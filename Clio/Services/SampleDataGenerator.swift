import Foundation
import SwiftData

/// Developer utility to populate the app with realistic fake data spanning ~2 weeks.
/// Accessible via Settings > Developer section.
struct SampleDataGenerator {

    static func loadSampleData(modelContext: ModelContext) {
        let calendar = Calendar.current

        // Current day is ~day 6 (follicular). So last period started 6 days ago.
        // We'll generate 14 days of history: days -13 through 0 (today).
        // Cycle mapping (28-day cycle, period started 6 days ago means we count backwards):
        //   Day 1 of cycle = 6 days ago
        //   So 14 days ago = day 23 of PREVIOUS cycle (luteal)
        //   Going back: day -13..-8 => previous cycle days 22-27 (luteal)
        //               day -7..-6  => previous cycle day 28 + current day 1-2 (menstrual)
        //               day -5..-2  => current cycle days 1-4 (menstrual)
        //               day -1..0   => current cycle days 5-6 (follicular)
        // Let's simplify: set lastPeriodStart to 5 days ago so today = day 6.
        // Then generate data going back 14 days from today.

        let today = calendar.startOfDay(for: Date())
        let lastPeriodStart = calendar.date(byAdding: .day, value: -5, to: today)!

        // Update UserSettings with the cycle start
        let settingsDescriptor = FetchDescriptor<UserSettings>()
        if let settings = try? modelContext.fetch(settingsDescriptor).first {
            settings.lastPeriodStart = lastPeriodStart
            settings.cycleLength = 28
            settings.periodLength = 5
            settings.updatedAt = Date()
        }

        // Phase for a given day offset from today (negative = past)
        func phaseForDayOffset(_ offset: Int) -> (phase: CyclePhase, cycleDay: Int) {
            // Day of current cycle: today is day 6, so offset 0 = day 6
            let cycleDay = 6 + offset // offset is negative for past days
            if cycleDay < 1 {
                // Previous cycle: map to 28-day cycle
                let prevDay = 28 + cycleDay // e.g. cycleDay=-2 => prevDay=26
                if prevDay <= 5 { return (.menstrual, prevDay) }
                if prevDay <= 13 { return (.follicular, prevDay) }
                if prevDay <= 16 { return (.ovulation, prevDay) }
                return (.luteal, prevDay)
            }
            if cycleDay <= 5 { return (.menstrual, cycleDay) }
            if cycleDay <= 13 { return (.follicular, cycleDay) }
            if cycleDay <= 16 { return (.ovulation, cycleDay) }
            return (.luteal, cycleDay)
        }

        // Days to skip check-ins (realistic gaps)
        let skipCheckInDays: Set<Int> = [-11, -7, -3]

        // Days to skip meals entirely
        let lightMealDays: Set<Int> = [-9, -4] // only 1 meal these days

        // Days with no movement
        let restDays: Set<Int> = [-13, -10, -6, -3, -1]

        // MARK: - Generate Feel Check-ins
        for offset in -13...0 {
            if skipCheckInDays.contains(offset) { continue }

            let date = calendar.date(byAdding: .day, value: offset, to: today)!
            let checkInTime = calendar.date(bySettingHour: Int.random(in: 7...10),
                                            minute: Int.random(in: 0...59),
                                            second: 0, of: date)!

            let (phase, cycleDay) = phaseForDayOffset(offset)
            let (primaryState, energy, moods, sensations) = feelDataForPhase(phase)

            let check = FeelCheck(
                dateTime: checkInTime,
                energyLevel: energy,
                moods: moods,
                bodySensations: sensations,
                primaryState: primaryState,
                cyclePhase: phase.rawValue,
                cycleDay: cycleDay,
                createdAt: checkInTime
            )
            modelContext.insert(check)
        }

        // MARK: - Generate Meals
        for offset in -13...0 {
            let date = calendar.date(byAdding: .day, value: offset, to: today)!
            let (phase, cycleDay) = phaseForDayOffset(offset)

            if lightMealDays.contains(offset) {
                // Just one meal
                let meal = randomMeal(type: .lunch, date: date, phase: phase, cycleDay: cycleDay)
                modelContext.insert(meal)
                continue
            }

            // 2-3 meals per day
            let mealCount = Int.random(in: 2...3)
            var types: [MealEntry.MealType] = [.breakfast, .lunch, .dinner]
            types.shuffle()
            let selectedTypes = Array(types.prefix(mealCount))

            for mealType in selectedTypes.sorted(by: { mealOrder($0) < mealOrder($1) }) {
                let meal = randomMeal(type: mealType, date: date, phase: phase, cycleDay: cycleDay)
                modelContext.insert(meal)
            }

            // Sometimes add a snack
            if Bool.random() && mealCount < 3 {
                let snack = randomMeal(type: .snack, date: date, phase: phase, cycleDay: cycleDay)
                modelContext.insert(snack)
            }
        }

        // MARK: - Generate Movement
        for offset in -13...0 {
            if restDays.contains(offset) { continue }

            let date = calendar.date(byAdding: .day, value: offset, to: today)!
            let workoutTime = calendar.date(bySettingHour: Int.random(in: 6...18),
                                            minute: Int.random(in: 0...59),
                                            second: 0, of: date)!
            let (phase, cycleDay) = phaseForDayOffset(offset)
            let movement = randomMovement(date: workoutTime, phase: phase, cycleDay: cycleDay)
            modelContext.insert(movement)
        }

        try? modelContext.save()
    }

