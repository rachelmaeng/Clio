# Clio v1 - SwiftUI iOS App

Build a mindful nutrition tracking app with Pilates-forward wellness features, dual visual modes, daily body check-ins, and pattern reflections.

## Core Product Value
**Clio is fundamentally a nutrition tracking app** - but one that prioritizes awareness over restriction. The nourishment log is the central feature. Movement and check-ins support the nutrition journey, not the other way around.

## Tech Stack
- SwiftUI (iOS 17+)
- SwiftData for persistence
- Swift 6
- No external dependencies

## Non-Negotiables
- No shame language
- No red "over" indicators
- No streaks or leaderboards
- No default calorie goals
- Calories hidden by default (behind "Details" tap)
- Calm, reflective tone

## 5 Screens to Build

### 1. Daily Check-in
- Prompt: "How does your body feel today?"
- 6 tappable states with icons: Energized, Calm, Foggy, Rested, Heavy, Open
- Single "Continue" CTA
- Save as today's check-in

### 2. Movement Log
- Movement types: Pilates, Walk, Strength, Stretch, Rest Day (grid layout)
- Energy level slider (0-100)
- Duration minutes (optional stepper)
- Notes textarea (optional)
- "Save Movement" CTA
- No calories burned, no intensity scoring

### 3. Nourishment Log
- Meal type tabs: Breakfast, Lunch, Dinner, Snack
- "What nourished you?" textarea
- Sensation chips (multi-select): Grounded, Bloated, Comforted, Mindful, Craving
- Optional photo
- Hidden "Details" section with: Calories, Protein, Carbs, Fat
- Details hidden by default, revealed on tap

### 4. Reflections
- 3-6 pattern cards based on recent entries
- Neutral language only - no advice, no "should", no "try"
- Example: "Energy felt steadier on mornings you logged movement."
- If no data: "Noticing is enough. Log anything you want today."

### 5. Home
- Greeting with user name
- Contextual primary CTA:
  - If no check-in today: "Daily Check-in"
  - Else if no movement: "Log Movement"
  - Else if no nourishment: "Log Nourishment"
  - Else: "Add Reflection"
- "Recent Care" list (max 2 items)
- No analytics charts

## Visual Theme (Evening Mode Only for v1)

### Colors
```
- background: #121022
- surface: #1c1a2e
- surfaceHighlight: #252540
- text: white
- textMuted: #9f9db9
- primary: #2111d4 (purple accent)
- primaryGlow: rgba(33, 17, 212, 0.3)
```

### Ambient Effects
- Subtle gradient backgrounds with purple/indigo glows
- Cards with soft borders (white/5% opacity)
- Shadows with primary color tint

## Data Model (SwiftData)

```swift
@Model class UserSettings {
    var modePreference: String = "adaptive" // adaptive | light | evening
    var showDailyNutritionContext: Bool = false
}

@Model class DailyCheckIn {
    var date: Date
    var state: String // energized, calm, foggy, rested, heavy, open
    var createdAt: Date
}

@Model class MovementEntry {
    var dateTime: Date
    var type: String // pilates, walk, strength, stretch, rest
    var energyLevel: Int // 0-100
    var durationMinutes: Int?
    var notes: String?
}

@Model class MealEntry {
    var dateTime: Date
    var mealType: String // breakfast, lunch, dinner, snack
    var descriptionText: String
    var sensationTags: [String]
    var photoData: Data?
    var calories: Int?
    var protein: Int?
    var carbs: Int?
    var fat: Int?
}
```

## Navigation
- TabView with: Home, Check-in, Log, Reflections, Settings
- Or 4 tabs if merging Check-in into Home CTA

## File Structure
```
Clio/
├── ClioApp.swift
├── Models/
│   ├── UserSettings.swift
│   ├── DailyCheckIn.swift
│   ├── MovementEntry.swift
│   └── MealEntry.swift
├── Views/
│   ├── HomeView.swift
│   ├── DailyCheckInView.swift
│   ├── MovementLogView.swift
│   ├── NourishmentLogView.swift
│   ├── ReflectionsView.swift
│   └── SettingsView.swift
├── Components/
│   ├── BodyStateCard.swift
│   ├── MovementTypeCard.swift
│   ├── SensationChip.swift
│   ├── ReflectionCard.swift
│   └── EnergySlider.swift
├── Theme/
│   └── ClioTheme.swift
└── Utilities/
    └── ReflectionGenerator.swift
```

## Design Details (from mockups)

### Typography
- Font: System (San Francisco) or Manrope-like weight variation
- Headings: Bold, tight tracking
- Body: Regular weight
- Muted text color: #9f9db9

### Components
- Cards: rounded-xl (12pt), surface-dark background, subtle border
- Buttons: rounded-lg or rounded-full, primary purple (#2111d4)
- Chips: rounded-full, toggle between surface-dark and primary
- Sliders: custom styled with white thumb, gradient track

### Icons
- SF Symbols throughout
- Check-in states: Use abstract gradients/colors (not literal icons)

## Build Order
1. Create Xcode project structure with proper folder organization
2. Implement ClioTheme with Evening mode colors
3. Build data models with SwiftData
4. Build DailyCheckInView (core interaction)
5. Build MovementLogView with CRUD
6. Build NourishmentLogView with hidden Details
7. Build HomeView with contextual CTA
8. Build ReflectionsView with pattern generation
9. Build SettingsView (basic preferences)
10. Wire up TabView navigation
11. Polish UI with ambient effects and animations
12. Verify calories never appear unless Details tapped

## Success Criteria
- App builds without errors via `xcodebuild`
- All 5 screens navigate correctly
- Check-in saves and shows on Home
- Movement entries persist
- Nourishment entries persist with hidden calories
- Evening mode theme applied consistently
- Reflections generate from stored data
- No shame language anywhere
- No red indicators anywhere
- UI matches the premium dark aesthetic from mockups

When complete, output:
<promise>CLIO BUILD COMPLETE</promise>
