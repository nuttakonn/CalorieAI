import Foundation

enum APIError: Error {
    case invalidURL
    case invalidResponse
    case apiError(String)
    case decodingError
}

protocol FoodAnalysisService {
    func analyzeFood(image: Data) async throws -> FoodAnalysisResult
}

class OpenRouterService: FoodAnalysisService {
    private let apiKey: String
    private let model = "google/gemini-2.5-flash-lite"
    private let endpoint = "https://openrouter.ai/api/v1/chat/completions"
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    static var `default`: OpenRouterService {
        let key = Bundle.main.infoDictionary?["OPENROUTER_API_KEY"] as? String ?? ""
        let cleanedKey = key.trimmingCharacters(in: .whitespacesAndNewlines)
        return OpenRouterService(apiKey: cleanedKey)
    }
    
    func analyzeFood(image: Data) async throws -> FoodAnalysisResult {
        guard let url = URL(string: endpoint) else {
            throw APIError.invalidURL
        }
        
        let base64Image = image.base64EncodedString()
        
        let prompt = """
        Analyze this food image and return ONLY a JSON object with this exact structure:
        {
          "foods": [
            {
              "name": "Food name",
              "portion": "1 plate",
              "estimatedGrams": 350,
              "calories": 620,
              "calorieMin": 550,
              "calorieMax": 700,
              "proteinGrams": 28,
              "carbsGrams": 75,
              "fatGrams": 22,
              "confidence": 0.78
            }
          ],
          "totalCalories": 620,
          "totalCalorieMin": 550,
          "totalCalorieMax": 700
        }
        Rules: Identify all food items, estimate realistic portions, recognize Thai food correctly. Return ONLY the JSON, no extra text.
        """
        
        let requestBody: [String: Any] = [
            "model": model,
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "image_url",
                            "image_url": ["url": "data:image/jpeg;base64,\(base64Image)"]
                        ],
                        [
                            "type": "text",
                            "text": prompt
                        ]
                    ]
                ]
            ],
            "response_format": ["type": "json_object"],
            "temperature": 0.1,
            "max_tokens": 1024
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("https://github.com/calorieai", forHTTPHeaderField: "HTTP-Referer")
        request.timeoutInterval = 30
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorJson["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw APIError.apiError(message)
            }
            throw APIError.apiError("HTTP \(httpResponse.statusCode)")
        }
        
        struct OpenRouterResponse: Decodable {
            struct Choice: Decodable {
                struct Message: Decodable {
                    let content: String
                }
                let message: Message
            }
            let choices: [Choice]
        }
        
        let openRouterResponse = try JSONDecoder().decode(OpenRouterResponse.self, from: data)
        
        guard let text = openRouterResponse.choices.first?.message.content,
              let textData = text.data(using: .utf8) else {
            throw APIError.decodingError
        }
        
        do {
            return try JSONDecoder().decode(FoodAnalysisResult.self, from: textData)
        } catch {
            print("OpenRouter decode error: \(text)")
            throw APIError.decodingError
        }
    }
}
