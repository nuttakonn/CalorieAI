# Build MVP: Personal AI Calorie Tracker for iPhone

You are an expert iOS engineer and AI application architect.

Build a production-quality MVP of a **personal calorie tracking iOS app** for a single user.

The goal is to create a simple iPhone app that can:

1. Take a photo of food.
2. Send the photo to Gemini API for AI food recognition and calorie estimation.
3. Let the user review/edit the AI result before saving.
4. Store food records locally.
5. Read health/activity data from Apple Health using HealthKit.
6. Show today's calorie intake, calorie target, steps, active energy, and weight.
7. Show a simple daily summary.
8. Work without any custom backend.

The app is for personal use initially. Do NOT build unnecessary enterprise features.

---

# 1. Product Name

Use the working name:

`CalorieAI`

The name can be changed later.

---

# 2. Platform

Target:

- iPhone
- iOS 18+
- Swift 6
- SwiftUI
- Xcode latest stable version
- SwiftData
- HealthKit
- PhotosUI / AVFoundation as appropriate

Do NOT build a watchOS app in this MVP.

Apple Watch data should be accessed indirectly through Apple Health / HealthKit.

Architecture:

```text
Apple Watch
     ↓
Apple Health
     ↓
HealthKit
     ↓
CalorieAI iPhone App
```

---

# 3. Important Architecture Constraints

This MVP must be:

- Local-first
- No custom backend
- No Firebase
- No Supabase
- No CloudKit
- No user authentication
- No account system
- No server database
- No unnecessary networking except Gemini API

Local persistence:

`SwiftData`

Health data:

`HealthKit`

AI:

`Gemini API`

UI:

`SwiftUI`

---

# 4. Core User Flow

The main user flow should be:

```text
Open App
    ↓
Today Dashboard
    ↓
Tap "Add Food"
    ↓
Take/select food photo
    ↓
Compress image if necessary
    ↓
Send image to Gemini API
    ↓
Gemini analyzes food
    ↓
Return structured JSON
    ↓
Show AI result
    ↓
User reviews/edits
    ↓
Save Food
    ↓
Update today's calorie total
```

---

# 5. Dashboard

Create a clean, simple dashboard.

Example:

```text
--------------------------------
          Today
--------------------------------

Calories

      1,320 / 1,500 kcal

      ███████████████░░░

      180 kcal remaining

--------------------------------

Activity

Steps
8,240

Active Energy
430 kcal

Weight
67.0 kg

--------------------------------

Today's Food

🍚 Chicken Rice
620 kcal

☕ Iced Coffee
140 kcal

🍗 Grilled Chicken
320 kcal

🥗 Salad
240 kcal

--------------------------------

          + Add Food
--------------------------------
```

Do not make the UI overly complicated.

The primary action must be obvious:

`+ Add Food`

---

# 6. User Profile / Settings

Create a simple Settings screen.

Allow the user to configure:

- Weight
- Height
- Age
- Sex
- Daily calorie target

Default values should be easy to change.

Do NOT hardcode personal values into business logic.

The user should be able to change them from Settings.

Calculate BMR using the Mifflin-St Jeor equation.

Calculate an initial estimated daily calorie target using a configurable activity factor.

However, the MVP must allow the user to manually override the calorie target.

Example:

```text
Daily calorie target

[ 1500 ] kcal

Use calculated target
[ ON/OFF ]
```

---

# 7. Food Photo Input

Support:

- Camera
- Photo Library

Use native iOS APIs.

When the user selects/takes a photo:

1. Resize/compress the image before API upload.
2. Preserve enough quality for food recognition.
3. Avoid sending unnecessarily huge images.
4. Show loading state.
5. Handle network failure gracefully.

Example:

```text
Analyzing food...

Identifying ingredients
Estimating portion
Estimating calories
```

---

# 8. Gemini API Integration

Create a dedicated service:

```text
GeminiService
```

Do NOT put Gemini API code inside SwiftUI Views.

Use a protocol:

```swift
protocol FoodAnalysisService {
    func analyzeFood(image: Data) async throws -> FoodAnalysisResult
}
```

Then:

```text
GeminiService
    implements FoodAnalysisService
```

This makes it possible to replace Gemini later.

---

# 9. Gemini Model

Use a current Gemini model that supports:

- Image input
- Structured JSON output

Prefer a cost-efficient Flash/Lite model suitable for frequent image analysis.

Do not hardcode assumptions about a specific model version throughout the application.

Make the model configurable in one place.

Example:

```swift
struct GeminiConfiguration {
    let modelName: String
    let apiKey: String
}
```

Do not scatter the model name throughout the codebase.

---

# 10. API Key Security

For MVP personal development, allow the API key to be configured locally.

DO NOT commit the API key to Git.

Support configuration through:

