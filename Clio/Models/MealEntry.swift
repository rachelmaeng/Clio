import Foundation
import SwiftData

@Model
final class MealEntry {
    var id: UUID
    var dateTime: Date
    var mealType: String
    var descriptionText: String
    var sensationTags: [String]
    var photoData: Data?
    var calories: Int?
    var protein: Int?
    var carbs: Int?
    var fat: Int?
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        dateTime: Date = Date(),
        mealType: String,
        descriptionText: String = "",
        sensationTags: [String] = [],
        photoData: Data? = nil,
        calories: Int? = nil,
        protein: Int? = nil,
        carbs: Int? = nil,
        fat: Int? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.dateTime = dateTime
        self.mealType = mealType
        self.descriptionText = descriptionText
        self.sensationTags = sensationTags
        self.photoData = photoData
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    enum MealType: String, CaseIterable, Identifiable {
        case breakfast = "Breakfast"
        case lunch = "Lunch"
        case dinner = "Dinner"
        case snack = "Snack"

        var id: String { rawValue }
    }

    enum Sensation: String, CaseIterable, Identifiable {
        case grounded = "Grounded"
        case light = "Light"
        case heavy = "Heavy"
        case satisfied = "Satisfied"
        case mindful = "Mindful"
        case comforted = "Comforted"
        case rushed = "Rushed"
        case nourished = "Nourished"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .grounded: return "leaf.fill"
            case .light: return "wind"
            case .heavy: return "circle.fill"
            case .satisfied: return "checkmark.circle.fill"
            case .mindful: return "brain.head.profile"
            case .comforted: return "heart.fill"
            case .rushed: return "hare.fill"
            case .nourished: return "sparkles"
            }
        }
    }

    var meal: MealType? {
        MealType(rawValue: mealType)
    }

    var hasNutritionData: Bool {
        calories != nil || protein != nil || carbs != nil || fat != nil
    }
}
