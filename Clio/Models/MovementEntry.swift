import Foundation
import SwiftData

@Model
final class MovementEntry {
    var id: UUID
    var dateTime: Date
    var type: String
    var energyLevel: Int
    var durationMinutes: Int?
    var notes: String?
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        dateTime: Date = Date(),
        type: String,
        energyLevel: Int = 50,
        durationMinutes: Int? = nil,
        notes: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.dateTime = dateTime
        self.type = type
        self.energyLevel = energyLevel
        self.durationMinutes = durationMinutes
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    enum MovementType: String, CaseIterable, Identifiable {
        case pilates = "Pilates"
        case walk = "Walk"
        case strength = "Strength"
        case stretch = "Stretch"
        case rest = "Rest Day"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .pilates: return "figure.pilates"
            case .walk: return "figure.walk"
            case .strength: return "dumbbell.fill"
            case .stretch: return "figure.flexibility"
            case .rest: return "bed.double.fill"
            }
        }
    }

    var movementType: MovementType? {
        MovementType(rawValue: type)
    }

    var energyDescription: String {
        switch energyLevel {
        case 0..<33: return "Depleted"
        case 33..<66: return "Neutral"
        default: return "Vibrant"
        }
    }
}
