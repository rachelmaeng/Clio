import Foundation
import SwiftData

@Model
final class DailyCheckIn {
    var id: UUID
    var date: Date
    var state: String
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        state: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.date = Calendar.current.startOfDay(for: date)
        self.state = state
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // Available body states
    enum BodyState: String, CaseIterable, Identifiable {
        case energized = "Energized"
        case calm = "Calm"
        case foggy = "Foggy"
        case rested = "Rested"
        case heavy = "Heavy"
        case open = "Open"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .energized: return "sun.max.fill"
            case .calm: return "water.waves"
            case .foggy: return "cloud.fog.fill"
            case .rested: return "moon.stars.fill"
            case .heavy: return "circle.fill"
            case .open: return "sparkle"
            }
        }

        var description: String {
            switch self {
            case .energized: return "Sunburst"
            case .calm: return "Flowing water"
            case .foggy: return "Soft blur"
            case .rested: return "Deep stillness"
            case .heavy: return "Grounded earth"
            case .open: return "Expanding flower"
            }
        }

        var gradientColors: [String] {
            switch self {
            case .energized: return ["FFA500", "FFD700"]
            case .calm: return ["4A90D9", "87CEEB"]
            case .foggy: return ["9E9E9E", "BDBDBD"]
            case .rested: return ["1A237E", "3949AB"]
            case .heavy: return ["5D4037", "795548"]
            case .open: return ["E91E63", "F48FB1"]
            }
        }
    }

    var bodyState: BodyState? {
        BodyState(rawValue: state)
    }
}