    // MARK: - Feel Check Data by Phase

    private static func feelDataForPhase(_ phase: CyclePhase) -> (primaryState: String, energy: Int, moods: [String], sensations: [String]) {
        switch phase {
        case .menstrual:
            let states = ["Heavy", "Low", "Calm", "Sore", "Foggy"]
            let moods = [["Tired", "Calm"], ["Sad", "Tired"], ["Content", "Tired"], ["Calm"]]
            let sensations = [["Crampy", "Heavy"], ["Bloated", "Tired"], ["Heavy", "Achy"], ["Tired"]]
            return (
                states.randomElement()!,
                Int.random(in: 3...5),
                moods.randomElement()!,
                sensations.randomElement()!
            )

        case .follicular:
            let states = ["Energized", "Calm", "Balanced", "Rested"]
            let moods = [["Happy", "Motivated"], ["Focused", "Content"], ["Calm", "Happy"], ["Motivated"]]
            let sensations = [["Energized", "Light"], ["Rested", "Strong"], ["Energized"], ["Light"]]
            return (
                states.randomElement()!,
                Int.random(in: 6...9),
                moods.randomElement()!,
                sensations.randomElement()!
            )

        case .ovulation:
            let states = ["Energized", "Balanced", "Calm"]
            let moods = [["Happy", "Motivated", "Focused"], ["Content", "Happy"], ["Motivated", "Focused"]]
            let sensations = [["Energized", "Strong"], ["Light", "Energized"], ["Strong"]]
            return (
                states.randomElement()!,
                Int.random(in: 7...10),
                moods.randomElement()!,
                sensations.randomElement()!
            )

        case .luteal:
            let states = ["Foggy", "Heavy", "Anxious", "Low", "Neutral", "Calm"]
            let moods = [["Irritable", "Stressed"], ["Anxious", "Tired"], ["Content"], ["Tired", "Neutral"], ["Stressed"]]
            let sensations = [["Bloated", "Heavy"], ["Tense", "Tired"], ["Bloated"], ["Heavy", "Headachy"], ["Achy"]]
            return (
                states.randomElement()!,
                Int.random(in: 3...6),
                moods.randomElement()!,
                sensations.randomElement()!
            )
        }
    }

    // MARK: - Meal Generation

    private static func mealOrder(_ type: MealEntry.MealType) -> Int {
        switch type {
        case .breakfast: return 0
        case .lunch: return 1
        case .dinner: return 2
        case .snack: return 3
        }
    }

    private static func randomMeal(type: MealEntry.MealType, date: Date, phase: CyclePhase, cycleDay: Int) -> MealEntry {
        let calendar = Calendar.current
        let hour: Int
        switch type {
        case .breakfast: hour = Int.random(in: 7...9)
        case .lunch: hour = Int.random(in: 11...13)
        case .dinner: hour = Int.random(in: 18...20)
        case .snack: hour = Int.random(in: 14...16)
        }
        let mealTime = calendar.date(bySettingHour: hour, minute: Int.random(in: 0...59), second: 0, of: date)!

        let (description, items, calories) = mealContent(for: type, phase: phase)
        let feelAfter = mealFeelAfter(for: phase)
        let bodyResponses = mealBodyResponses(for: phase)

        return MealEntry(
            dateTime: mealTime,
            mealType: type.rawValue,
            foodItems: items,
            descriptionText: description,
            calories: calories,
            bodyResponses: bodyResponses,
            feelAfter: feelAfter,
            cyclePhase: phase.rawValue,
            cycleDay: cycleDay,
            createdAt: mealTime,
            updatedAt: mealTime
        )
    }

