import Foundation
import SwiftData

@Model
final class MovementEntry {
    var id: UUID
    var dateTime: Date
    var type: String
    var durationMinutes: Int?

    // MARK: - Calorie Burn (Optional)
    var estimatedCaloriesBurned: Int?

    // MARK: - How It Made You Feel (Optional)
    var feelAfter: [String]  // energized, calm, tired, etc.
    var intensityLevel: Int?  // 1-10
    var notes: String?

    // MARK: - Cycle Context
    var cyclePhase: String?
    var cycleDay: Int?

    // MARK: - From Tips
    var fromTipId: String?

    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        dateTime: Date = Date(),
        type: String,
        durationMinutes: Int? = nil,
        estimatedCaloriesBurned: Int? = nil,
        feelAfter: [String] = [],
        intensityLevel: Int? = nil,
        notes: String? = nil,
        cyclePhase: String? = nil,
        cycleDay: Int? = nil,
        fromTipId: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.dateTime = dateTime
        self.type = type
        self.durationMinutes = durationMinutes
        self.estimatedCaloriesBurned = estimatedCaloriesBurned
        self.feelAfter = feelAfter
        self.intensityLevel = intensityLevel
        self.notes = notes
        self.cyclePhase = cyclePhase
        self.cycleDay = cycleDay
        self.fromTipId = fromTipId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // MARK: - Movement Categories
    enum MovementCategory: String, CaseIterable, Identifiable {
        case cardio = "Cardio"
        case strength = "Strength"
        case flexibility = "Flexibility"
        case lowImpact = "Low Impact"
        case rest = "Rest"
        case custom = "Custom"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .cardio: return "heart.fill"
            case .strength: return "dumbbell.fill"
            case .flexibility: return "figure.yoga"
            case .lowImpact: return "leaf.fill"
            case .rest: return "moon.fill"
            case .custom: return "sparkles"
            }
        }

        var subtitle: String {
            switch self {
            case .cardio: return "Get your heart pumping"
            case .strength: return "Build & tone"
            case .flexibility: return "Stretch & flow"
            case .lowImpact: return "Gentle movement"
            case .rest: return "Recovery matters"
            case .custom: return "Your workout"
            }
        }

        var movementTypes: [MovementType] {
            switch self {
            case .cardio: return [.running, .hiit, .cycling, .dancing, .jumpRope]
            case .strength: return [.upperBody, .lowerBody, .push, .pull, .fullBody, .core]
            case .flexibility: return [.yoga, .pilates, .stretching]
            case .lowImpact: return [.walking, .hiking, .swimming, .taiChi, .gentleYoga, .leisureCycling]
            case .rest: return [.restDay]
            case .custom: return [.custom]
            }
        }
    }

    // MARK: - Movement Types
    enum MovementType: String, CaseIterable, Identifiable {
        // Cardio
        case running = "Running"
        case hiit = "HIIT"
        case cycling = "Cycling"
        case dancing = "Dancing"
        case jumpRope = "Jump Rope"

        // Strength Splits
        case upperBody = "Upper Body"
        case lowerBody = "Lower Body"
        case push = "Push"
        case pull = "Pull"
        case fullBody = "Full Body"
        case core = "Core"

        // Flexibility
        case yoga = "Yoga"
        case pilates = "Pilates"
        case stretching = "Stretching"

        // Low Impact
        case walking = "Walking"
        case hiking = "Hiking"
        case swimming = "Swimming"
        case taiChi = "Tai Chi"
        case gentleYoga = "Gentle Yoga"
        case leisureCycling = "Leisure Cycling"

        // Rest
        case restDay = "Rest day"

        // Custom
        case custom = "Custom"

        var id: String { rawValue }

        var icon: String {
            switch self {
            // Cardio
            case .running: return "figure.run"
            case .hiit: return "figure.highintensity.intervaltraining"
            case .cycling: return "figure.outdoor.cycle"
            case .dancing: return "figure.dance"
            case .jumpRope: return "figure.jumprope"
            // Strength
            case .upperBody: return "figure.arms.open"
            case .lowerBody: return "figure.walk"
            case .push: return "figure.strengthtraining.traditional"
            case .pull: return "figure.boxing"
            case .fullBody: return "dumbbell.fill"
            case .core: return "figure.core.training"
            // Flexibility
            case .yoga: return "figure.yoga"
            case .pilates: return "figure.pilates"
            case .stretching: return "figure.flexibility"
            // Low Impact
            case .walking: return "figure.walk"
            case .hiking: return "figure.hiking"
            case .swimming: return "figure.pool.swim"
            case .taiChi: return "figure.taichi"
            case .gentleYoga: return "figure.mind.and.body"
            case .leisureCycling: return "bicycle"
            // Rest & Custom
            case .restDay: return "bed.double"
            case .custom: return "sparkles"
            }
        }

        var intensity: Intensity {
            switch self {
            case .walking, .yoga, .stretching, .restDay, .gentleYoga, .taiChi, .leisureCycling:
                return .low
            case .pilates, .swimming, .cycling, .dancing, .hiking, .custom:
                return .medium
            case .hiit, .running, .upperBody, .lowerBody, .push, .pull, .fullBody, .core, .jumpRope:
                return .high
            }
        }

        /// Estimated calories burned per minute (rough average)
        var caloriesPerMinute: Double {
            switch intensity {
            case .low: return 3.0
            case .medium: return 6.0
            case .high: return 10.0
            }
        }

        enum Intensity: String {
            case low = "Low"
            case medium = "Medium"
            case high = "High"
        }
    }

    // MARK: - Feel After Options (9 options for movement feedback)
    enum FeelAfter: String, CaseIterable, Identifiable {
        case energized = "Energized"
        case strong = "Strong"
        case calm = "Calm"
        case tired = "Tired"
        case sore = "Sore"
        case accomplished = "Accomplished"
        case drained = "Drained"
        case refreshed = "Refreshed"
        case neutral = "Neutral"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .energized: return "bolt"
            case .strong: return "dumbbell"
            case .calm: return "leaf"
            case .tired: return "moon.zzz"
            case .sore: return "staroflife"
            case .accomplished: return "checkmark.seal"
            case .drained: return "battery.0"
            case .refreshed: return "arrow.counterclockwise"
            case .neutral: return "minus"
            }
        }

        var isPositive: Bool {
            switch self {
            case .energized, .strong, .calm, .accomplished, .refreshed, .neutral: return true
            case .tired, .sore, .drained: return false
            }
        }
    }

    // MARK: - Computed Properties

    var movementType: MovementType? {
        MovementType(rawValue: type)
    }

    var phase: CyclePhase? {
        guard let phaseString = cyclePhase else { return nil }
        return CyclePhase(rawValue: phaseString)
    }

    var hasFeelData: Bool {
        !feelAfter.isEmpty
    }

    var durationText: String {
        guard let minutes = durationMinutes else { return "" }
        if minutes >= 60 {
            let hours = minutes / 60
            let mins = minutes % 60
            return mins > 0 ? "\(hours)h \(mins)m" : "\(hours)h"
        }
        return "\(minutes) min"
    }

    var caloriesText: String? {
        guard let cals = estimatedCaloriesBurned else { return nil }
        return "\(cals) cal"
    }

    // MARK: - Helper Methods

    func calculateCaloriesBurned() {
        guard let minutes = durationMinutes,
              let movementType = movementType else { return }
        estimatedCaloriesBurned = Int(Double(minutes) * movementType.caloriesPerMinute)
    }

    func addFeelAfter(_ feel: FeelAfter) {
        if !feelAfter.contains(feel.rawValue) {
            feelAfter.append(feel.rawValue)
        }
    }

    func removeFeelAfter(_ feel: FeelAfter) {
        feelAfter.removeAll { $0 == feel.rawValue }
    }

    func setCycleContext(phase: CyclePhase, day: Int) {
        self.cyclePhase = phase.rawValue
        self.cycleDay = day
    }
}