```text
xcconfig
```

or an ignored local configuration file.

Example:

```text
Secrets.xcconfig
```

Add it to `.gitignore`.

Never put:

```swift
let apiKey = "AIza..."
```

directly into source code.

Create a clear README explaining how to configure the key.

Important:

This MVP is intended for personal use.

Do NOT pretend that embedding an API key in a client application is secure for public distribution.

---

# 11. Gemini Prompt

Use a carefully designed prompt.

Gemini should analyze the image and return:

- Food name
- Portion description
- Estimated grams
- Calories
- Protein
- Carbohydrates
- Fat
- Confidence
- Calorie range

Important instructions:

- Identify all visible food items.
- Do not assume restaurant-standard portions.
- Estimate realistic portion sizes.
- If portion size is uncertain, provide a range.
- Do not invent invisible ingredients.
- Clearly represent uncertainty.
- Thai food should be recognized correctly where possible.
- Use common Thai food names when appropriate.

Expected JSON:

```json
{
  "foods": [
    {
      "name": "Chicken rice",
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
```

The Gemini response must be parsed into strongly typed Swift models.

Do NOT parse arbitrary natural-language responses if structured JSON can be used.

---

# 12. Food Models

Create appropriate SwiftData models.

Suggested model:

```text
FoodEntry

id
createdAt
mealType
foodName
portionDescription
estimatedGrams
calories
calorieMin
calorieMax
proteinGrams
carbsGrams
fatGrams
confidence
imageData (optional)
```

Meal types:

```text
Breakfast
Lunch
Dinner
Snack
Other
```

Do not over-engineer the database.

---

# 13. Daily Nutrition Calculation

For each day:

```text
totalCalories
totalProtein
totalCarbs
totalFat
```

Calculate:

```text
remainingCalories =
dailyTarget - totalCalories
```

If calories exceed target:

```text
remainingCalories = 0
```

but separately show:

```text
overTargetCalories
```

Example:

```text
Target       1,500
Consumed     1,620
Remaining        0
Over target    120
```

Do not automatically add Apple Watch active calories to the food allowance.

The app should show activity separately.

---

# 14. HealthKit Integration

Create:

```text
HealthKitManager
```

Responsibilities:

- Request permissions
- Read today's steps
- Read today's active energy burned
- Read latest body weight
- Read heart rate if useful
- Read workouts if useful

For MVP, prioritize:

```text
Steps
Active Energy
Body Weight
```

Use HealthKit APIs correctly.

Do not attempt to access Apple Watch directly.

The source of truth should be HealthKit.

Architecture:

```text
Apple Watch
    ↓
Apple Health
    ↓
HealthKit
    ↓
HealthKitManager
    ↓
Dashboard
```

---

# 15. HealthKit Permissions

Request only the permissions actually needed.

Read:

```text
Step Count
Active Energy Burned
Body Mass
```

Optional:

```text
Heart Rate
Workouts
```

Do not request unnecessary health permissions.

Provide a user-friendly explanation before requesting HealthKit permission.

If permission is denied:

- App must continue working.
- Show a helpful message.
- Do not crash.
- Allow the user to continue tracking food manually.

---

# 16. HealthKit Data Refresh

Dashboard should refresh health data when the app becomes active.

Use appropriate HealthKit query mechanisms.

Do not constantly poll HealthKit.

For MVP:

```text
App launch
App becomes active
Manual refresh
```

are sufficient.

If practical, support HealthKit observer/background updates, but this is secondary to the core MVP.

Do not allow background complexity to delay the MVP.

---

# 17. Food Confirmation Screen

After Gemini analysis, show:

```text
AI Analysis

🍚 Chicken Rice

Portion
1 plate

Estimated calories

620 kcal

Estimated range

550 - 700 kcal

Protein
28 g

Carbs
75 g

Fat
22 g

Confidence
78%

[ Edit ]

[ Save Food ]
```

The user must be able to edit:

- Food name
- Portion
- Calories
- Protein
- Carbs
- Fat

AI suggestions are estimates, not absolute truth.

---

# 18. Manual Food Entry

The user should also be able to manually add food.

Example:

```text
Food name
[________________]

Calories
[________] kcal

Protein
[________] g

Carbs
[________] g

Fat
[________] g

[Save]
```

This is important because AI recognition will not always be correct.

---

# 19. Daily Summary

Create a Daily Summary screen.

Example:

```text
Today's Summary

Calories
1,420 / 1,500 kcal

Remaining
80 kcal

Protein
82 g

Carbs
165 g

Fat
48 g

Activity

Steps
8,240

Active Energy
430 kcal

Weight
67.0 kg
```

Keep the summary descriptive.

Do NOT present medical advice.

Do NOT claim that calorie estimates are medically accurate.

---

