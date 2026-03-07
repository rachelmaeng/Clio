# Clio Project Context

## Overview
Clio is an iOS health & wellness app that helps users track their lifestyle in sync with their menstrual cycle phases. The app provides personalized recommendations for eating, movement, and self-care based on the user's current cycle phase.

## Tech Stack
- **Platform**: iOS 18+
- **UI Framework**: SwiftUI
- **Data Persistence**: SwiftData
- **Health Integration**: HealthKit
- **Architecture**: MVVM-ish with SwiftUI's native patterns

## Project Structure
```
Clio/
├── App/
│   └── ClioApp.swift          # Main app entry point
├── Models/
│   ├── MealEntry.swift        # Meal tracking data model
│   ├── WorkoutEntry.swift     # Workout tracking data model
│   ├── UserSettings.swift     # User preferences/settings
│   └── CyclePhase.swift       # Menstrual cycle phases enum
├── Views/
│   ├── HomeView.swift         # Main home/dashboard
│   ├── EatView.swift          # Meal tracking tab
│   ├── MoveView.swift         # Workout tracking tab
│   ├── AddMealView.swift      # Add new meal sheet
│   ├── EditMealView.swift     # Edit existing meal sheet
│   ├── AddWorkoutView.swift   # Add new workout sheet
│   └── SettingsView.swift     # App settings
├── Components/
│   ├── ClioTheme.swift        # Design system (colors, fonts, spacing)
│   ├── PhaseHeroView.swift    # Phase-based hero illustrations
│   └── Various UI components
├── Services/
│   ├── HealthKitManager.swift # HealthKit integration
│   └── NotificationManager.swift
└── Resources/
    └── Assets.xcassets        # App icons, images
```

## Design System (ClioTheme)
- **Background**: Dark theme base
- **Colors**:
  - `eatColor` - For food/nutrition features
  - `moveColor` - For exercise features
  - `terracotta` - Accent/warning color
  - Phase-specific colors for cycle phases
- **Typography**: Custom heading and body fonts
- **Animations**: `.clioQuick`, `.clioStandard` animation curves

## Key Features
1. **Cycle Phase Tracking**: Menstrual, Follicular, Ovulation, Luteal phases
2. **Meal Logging**: Track food items, macros, body responses
3. **Workout Logging**: Track exercises with HealthKit sync
4. **Phase-Based Recommendations**: Tips tailored to current cycle phase

## Bundle ID
`com.clio.app`

## Current State
- Core functionality complete
- HealthKit integration working
- Push notifications configured
- Unit tests for models/services added
- Privacy policy template created

## Pending Work
- Add accessibility labels throughout app

## Important Conventions
- Use `ClioTheme` for all styling (colors, fonts, spacing)
- Navigation uses `.toolbarBackground(.hidden, for: .navigationBar)` to prevent white flash
- Meals and workouts are tappable to edit
- All views use `.fadeInFromBottom()` animation modifier for entrance animations

## Simulator
- Primary testing on iPhone 17 Pro simulator
- Simulator ID: 94EBEE91-7D52-49B5-ABA0-711C958FF73C