    private static func mealContent(for type: MealEntry.MealType, phase: CyclePhase) -> (description: String, items: [String], calories: Int?) {
        let breakfasts: [(String, [String], Int?)] = [
            ("Oatmeal with berries and honey", ["Oats", "Blueberries", "Honey"], 350),
            ("Greek yogurt with granola", ["Greek yogurt", "Granola", "Strawberries"], 320),
            ("Avocado toast with eggs", ["Sourdough", "Avocado", "Eggs"], 450),
            ("Smoothie bowl", ["Banana", "Spinach", "Protein powder", "Almond milk"], 380),
            ("Scrambled eggs with toast", ["Eggs", "Whole wheat toast", "Butter"], 400),
            ("Overnight oats", ["Oats", "Chia seeds", "Almond milk", "Maple syrup"], nil),
            ("Banana pancakes", ["Banana", "Eggs", "Oat flour"], 420),
        ]

        let lunches: [(String, [String], Int?)] = [
            ("Salad with grilled chicken", ["Mixed greens", "Grilled chicken", "Tomato", "Dressing"], 480),
            ("Turkey wrap", ["Turkey", "Lettuce", "Tomato", "Whole wheat wrap"], 420),
            ("Quinoa bowl with veggies", ["Quinoa", "Roasted vegetables", "Chickpeas"], 520),
            ("Chicken soup", ["Chicken", "Noodles", "Carrots", "Celery"], nil),
            ("Poke bowl", ["Rice", "Salmon", "Avocado", "Edamame"], 580),
            ("Lentil soup with bread", ["Lentils", "Vegetables", "Sourdough"], 450),
            ("Caesar salad", ["Romaine", "Parmesan", "Croutons", "Caesar dressing"], nil),
        ]

        let dinners: [(String, [String], Int?)] = [
            ("Pasta with marinara", ["Pasta", "Tomato sauce", "Parmesan"], 620),
            ("Grilled salmon with rice", ["Salmon", "Brown rice", "Broccoli"], 580),
            ("Stir fry with tofu", ["Tofu", "Mixed vegetables", "Soy sauce", "Rice"], nil),
            ("Chicken with sweet potato", ["Chicken breast", "Sweet potato", "Green beans"], 550),
            ("Tacos", ["Ground turkey", "Tortillas", "Salsa", "Cheese"], 650),
            ("Baked cod with vegetables", ["Cod", "Asparagus", "Lemon"], 420),
            ("Veggie curry with naan", ["Chickpeas", "Coconut milk", "Vegetables", "Naan"], nil),
        ]

        let snacks: [(String, [String], Int?)] = [
            ("Apple with almond butter", ["Apple", "Almond butter"], 220),
            ("Trail mix", ["Almonds", "Cashews", "Dried cranberries"], 280),
            ("Dark chocolate", ["Dark chocolate"], 200),
            ("Hummus with carrots", ["Hummus", "Carrots", "Celery"], nil),
            ("Protein bar", ["Protein bar"], 250),
            ("Banana", ["Banana"], nil),
        ]

        switch type {
        case .breakfast: return breakfasts.randomElement()!
        case .lunch: return lunches.randomElement()!
        case .dinner: return dinners.randomElement()!
        case .snack: return snacks.randomElement()!
        }
    }

    private static func mealFeelAfter(for phase: CyclePhase) -> String? {
        // Not every meal has a feel-after
        guard Bool.random() else { return nil }

        switch phase {
        case .menstrual:
            return ["Neutral", "Sluggish", "Bloated", "Satisfied"].randomElement()
        case .follicular:
            return ["Energized", "Satisfied", "Nourished"].randomElement()
        case .ovulation:
            return ["Energized", "Nourished", "Satisfied"].randomElement()
        case .luteal:
            return ["Bloated", "Sluggish", "Satisfied", "Neutral"].randomElement()
        }
    }

    private static func mealBodyResponses(for phase: CyclePhase) -> [String] {
        // Only some meals get body responses
        guard Int.random(in: 0...2) == 0 else { return [] }

        switch phase {
        case .menstrual:
            return [["Bloated"], ["Crampy"], ["Sluggish"], []].randomElement()!
        case .follicular:
            return [["Energized"], ["Satisfied", "Light"], []].randomElement()!
        case .ovulation:
            return [["Energized"], ["Light"], []].randomElement()!
        case .luteal:
            return [["Bloated"], ["Sluggish"], ["Bloated", "Gassy"], []].randomElement()!
        }
    }

    // MARK: - Movement Generation

