import Foundation
import SwiftData

@Model
final class PersonalInsight {
    var id: UUID
    var category: String  // "food", "movement", "general"
    var insightType: String  // "correlation", "pattern", "suggestion"

    // MARK: - Pattern Data
    var trigger: String  // What was done: "yoga", "salmon", etc.
    var triggerCategory: String?  // "movement", "food"
    var outcome: String  // How they felt: "calm", "energized", etc.
    var cyclePhase: String?  // Which phase this applies to

    // MARK: - Confidence
    var occurrences: Int  // How many times this pattern was observed
    var totalOpportunities: Int  // How many times the trigger happened
    var confidenceScore: Double  // occurrences / totalOpportunities

    // MARK: - Display
    var title: String  // "Yoga helps you feel calm"
    var body: String  // "You've done yoga during menstrual phase 4 times..."
    var suggestion: String?  // "Try yoga again during your next menstrual phase"

    // MARK: - Status
    var isNew: Bool
    var hasBeenViewed: Bool
    var hasBeenDismissed: Bool
    var isPositive: Bool

    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        category: String,
        insightType: String = "correlation",
        trigger: String,
        triggerCategory: String? = nil,
        outcome: String,
        cyclePhase: String? = nil,
        occurrences: Int = 1,
        totalOpportunities: Int = 1,
        confidenceScore: Double = 1.0,
        title: String,
        body: String,
        suggestion: String? = nil,
        isNew: Bool = true,
        hasBeenViewed: Bool = false,
        hasBeenDismissed: Bool = false,
        isPositive: Bool = true,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.category = category
        self.insightType = insightType
        self.trigger = trigger
        self.triggerCategory = triggerCategory
        self.outcome = outcome
        self.cyclePhase = cyclePhase
        self.occurrences = occurrences
        self.totalOpportunities = totalOpportunities
        self.confidenceScore = confidenceScore
        self.title = title
        self.body = body
        self.suggestion = suggestion
        self.isNew = isNew
        self.hasBeenViewed = hasBeenViewed
        self.hasBeenDismissed = hasBeenDismissed
        self.isPositive = isPositive
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // MARK: - Insight Categories
    enum Category: String, CaseIterable {
        case food = "food"
        case movement = "movement"
        case general = "general"

        var icon: String {
            switch self {
            case .food: return "fork.knife"
            case .movement: return "figure.run"
            case .general: return "sparkles"
            }
        }

        var displayName: String {
            switch self {
            case .food: return "Nutrition"
            case .movement: return "Movement"
            case .general: return "General"
            }
        }
    }

    // MARK: - Insight Types
    enum InsightType: String, CaseIterable {
        case correlation = "correlation"  // "X leads to Y"
        case pattern = "pattern"  // "You tend to X during Y phase"
        case suggestion = "suggestion"  // "Based on patterns, try X"
        case milestone = "milestone"  // "You've logged 30 days!"

        var icon: String {
            switch self {
            case .correlation: return "arrow.triangle.branch"
            case .pattern: return "waveform.path.ecg.rectangle"
            case .suggestion: return "lightbulb.fill"
            case .milestone: return "star.fill"
            }
        }
    }

    // MARK: - Computed Properties

    var phase: CyclePhase? {
        guard let phaseString = cyclePhase else { return nil }
        return CyclePhase(rawValue: phaseString)
    }

    var categoryEnum: Category? {
        Category(rawValue: category)
    }

    var insightTypeEnum: InsightType? {
        InsightType(rawValue: insightType)
    }

    var confidenceLevel: ConfidenceLevel {
        switch confidenceScore {
        case 0.8...1.0: return .high
        case 0.6..<0.8: return .medium
        default: return .low
        }
    }

    var confidenceText: String {
        let percentage = Int(confidenceScore * 100)
        return "\(occurrences)/\(totalOpportunities) times (\(percentage)%)"
    }

    enum ConfidenceLevel: String {
        case high = "High"
        case medium = "Medium"
        case low = "Low"

        var color: String {
            switch self {
            case .high: return "forest"
            case .medium: return "terracotta"
            case .low: return "stone"
            }
        }
    }

    // MARK: - Helper Methods

    func markAsViewed() {
        isNew = false
        hasBeenViewed = true
        updatedAt = Date()
    }

    func dismiss() {
        hasBeenDismissed = true
        updatedAt = Date()
    }

    func updateOccurrence(occurred: Bool) {
        totalOpportunities += 1
        if occurred {
            occurrences += 1
        }
        confidenceScore = Double(occurrences) / Double(totalOpportunities)
        updatedAt = Date()
    }

    // MARK: - Static Factory Methods

    static func createFoodInsight(
        food: String,
        outcome: String,
        phase: CyclePhase?,
        occurrences: Int,
        total: Int
    ) -> PersonalInsight {
        let phaseText = phase.map { "during \($0.description.lowercased())" } ?? ""
        let confidence = Double(occurrences) / Double(total)

        return PersonalInsight(
            category: "food",
            insightType: "correlation",
            trigger: food,
            triggerCategory: "food",
            outcome: outcome,
            cyclePhase: phase?.rawValue,
            occurrences: occurrences,
            totalOpportunities: total,
            confidenceScore: confidence,
            title: "\(food) helps you feel \(outcome.lowercased())",
            body: "You've eaten \(food.lowercased()) \(phaseText) \(total) times and felt \(outcome.lowercased()) \(occurrences) times.",
            suggestion: "Consider adding \(food.lowercased()) to your meals \(phaseText)."
        )
    }

    static func createMovementInsight(
        movement: String,
        outcome: String,
        phase: CyclePhase?,
        occurrences: Int,
        total: Int
    ) -> PersonalInsight {
        let phaseText = phase.map { "during \($0.description.lowercased())" } ?? ""
        let confidence = Double(occurrences) / Double(total)

        return PersonalInsight(
            category: "movement",
            insightType: "correlation",
            trigger: movement,
            triggerCategory: "movement",
            outcome: outcome,
            cyclePhase: phase?.rawValue,
            occurrences: occurrences,
            totalOpportunities: total,
            confidenceScore: confidence,
            title: "\(movement) helps you feel \(outcome.lowercased())",
            body: "You've done \(movement.lowercased()) \(phaseText) \(total) times and felt \(outcome.lowercased()) \(occurrences) times.",
            suggestion: "Try \(movement.lowercased()) again \(phaseText)."
        )
    }
}
