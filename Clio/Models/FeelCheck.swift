import Foundation
import SwiftData

@Model
final class FeelCheck {
    var id: UUID
    var dateTime: Date

    // MARK: - Energy (Sliding Scale 1-10)
    var energyLevel: Int  // 1 = depleted, 10 = vibrant

    // MARK: - Mood (Multiple Selection)
    var moods: [String]

    // MARK: - Body Sensations
    var bodySensations: [String]

    // MARK: - Optional Notes
    var notes: String?

    // MARK: - Cycle Context
    var cyclePhase: String?
    var cycleDay: Int?

    var createdAt: Date

    init(
        id: UUID = UUID(),
        dateTime: Date = Date(),
        energyLevel: Int = 5,
        moods: [String] = [],
        bodySensations: [String] = [],
        notes: String? = nil,
        cyclePhase: String? = nil,
        cycleDay: Int? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.dateTime = dateTime
        self.energyLevel = energyLevel
        self.moods = moods
        self.bodySensations = bodySensations
        self.notes = notes
        self.cyclePhase = cyclePhase
        self.cycleDay = cycleDay
        self.createdAt = createdAt
    }

    // MARK: - Mood Options
    enum Mood: String, CaseIterable, Identifiable {
        case calm = "Calm"
        case happy = "Happy"
        case focused = "Focused"
        case motivated = "Motivated"
        case content = "Content"
        case hopeful = "Hopeful"
        case anxious = "Anxious"
        case irritable = "Irritable"
        case sad = "Sad"
        case stressed = "Stressed"
        case tired = "Tired"
        case neutral = "Neutral"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .calm: return "leaf"
            case .happy: return "sun.max"
            case .focused: return "scope"
            case .motivated: return "flame"
            case .content: return "heart"
            case .hopeful: return "sparkles"
            case .anxious: return "waveform"
            case .irritable: return "cloud.bolt"
            case .sad: return "cloud.rain"
            case .stressed: return "exclamationmark"
            case .tired: return "moon.zzz"
            case .neutral: return "minus"
            }
        }

        var isPositive: Bool {
            switch self {
            case .calm, .happy, .focused, .motivated, .content, .hopeful, .neutral: return true
            case .anxious, .irritable, .sad, .stressed, .tired: return false
            }
        }
    }

    // MARK: - Body Sensation Options
    enum BodySensation: String, CaseIterable, Identifiable {
        case energized = "Energized"
        case rested = "Rested"
        case strong = "Strong"
        case light = "Light"
        case tired = "Tired"
        case heavy = "Heavy"
        case crampy = "Crampy"
        case bloated = "Bloated"
        case headachy = "Headachy"
        case tense = "Tense"
        case achy = "Achy"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .energized: return "bolt"
            case .rested: return "bed.double"
            case .strong: return "dumbbell"
            case .light: return "wind"
            case .tired: return "battery.25"
            case .heavy: return "arrow.down.circle"
            case .crampy: return "staroflife"
            case .bloated: return "circle.circle"
            case .headachy: return "brain"
            case .tense: return "arrow.up.arrow.down"
            case .achy: return "figure.wave"
            }
        }

        var isPositive: Bool {
            switch self {
            case .energized, .rested, .strong, .light: return true
            case .tired, .heavy, .crampy, .bloated, .headachy, .tense, .achy: return false
            }
        }
    }

    // MARK: - Computed Properties

    var phase: CyclePhase? {
        guard let phaseString = cyclePhase else { return nil }
        return CyclePhase(rawValue: phaseString)
    }

    var energyDescription: String {
        switch energyLevel {
        case 1...3: return "Low"
        case 4...6: return "Moderate"
        case 7...10: return "High"
        default: return "Moderate"
        }
    }

    var overallFeeling: String {
        let positiveMoods = moods.compactMap { Mood(rawValue: $0) }.filter { $0.isPositive }.count
        let negativeMoods = moods.compactMap { Mood(rawValue: $0) }.filter { !$0.isPositive }.count

        if positiveMoods > negativeMoods && energyLevel >= 6 {
            return "Good"
        } else if negativeMoods > positiveMoods || energyLevel <= 3 {
            return "Tough"
        } else {
            return "Okay"
        }
    }

    // MARK: - Helper Methods

    func addMood(_ mood: Mood) {
        if !moods.contains(mood.rawValue) {
            moods.append(mood.rawValue)
        }
    }

    func removeMood(_ mood: Mood) {
        moods.removeAll { $0 == mood.rawValue }
    }

    func addBodySensation(_ sensation: BodySensation) {
        if !bodySensations.contains(sensation.rawValue) {
            bodySensations.append(sensation.rawValue)
        }
    }

    func removeBodySensation(_ sensation: BodySensation) {
        bodySensations.removeAll { $0 == sensation.rawValue }
    }

    func setCycleContext(phase: CyclePhase, day: Int) {
        self.cyclePhase = phase.rawValue
        self.cycleDay = day
    }
}
