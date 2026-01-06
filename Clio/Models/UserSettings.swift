import Foundation
import SwiftData

@Model
final class UserSettings {
    var id: UUID
    var email: String
    var userName: String

    // MARK: - Cycle Data
    var lastPeriodStart: Date?
    var cycleLength: Int
    var periodLength: Int

    // MARK: - Body Metrics (for calorie calculation)
    var heightCm: Int?
    var weightKg: Double?
    var birthYear: Int?
    var activityLevel: String?  // "sedentary", "light", "moderate", "active", "very_active"

    // MARK: - Goals (Optional)
    var hasCalorieGoal: Bool
    var calorieGoalType: String?  // "gain_muscle", "get_leaner", "lose_weight"
    var calorieRangeLow: Int?
    var calorieRangeHigh: Int?

    // MARK: - Fertility Goal (Optional, private)
    var fertilityGoal: String?  // "trying_to_conceive", "avoiding_pregnancy", "just_tracking"

    // MARK: - Allergens
    var allergens: [String]

    // MARK: - Toggles
    var showCalories: Bool
    var showMacros: Bool
    var showCalorieBurnEstimate: Bool
    var notificationsEnabled: Bool
    var feelCheckFrequency: String  // "daily", "twice_daily", "after_meals"

    // MARK: - Privacy
    var dataStoredOnDevice: Bool

    // MARK: - Onboarding
    var hasCompletedOnboarding: Bool

    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        email: String = "",
        userName: String = "",
        lastPeriodStart: Date? = nil,
        cycleLength: Int = 28,
        periodLength: Int = 5,
        heightCm: Int? = nil,
        weightKg: Double? = nil,
        birthYear: Int? = nil,
        activityLevel: String? = nil,
        hasCalorieGoal: Bool = false,
        calorieGoalType: String? = nil,
        calorieRangeLow: Int? = nil,
        calorieRangeHigh: Int? = nil,
        fertilityGoal: String? = nil,
        allergens: [String] = [],
        showCalories: Bool = true,
        showMacros: Bool = true,
        showCalorieBurnEstimate: Bool = true,
        notificationsEnabled: Bool = true,
        feelCheckFrequency: String = "daily",
        dataStoredOnDevice: Bool = true,
        hasCompletedOnboarding: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.email = email
        self.userName = userName
        self.lastPeriodStart = lastPeriodStart
        self.cycleLength = cycleLength
        self.periodLength = periodLength
        self.heightCm = heightCm
        self.weightKg = weightKg
        self.birthYear = birthYear
        self.activityLevel = activityLevel
        self.hasCalorieGoal = hasCalorieGoal
        self.calorieGoalType = calorieGoalType
        self.calorieRangeLow = calorieRangeLow
        self.calorieRangeHigh = calorieRangeHigh
        self.fertilityGoal = fertilityGoal
        self.allergens = allergens
        self.showCalories = showCalories
        self.showMacros = showMacros
        self.showCalorieBurnEstimate = showCalorieBurnEstimate
        self.notificationsEnabled = notificationsEnabled
        self.feelCheckFrequency = feelCheckFrequency
        self.dataStoredOnDevice = dataStoredOnDevice
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // MARK: - Computed Properties

    var currentPhaseInfo: PhaseInfo? {
        guard let lastPeriod = lastPeriodStart else { return nil }
        return CyclePhaseEngine.phaseInfo(lastPeriodStart: lastPeriod, cycleLength: cycleLength)
    }

    var currentPhase: CyclePhase? {
        currentPhaseInfo?.phase
    }

    var dayOfCycle: Int? {
        currentPhaseInfo?.dayOfCycle
    }

    var calorieGoalDescription: String? {
        guard let type = calorieGoalType else { return nil }
        switch type {
        case "gain_muscle": return "Build muscle"
        case "get_leaner": return "Get leaner"
        case "lose_weight": return "Lose weight"
        default: return nil
        }
    }

    var calorieRangeText: String? {
        guard let low = calorieRangeLow, let high = calorieRangeHigh else { return nil }
        return "\(low) - \(high) cal"
    }