# 20. 7-Day Weight Trend

Add a very simple 7-day weight chart.

Use Swift Charts if available.

Example:

```text
Weight

67.5 ┤ ●
67.0 ┤   ●
66.8 ┤      ●
66.6 ┤         ●
66.5 ┤            ●
     └──────────────
       Mon Tue Wed Thu Fri
```

If there is not enough data, show:

```text
Not enough data yet.
Keep recording your weight.
```

---

# 21. Daily Notification

Add a local notification feature.

Default reminder:

```text
20:00
```

Example notification:

```text
Daily calorie summary

You've eaten 1,420 / 1,500 kcal today.
Tap to view your summary.
```

Allow the user to enable/disable the reminder.

Do NOT create a backend or push notification service.

Use local notifications.

Important:

A notification should use locally stored food data and the latest locally available HealthKit data.

Do not require Gemini API just to generate the daily notification.

---

# 22. Privacy

The app should be local-first.

Food records:

Local only.

Health data:

Read from HealthKit.

Do not upload HealthKit data to a server.

Food images:

Do not permanently upload/store them remotely.

If an image is sent to Gemini:

- Explain in the app that the selected food photo is sent to Gemini for analysis.
- Allow the user to delete stored food images.
- Prefer not storing the original image unless necessary.

---

# 23. Error Handling

Handle:

- No internet
- Gemini API failure
- Invalid Gemini JSON
- Rate limit
- Timeout
- HealthKit permission denied
- Camera permission denied
- Photo library permission denied
- Empty response
- Image too large
- Invalid API key

Never crash because of an external API failure.

Example:

```text
Unable to analyze this image.

Please check your internet connection
or enter the food manually.

[Try Again]
[Enter Manually]
```

---

# 24. Loading / UX

Use simple loading states.

Do not block the entire UI unnecessarily.

Example:

```text
Analyzing food...
```

with a progress indicator.

Avoid fake progress percentages.

---

# 25. App Structure

Use a clean feature-oriented architecture.

Suggested:

```text
CalorieAI/
│
├── App/
│   ├── CalorieAIApp.swift
│   └── AppState.swift
│
├── Features/
│   ├── Dashboard/
│   │   ├── DashboardView.swift
│   │   └── DashboardViewModel.swift
│   │
│   ├── Food/
│   │   ├── AddFoodView.swift
│   │   ├── FoodAnalysisView.swift
│   │   ├── ManualFoodView.swift
│   │   ├── FoodListView.swift
│   │   └── FoodViewModel.swift
│   │
│   ├── Summary/
│   │   └── DailySummaryView.swift
│   │
│   └── Settings/
│       ├── SettingsView.swift
│       └── SettingsViewModel.swift
│
├── Services/
│   ├── HealthKit/
│   │   └── HealthKitManager.swift
│   │
│   ├── Gemini/
│   │   ├── GeminiService.swift
│   │   ├── GeminiConfiguration.swift
│   │   └── GeminiPrompt.swift
│   │
│   └── Notifications/
│       └── NotificationManager.swift
│
├── Models/
│   ├── FoodEntry.swift
│   ├── UserProfile.swift
│   ├── FoodAnalysisResult.swift
│   └── MealType.swift
│
├── Utilities/
│   ├── ImageCompressor.swift
│   ├── CalorieCalculator.swift
│   └── DateExtensions.swift
│
└── Resources/
```

You may adjust the structure if there is a better Swift-native architecture.

Do not create unnecessary layers just for the sake of architecture.

---

# 26. SwiftData

Use SwiftData for local persistence.

Persist:

```text
UserProfile
FoodEntry
```

Do not create a complicated repository abstraction unless it provides real value.

SwiftUI should observe SwiftData correctly.

---

# 27. Testing

Write unit tests for:

### Calorie calculation

Test:

- Under target
- Exactly target
- Over target

### BMR

Test:

- Male
- Female
- Different weights/heights/ages

### Food total

Test multiple food entries.

### Gemini JSON decoding

Test valid response.

Test malformed response.

### HealthKit

Do not attempt to fully unit-test Apple's HealthKit framework.

Instead isolate the HealthKit manager behind a protocol where practical and test the app using mocked health data.

---

# 28. Mock Mode

Add a development-only mock mode.

This allows the developer to run the app without:

- Gemini API key
- HealthKit permissions

Example mock data:

```text
Steps: 8240
Active Energy: 430
Weight: 67.0 kg
```

Mock Gemini response:

```text
Chicken rice
620 kcal
```

Make mock mode easy to disable for production.

Do NOT let mock data silently appear in production builds.

---

# 29. Configuration

Create:

```text
AppConfiguration
```

with environment-aware configuration.

Example:

```text
Development
Production
```

Gemini:

```text
modelName
API key
```

