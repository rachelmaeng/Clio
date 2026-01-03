import Foundation
import SwiftData

@Model
final class UserSettings {
    var id: UUID
    var userName: String
    var showDailyNutritionContext: Bool
    var showCalories: Bool
    var notificationsEnabled: Bool
    var createdAt: Date

    init(
        id: UUID = UUID(),
        userName: String = "Friend",
        showDailyNutritionContext: Bool = false,
        showCalories: Bool = false,
        notificationsEnabled: Bool = true,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.userName = userName
        self.showDailyNutritionContext = showDailyNutritionContext
        self.showCalories = showCalories
        self.notificationsEnabled = notificationsEnabled
        self.createdAt = createdAt
    }
}
