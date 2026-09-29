import SwiftUI
import PhotosUI

struct AddFoodView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showingManualEntry = false
    @State private var showingCamera = false
    @State private var selectedImage: UIImage?
    @State private var selectedImageWrapper: ImageWrapper?
    @State private var photosPickerItem: PhotosPickerItem?
    
    struct ImageWrapper: Identifiable, Hashable {
        let id = UUID()
        let image: UIImage
        
        static func == (lhs: ImageWrapper, rhs: ImageWrapper) -> Bool {
            lhs.id == rhs.id
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background Gradient
                LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.05)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Text("Track Your Meal")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .padding(.top, 20)
                    
                    Text("Choose how you want to add your food to CalorieAI.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    VStack(spacing: 16) {
                        Button(action: { showingCamera = true }) {
                            PremiumButtonContent(icon: "camera.viewfinder", title: "Take a Photo", subtitle: "Use your camera", colors: [Color.blue, Color.cyan])
                        }
                        
                        PhotosPicker(selection: $photosPickerItem, matching: .images) {
                            PremiumButtonContent(icon: "photo.stack.fill", title: "Choose from Library", subtitle: "Pick an existing photo", colors: [Color.purple, Color.indigo])
                        }
                        .onChange(of: photosPickerItem) {
                            Task {
                                if let data = try? await photosPickerItem?.loadTransferable(type: Data.self),
                                   let image = UIImage(data: data) {
                                    await MainActor.run { selectedImage = image }
                                }
                            }
                        }
                        
                        Button(action: { showingManualEntry = true }) {
                            PremiumButtonContent(icon: "text.alignleft", title: "Enter Manually", subtitle: "Type in macros yourself", colors: [Color.gray.opacity(0.8), Color.gray])
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .navigationDestination(isPresented: $showingManualEntry) {
                ManualFoodView(onSaved: { dismiss() })
            }
            .fullScreenCover(isPresented: $showingCamera) {
                CameraView(selectedImage: $selectedImage)
            }
            .navigationDestination(item: $selectedImageWrapper) { wrapper in
                FoodAnalysisView(image: wrapper.image, onSaved: { dismiss() })
            }
            .onChange(of: selectedImage) {
                if let image = selectedImage {
                    selectedImageWrapper = ImageWrapper(image: image)
                    selectedImage = nil // Reset so it can trigger again if needed
                }
            }
        }
    }
    
}

struct PremiumButtonContent: View {
    let icon: String
    let title: String
    let subtitle: String
    let colors: [Color]
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 50, height: 50)
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.white.opacity(0.5))
        }
        .padding()
        .background(
            LinearGradient(gradient: Gradient(colors: colors), startPoint: .leading, endPoint: .trailing)
        )
        .cornerRadius(16)
        .shadow(color: colors.last!.opacity(0.3), radius: 10, x: 0, y: 5)
    }
}
