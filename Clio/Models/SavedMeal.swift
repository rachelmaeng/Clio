import Foundation
import SwiftData

@Model
final class SavedMeal {
    var id: UUID
    var name: String
    var foodItems: [String]
    var calories: Int?
    var protein: Int?
    var carbs: Int?
    var fat: Int?
    var mealType: String?
    var usageCount: Int
    var lastUsed: Date?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        foodItems: [String] = [],
        calories: Int? = nil,
        protein: Int? = nil,
        carbs: Int? = nil,
        fat: Int? = nil,
        mealType: String? = nil,
        usageCount: Int = 0,
        lastUsed: Date? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.foodItems = foodItems
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.mealType = mealType
        self.usageCount = usageCount
        self.lastUsed = lastUsed
        self.createdAt = createdAt
    }

    // MARK: - Computed Properties

    var hasMacros: Bool {
        calories != nil || protein != nil || carbs != nil || fat != nil
    }

    var macrosSummary: String? {
        var parts: [String] = []
        if let cal = calories { parts.append("\(cal) cal") }
        if let prot = protein { parts.append("\(prot)g protein") }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    // MARK: - Methods

    func incrementUsage() {
        usageCount += 1
        lastUsed = Date()
    }
}
