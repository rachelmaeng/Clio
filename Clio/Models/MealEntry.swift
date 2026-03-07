import Foundation
import SwiftData

@Model
final class MealEntry {
    var id: UUID
    var dateTime: Date
    var mealType: String

    // MARK: - Food Items
    var foodItems: [String]  // List of food names
    var descriptionText: String
    var photoData: Data?

    // MARK: - Nutrition (Optional)
    var calories: Int?
    var protein: Int?
    var carbs: Int?
    var fat: Int?

    // MARK: - Whole Food Score
    var wholeFoodScore: Int?  // 1-10, higher = more whole foods
    var ingredientCount: Int?
    var hasPreservatives: Bool?

    // MARK: - Body Response (Per Meal)
    var bodyResponses: [String]  // bloated, gassy, energized, etc.
    var specificFoodReaction: String?  // If they know which food caused it
    var bodyResponseNotes: String?

    // MARK: - Feel After (Simple post-meal feeling)
    var feelAfter: String?  // "satisfied", "nourished", "energized", "sluggish", "bloated", "neutral"

    // MARK: - Cycle Context
    var cyclePhase: String?
    var cycleDay: Int?

    // MARK: - From Tips
    var fromTipId: String?  // If logged from a phase tip

    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        dateTime: Date = Date(),
        mealType: String,
        foodItems: [String] = [],
        descriptionText: String = "",
        photoData: Data? = nil,
        calories: Int? = nil,
        protein: Int? = nil,
        carbs: Int? = nil,
        fat: Int? = nil,
        wholeFoodScore: Int? = nil,
        ingredientCount: Int? = nil,
        hasPreservatives: Bool? = nil,
        bodyResponses: [String] = [],
        specificFoodReaction: String? = nil,
        bodyResponseNotes: String? = nil,
        feelAfter: String? = nil,
        cyclePhase: String? = nil,
        cycleDay: Int? = nil,
        fromTipId: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.dateTime = dateTime
        self.mealType = mealType
        self.foodItems = foodItems
        self.descriptionText = descriptionText
        self.photoData = photoData
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.wholeFoodScore = wholeFoodScore
        self.ingredientCount = ingredientCount
        self.hasPreservatives = hasPreservatives
        self.bodyResponses = bodyResponses
        self.specificFoodReaction = specificFoodReaction
        self.bodyResponseNotes = bodyResponseNotes
        self.feelAfter = feelAfter
        self.cyclePhase = cyclePhase
        self.cycleDay = cycleDay
        self.fromTipId = fromTipId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // MARK: - Meal Types
    enum MealType: String, CaseIterable, Identifiable {
        case breakfast = "Breakfast"
        case lunch = "Lunch"
        case dinner = "Dinner"
        case snack = "Snack"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .breakfast: return "sunrise"
            case .lunch: return "sun.max"
            case .dinner: return "moon"
            case .snack: return "sparkle"
            }
        }
    }

    // MARK: - Body Responses
    enum BodyResponse: String, CaseIterable, Identifiable {
        case energized = "Energized"
        case satisfied = "Satisfied"
        case light = "Light"
        case bloated = "Bloated"
        case gassy = "Gassy"
        case nauseous = "Nauseous"
        case sluggish = "Sluggish"
        case crampy = "Crampy"
        case neutral = "Neutral"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .energized: return "bolt"
            case .satisfied: return "checkmark"
            case .light: return "wind"
            case .bloated: return "circle"
            case .gassy: return "cloud"
            case .nauseous: return "waveform.path"
            case .sluggish: return "tortoise"
            case .crampy: return "staroflife"
            case .neutral: return "minus"
            }
        }

        var isPositive: Bool {
            switch self {
            case .energized, .satisfied, .light, .neutral: return true
            case .bloated, .gassy, .nauseous, .sluggish, .crampy: return false
            }
        }
    }

    // MARK: - Meal Feel After (Simple post-meal feeling)
    enum MealFeelAfter: String, CaseIterable, Identifiable {
        case satisfied = "Satisfied"
        case nourished = "Nourished"
        case energized = "Energized"
        case sluggish = "Sluggish"
        case bloated = "Bloated"
        case neutral = "Neutral"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .satisfied: return "checkmark.circle"
            case .nourished: return "leaf"
            case .energized: return "bolt"
            case .sluggish: return "tortoise"
            case .bloated: return "circle.circle"
            case .neutral: return "minus"
            }
        }

        var isPositive: Bool {
            switch self {
            case .satisfied, .nourished, .energized, .neutral: return true
            case .sluggish, .bloated: return false
            }
        }
    }

    // MARK: - Computed Properties

    var meal: MealType? {
        MealType(rawValue: mealType)
    }

    var hasNutritionData: Bool {
        calories != nil || protein != nil || carbs != nil || fat != nil
    }

    var hasBodyResponse: Bool {
        !bodyResponses.isEmpty
    }

    var phase: CyclePhase? {
        guard let phaseString = cyclePhase else { return nil }
        return CyclePhase(rawValue: phaseString)
    }

    var wholeFoodDescription: String {
        guard let score = wholeFoodScore else { return "Not rated" }
        switch score {
        case 8...10: return "Whole foods"
        case 5...7: return "Mixed"
        case 1...4: return "Processed"
        default: return "Not rated"
        }
    }

    var totalMacros: Int {
        (protein ?? 0) + (carbs ?? 0) + (fat ?? 0)
    }

    // MARK: - Helper Methods

    func addBodyResponse(_ response: BodyResponse) {
        if !bodyResponses.contains(response.rawValue) {
            bodyResponses.append(response.rawValue)
        }
    }

    func removeBodyResponse(_ response: BodyResponse) {
        bodyResponses.removeAll { $0 == response.rawValue }
    }

    func setCycleContext(phase: CyclePhase, day: Int) {
        self.cyclePhase = phase.rawValue
        self.cycleDay = day
    }
}