must be configurable.

Never hardcode secrets.

---

# 30. Accessibility

Use:

- Dynamic Type
- VoiceOver-friendly labels
- Sufficient contrast
- Native SwiftUI controls

Do not use text-only icons as the only way to understand an action.

---

# 31. Thai Language Support

The initial UI should support Thai.

Use Thai as the primary display language.

Examples:

```text
วันนี้
เพิ่มอาหาร
แคลอรี่
กิจกรรม
ก้าว
พลังงานที่ใช้
น้ำหนัก
สรุปวันนี้
ตั้งค่า
```

However, keep all user-facing strings centralized/localizable.

Prepare the architecture for English localization later.

---

# 32. Important Product Rule

AI calorie estimation is inherently uncertain.

The app must never communicate:

```text
This food contains exactly 620 calories.
```

Instead use:

```text
Estimated: 620 kcal
Likely range: 550–700 kcal
```

where appropriate.

The user must always be able to edit the AI result.

---

# 33. MVP Scope

MUST HAVE:

- SwiftUI iPhone app
- Dashboard
- Food photo
- Camera
- Photo library
- Gemini image analysis
- Structured JSON
- Food confirmation/edit
- Manual food entry
- SwiftData
- Daily calorie total
- Calorie target
- HealthKit
- Steps
- Active energy
- Weight
- Settings
- Daily summary
- 7-day weight trend
- Local 20:00 notification
- Error handling
- Mock mode
- README
- Unit tests

NOT REQUIRED FOR MVP:

- watchOS app
- Backend
- Login
- Cloud database
- Social features
- Food sharing
- Barcode scanning
- Restaurant database
- Subscription system
- AI chat
- Meal planning
- Advanced analytics
- Automatic diet recommendations
- Medical advice
- App Store distribution

Do not implement these unless required by the core MVP.

---

# 34. Development Rules

Follow these rules strictly:

1. Do not make unrelated changes.
2. Do not introduce unnecessary dependencies.
3. Prefer Apple's native frameworks.
4. Keep the implementation simple.
5. Do not hardcode secrets.
6. Do not hardcode personal user data.
7. Do not auto-push to Git.
8. Do not modify unrelated project files.
9. Add tests for business logic.
10. Handle errors explicitly.
11. Do not hide API failures.
12. Keep Gemini integration isolated.
13. Keep HealthKit integration isolated.
14. Use async/await.
15. Avoid force unwraps where practical.
16. Do not use deprecated APIs when a modern alternative exists.
17. Keep UI and business logic separated.
18. Do not over-engineer the MVP.

---

# 35. Implementation Process

Before writing code:

1. Inspect the existing repository.
2. Determine whether an Xcode project already exists.
3. Identify the current Swift/Xcode configuration.
4. Do not delete existing work without justification.
5. Create a short implementation plan.
6. Then implement the MVP incrementally.

Implementation order:

### Phase 1
Project foundation

### Phase 2
SwiftData models

### Phase 3
Dashboard

### Phase 4
Manual food entry

### Phase 5
Camera/photo picker

### Phase 6
Gemini API integration

### Phase 7
AI confirmation/edit screen

### Phase 8
HealthKit integration

### Phase 9
Daily summary

### Phase 10
7-day weight chart

### Phase 11
20:00 local notification

### Phase 12
Testing and polish

---

# 36. Definition of Done

The MVP is complete when:

1. App launches successfully on an iPhone simulator.
2. App launches successfully on a physical iPhone if configured.
3. User can enter their profile.
4. User can configure calorie target.
5. User can take a food photo.
6. User can select a food photo.
7. Gemini analyzes the photo.
8. JSON is parsed correctly.
9. User can edit the AI result.
10. User can save the food.
11. Dashboard updates immediately.
12. Daily calorie totals are correct.
13. HealthKit can return today's steps.
14. HealthKit can return active energy.
15. HealthKit can return body weight.
16. App works if HealthKit permission is denied.
17. App works if Gemini is unavailable.
18. User can manually enter food.
19. 7-day weight history can be displayed.
20. Local 20:00 notification can be configured.
21. No secrets are committed to Git.
22. Unit tests pass.
23. README explains setup and configuration.
24. No backend is required.

---

# 37. Final Deliverables

At the end of implementation provide:

1. Working Xcode project.
2. README.md.
3. Setup instructions.
4. Gemini API configuration instructions.
5. HealthKit capability configuration instructions.
6. Required Info.plist privacy descriptions.
7. Unit tests.
8. Mock mode instructions.
9. Known limitations.
10. List of files created/modified.
11. Commands/build steps used to verify the project.

Before declaring completion, build the project and fix compilation errors.

Do not simply generate code without verifying that it builds.

Start by inspecting the repository and then implement the MVP according to the requirements above.