    private static func randomMovement(date: Date, phase: CyclePhase, cycleDay: Int) -> MovementEntry {
        let (type, duration, intensity, feels) = movementForPhase(phase)
        let caloriesPerMin: Double
        switch intensity {
        case 1...3: caloriesPerMin = 3.0
        case 4...6: caloriesPerMin = 6.0
        default: caloriesPerMin = 10.0
        }
        let calories = Int(Double(duration) * caloriesPerMin)

        return MovementEntry(
            dateTime: date,
            type: type,
            durationMinutes: duration,
            estimatedCaloriesBurned: Bool.random() ? calories : nil,
            feelAfter: feels,
            intensityLevel: intensity,
            cyclePhase: phase.rawValue,
            cycleDay: cycleDay,
            createdAt: date,
            updatedAt: date
        )
    }

    private static func movementForPhase(_ phase: CyclePhase) -> (type: String, duration: Int, intensity: Int, feels: [String]) {
        switch phase {
        case .menstrual:
            let options: [(String, Int, Int, [String])] = [
                ("Walking", Int.random(in: 20...35), Int.random(in: 2...4), ["Calm", "Refreshed"]),
                ("Gentle Yoga", Int.random(in: 25...40), Int.random(in: 2...3), ["Calm", "Refreshed"]),
                ("Stretching", Int.random(in: 15...25), Int.random(in: 1...3), ["Calm"]),
                ("Pilates", Int.random(in: 30...40), Int.random(in: 3...5), ["Tired", "Calm"]),
            ]
            return options.randomElement()!

        case .follicular:
            let options: [(String, Int, Int, [String])] = [
                ("Running", Int.random(in: 25...45), Int.random(in: 6...8), ["Energized", "Accomplished"]),
                ("Upper Body", Int.random(in: 35...50), Int.random(in: 6...8), ["Strong", "Energized"]),
                ("HIIT", Int.random(in: 20...35), Int.random(in: 7...9), ["Energized", "Strong"]),
                ("Cycling", Int.random(in: 30...50), Int.random(in: 5...7), ["Energized", "Refreshed"]),
                ("Yoga", Int.random(in: 30...50), Int.random(in: 3...5), ["Calm", "Refreshed"]),
            ]
            return options.randomElement()!

        case .ovulation:
            let options: [(String, Int, Int, [String])] = [
                ("HIIT", Int.random(in: 25...40), Int.random(in: 8...10), ["Energized", "Accomplished"]),
                ("Full Body", Int.random(in: 40...60), Int.random(in: 7...9), ["Strong", "Accomplished"]),
                ("Running", Int.random(in: 30...50), Int.random(in: 7...9), ["Energized", "Strong"]),
                ("Dancing", Int.random(in: 30...45), Int.random(in: 6...8), ["Energized", "Refreshed"]),
            ]
            return options.randomElement()!

        case .luteal:
            let options: [(String, Int, Int, [String])] = [
                ("Yoga", Int.random(in: 30...45), Int.random(in: 3...5), ["Calm", "Refreshed"]),
                ("Walking", Int.random(in: 25...40), Int.random(in: 2...4), ["Calm", "Neutral"]),
                ("Pilates", Int.random(in: 30...45), Int.random(in: 4...6), ["Calm", "Tired"]),
                ("Lower Body", Int.random(in: 30...45), Int.random(in: 5...7), ["Tired", "Accomplished"]),
                ("Swimming", Int.random(in: 25...40), Int.random(in: 4...6), ["Refreshed", "Calm"]),
            ]
            return options.randomElement()!
        }
    }

    // MARK: - Clear Sample Data

    /// Clears all meal, movement, and check-in data (same as existing clear, but also resets insights)
    static func clearAllSampleData(modelContext: ModelContext) {
        do {
            let feelChecks = try modelContext.fetch(FetchDescriptor<FeelCheck>())
            let movements = try modelContext.fetch(FetchDescriptor<MovementEntry>())
            let meals = try modelContext.fetch(FetchDescriptor<MealEntry>())
            let insights = try modelContext.fetch(FetchDescriptor<PersonalInsight>())

            for item in feelChecks { modelContext.delete(item) }
            for item in movements { modelContext.delete(item) }
            for item in meals { modelContext.delete(item) }
            for item in insights { modelContext.delete(item) }

            // Reset insight generation hash so it re-runs
            UserDefaults.standard.removeObject(forKey: "insight_last_generation_date")
            UserDefaults.standard.removeObject(forKey: "insight_data_hash")

            try modelContext.save()
        } catch {
            print("Failed to clear sample data: \(error)")
        }
    }
}
