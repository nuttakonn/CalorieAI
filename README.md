# CalorieAI

CalorieAI is a local-first, personal calorie tracking iOS app that uses the Gemini API for AI food recognition and calorie estimation, and HealthKit for activity tracking.

## Features
- **Local-First Architecture:** No backend required. Uses SwiftData for local persistence.
- **AI Food Recognition:** Snap a photo of your food, and Gemini AI will estimate the portion size, calories, and macros.
- **HealthKit Integration:** Automatically syncs your steps, active energy burned, and weight from Apple Health.
- **Daily Dashboard:** Tracks your daily consumed calories against a calculated BMR target.
- **Local Reminders:** Sends a 20:00 local notification reminder to check your summary.

## Setup Instructions

### 1. Requirements
- iOS 18.0+
- Xcode 16+
- An active Google Gemini API Key

### 2. Configure API Key
The app uses an xcconfig file to inject the API key to prevent committing secrets to git.

1. Open `Secrets.xcconfig` in the root folder (it's ignored by Git).
2. Add your Gemini API key like this:
```text
GEMINI_API_KEY = "AIzaSy..."
```

### 3. Generate Xcode Project (if needed)
If the `.xcodeproj` is missing or you need to regenerate it, this project uses [XcodeGen](https://github.com/yonaskolb/XcodeGen):
```bash
brew install xcodegen
xcodegen
```

### 4. HealthKit Capabilities
- When running on a physical device, ensure you add the HealthKit capability in Xcode under "Signing & Capabilities".
- The app requests reading `Step Count`, `Active Energy Burned`, and `Body Mass`.

## Mock Mode (Development)
To run the app without real HealthKit data or API calls, you can toggle `isMockMode = true` in `DashboardViewModel`. It provides a static set of health metrics and randomly generated history for UI testing.

## Known Limitations
- The accuracy of calorie estimations highly depends on the provided image and Gemini's current reasoning capabilities. All estimates should be reviewed and can be manually edited before saving.
- This app is meant for personal tracking and does not provide medical advice.