    // MARK: - Goal Types
    enum GoalType: String, CaseIterable, Identifiable {
        case gainMuscle = "gain_muscle"
        case getLeaner = "get_leaner"
        case loseWeight = "lose_weight"

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .gainMuscle: return "Build muscle"
            case .getLeaner: return "Get leaner"
            case .loseWeight: return "Lose weight"
            }
        }

        var icon: String {
            switch self {
            case .gainMuscle: return "figure.strengthtraining.traditional"
            case .getLeaner: return "figure.run"
            case .loseWeight: return "scalemass"
            }
        }

        /// Suggested calorie ranges (these would ideally be calculated based on TDEE)
        var suggestedRange: (low: Int, high: Int) {
            switch self {
            case .gainMuscle: return (2200, 2800)
            case .getLeaner: return (1600, 2000)
            case .loseWeight: return (1400, 1800)
            }
        }
    }

    // MARK: - Feel Check Frequency
    enum FeelCheckFrequency: String, CaseIterable, Identifiable {
        case daily = "daily"
        case twiceDaily = "twice_daily"
        case afterMeals = "after_meals"
        case never = "never"

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .daily: return "Once daily (recommended)"
            case .twiceDaily: return "Twice daily"
            case .afterMeals: return "After meals"
            case .never: return "Never"
            }
        }
    }

    // MARK: - Fertility Goal (kept private/subtle)
    enum FertilityGoal: String, CaseIterable, Identifiable {
        case none = "none"
        case tryingToConceive = "trying_to_conceive"
        case avoidingPregnancy = "avoiding_pregnancy"
        case justTracking = "just_tracking"

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .none: return "Prefer not to say"
            case .tryingToConceive: return "Trying to conceive"
            case .avoidingPregnancy: return "Avoiding pregnancy"
            case .justTracking: return "Just tracking my cycle"
            }
        }

        var icon: String {
            switch self {
            case .none: return "hand.raised"
            case .tryingToConceive: return "heart.circle"
            case .avoidingPregnancy: return "shield"
            case .justTracking: return "calendar.circle"
            }
        }
    }

    // MARK: - Common Allergens
    static let commonAllergens = [
        "Dairy", "Gluten", "Eggs", "Peanuts", "Tree nuts",
        "Soy", "Fish", "Shellfish", "Sesame", "Wheat"
    ]

    // MARK: - Activity Level
    enum ActivityLevel: String, CaseIterable, Identifiable {
        case sedentary = "sedentary"
        case light = "light"
        case moderate = "moderate"
        case active = "active"
        case veryActive = "very_active"

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .sedentary: return "Sedentary"
            case .light: return "Lightly active"
            case .moderate: return "Moderately active"
            case .active: return "Active"
            case .veryActive: return "Very active"
            }
        }

        var description: String {
            switch self {
            case .sedentary: return "Desk job, little exercise"
            case .light: return "Light exercise 1-3 days/week"
            case .moderate: return "Moderate exercise 3-5 days/week"
            case .active: return "Hard exercise 6-7 days/week"
            case .veryActive: return "Very hard exercise, physical job"
            }
        }

        var multiplier: Double {
            switch self {
            case .sedentary: return 1.2
            case .light: return 1.375
            case .moderate: return 1.55
            case .active: return 1.725
            case .veryActive: return 1.9
            }
        }
    }

    // MARK: - TDEE Calculation (Mifflin-St Jeor for women)
    /// Calculates estimated TDEE based on user metrics
    func calculateTDEE() -> Int? {
        guard let height = heightCm,
              let weight = weightKg,
              let birthYear = birthYear,
              let activityStr = activityLevel,
              let activity = ActivityLevel(rawValue: activityStr) else {
            return nil
        }

        let currentYear = Calendar.current.component(.year, from: Date())
        let age = currentYear - birthYear

        // Mifflin-St Jeor formula for women:
        // BMR = (10 × weight in kg) + (6.25 × height in cm) − (5 × age in years) − 161
        let bmr = (10.0 * weight) + (6.25 * Double(height)) - (5.0 * Double(age)) - 161.0
        let tdee = bmr * activity.multiplier

        return Int(tdee)
    }

    /// Calculates suggested calorie range based on TDEE and goal
    func calculateCalorieRange(for goal: GoalType) -> (low: Int, high: Int)? {
        guard let tdee = calculateTDEE() else { return nil }

        switch goal {
        case .gainMuscle:
            // Surplus of 200-400 calories
            return (tdee + 200, tdee + 400)
        case .getLeaner:
            // Slight deficit of 100-300 calories
            return (tdee - 300, tdee - 100)
        case .loseWeight:
            // Moderate deficit of 300-500 calories
            return (tdee - 500, tdee - 300)
        }
    }
}
