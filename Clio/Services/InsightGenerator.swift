import Foundation
import SwiftData

/// Service that generates and manages personal insights
/// Regeneration rules:
/// - On app open: regenerate if data changed since last run
/// - On new log entry: queue regeneration (debounced)
/// - Manually: user can trigger "refresh insights"
/// - Cache limit: keep max 5 active insights, archive viewed ones
class InsightGenerator {

    // MARK: - Configuration

    /// Maximum active insights to show
    static let maxActiveInsights = 5

    /// Debounce interval for regeneration (seconds)
    static let regenerationDebounce: TimeInterval = 30

    /// Storage key for last generation timestamp
    private static let lastGenerationKey = "insight_last_generation_date"

    /// Storage key for data hash (to detect changes)
    private static let dataHashKey = "insight_data_hash"

    // MARK: - Main Generation

    /// Run insight generation and save new insights to the model context
    static func generateInsights(modelContext: ModelContext) {
        // Fetch all data
        let mealDescriptor = FetchDescriptor<MealEntry>(sortBy: [SortDescriptor(\.dateTime, order: .reverse)])
        let movementDescriptor = FetchDescriptor<MovementEntry>(sortBy: [SortDescriptor(\.dateTime, order: .reverse)])
        let feelCheckDescriptor = FetchDescriptor<FeelCheck>(sortBy: [SortDescriptor(\.dateTime, order: .reverse)])
        let insightDescriptor = FetchDescriptor<PersonalInsight>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])

        guard let meals = try? modelContext.fetch(mealDescriptor),
              let movements = try? modelContext.fetch(movementDescriptor),
              let feelChecks = try? modelContext.fetch(feelCheckDescriptor),
              let existingInsights = try? modelContext.fetch(insightDescriptor) else {
            return
        }

        // Clear all non-dismissed insights so we get a fresh, deduplicated set
        for insight in existingInsights where !insight.hasBeenDismissed {
            modelContext.delete(insight)
        }

        // Run correlation analysis
        let patterns = CorrelationEngine.analyzePatterns(
            meals: meals,
            movements: movements,
            feelChecks: feelChecks,
            existingInsights: existingInsights
        )

        // Convert patterns to insights and save
        for pattern in patterns {
            let insight = pattern.toInsight()
            modelContext.insert(insight)
        }

        // Update last generation timestamp and data hash
        UserDefaults.standard.set(Date(), forKey: lastGenerationKey)
        let newHash = computeDataHash(meals: meals, movements: movements, feelChecks: feelChecks)
        UserDefaults.standard.set(newHash, forKey: dataHashKey)

        // Save context
        try? modelContext.save()
    }

    /// Check if we should run insight generation
    /// Returns true if:
    /// - Never run before AND minimum data exists
    /// - Data has changed since last generation
    /// - Enough time has passed with new data
    static func shouldGenerateInsights(
        modelContext: ModelContext
    ) -> Bool {
        // Fetch current data counts
        let mealDescriptor = FetchDescriptor<MealEntry>()
        let movementDescriptor = FetchDescriptor<MovementEntry>()
        let feelCheckDescriptor = FetchDescriptor<FeelCheck>()

        guard let meals = try? modelContext.fetch(mealDescriptor),
              let movements = try? modelContext.fetch(movementDescriptor),
              let feelChecks = try? modelContext.fetch(feelCheckDescriptor) else {
            return false
        }

        // Check minimum data thresholds
        let hasMinimumData = feelChecks.count >= CorrelationEngine.minCheckIns &&
            (meals.count >= CorrelationEngine.minEntries || movements.count >= CorrelationEngine.minEntries)

        guard hasMinimumData else { return false }

        // Check if never run before
        guard let lastGeneration = UserDefaults.standard.object(forKey: lastGenerationKey) as? Date else {
            return true  // First time generation
        }

        // Check if data has changed
        let currentHash = computeDataHash(meals: meals, movements: movements, feelChecks: feelChecks)
        let storedHash = UserDefaults.standard.string(forKey: dataHashKey) ?? ""

        if currentHash != storedHash {
            return true  // Data changed
        }

        // Check time since last generation (regenerate if > 24 hours)
        let hoursSinceLastGeneration = Date().timeIntervalSince(lastGeneration) / 3600
        if hoursSinceLastGeneration >= 24 {
            return true
        }

        return false
    }

    /// Force regeneration (user-triggered refresh)
    static func forceRegenerate(modelContext: ModelContext) {
        // Clear the stored hash to force regeneration
        UserDefaults.standard.removeObject(forKey: dataHashKey)
        generateInsights(modelContext: modelContext)
    }

    // MARK: - Insight Management

    /// Enforce the maximum number of active (non-dismissed, non-viewed) insights
    private static func enforceInsightLimit(
        modelContext: ModelContext,
        existingInsights: [PersonalInsight]
    ) {
        // Get active insights (not dismissed, not viewed too long ago)
        let activeInsights = existingInsights
            .filter { !$0.hasBeenDismissed }
            .sorted { $0.createdAt > $1.createdAt }

        // If over limit, archive older ones by marking as viewed
        if activeInsights.count > maxActiveInsights {
            let toArchive = activeInsights.dropFirst(maxActiveInsights)
            for insight in toArchive {
                if !insight.hasBeenViewed {
                    insight.hasBeenViewed = true
                    insight.isNew = false
                }
            }
        }
    }

    /// Dismiss an insight (won't be regenerated)
    static func dismissInsight(_ insight: PersonalInsight, modelContext: ModelContext) {
        insight.dismiss()
        try? modelContext.save()
    }

    /// Mark insight as viewed
    static func markAsViewed(_ insight: PersonalInsight, modelContext: ModelContext) {
        insight.markAsViewed()
        try? modelContext.save()
    }

    // MARK: - Data Hash

    /// Compute a hash of the current data state to detect changes
    private static func computeDataHash(
        meals: [MealEntry],
        movements: [MovementEntry],
        feelChecks: [FeelCheck]
    ) -> String {
        // Simple hash based on counts and most recent timestamps
        let mealHash = "\(meals.count)_\(meals.first?.updatedAt.timeIntervalSince1970 ?? 0)"
        let movementHash = "\(movements.count)_\(movements.first?.updatedAt.timeIntervalSince1970 ?? 0)"
        let checkHash = "\(feelChecks.count)_\(feelChecks.first?.dateTime.timeIntervalSince1970 ?? 0)"

        return "\(mealHash)|\(movementHash)|\(checkHash)"
    }

    // MARK: - Insight Grouping

    /// Group insights by their display category for the UI
    static func groupInsightsForDisplay(_ insights: [PersonalInsight]) -> [InsightGroup] {
        var groups: [String: [PersonalInsight]] = [:]

        // Filter to non-dismissed insights
        let activeInsights = insights.filter { !$0.hasBeenDismissed }

        for insight in activeInsights {
            let groupTitle: String
            if let type = PersonalInsight.InsightType(rawValue: insight.insightType) {
                groupTitle = type.groupTitle
            } else {
                groupTitle = "For you"
            }

            groups[groupTitle, default: []].append(insight)
        }

        // Convert to array and sort
        var result: [InsightGroup] = []

        // Define group order
        let orderedGroupNames = ["This cycle", "Over time", "Cycle patterns", "For you"]

        for groupName in orderedGroupNames {
            if let insights = groups[groupName], !insights.isEmpty {
                let sortedInsights = insights.sorted { $0.confidenceScore > $1.confidenceScore }
                result.append(InsightGroup(title: groupName, insights: sortedInsights))
            }
        }

        return result
    }

    /// Get insight summaries for display
    static func getInsightSummary(insights: [PersonalInsight]) -> InsightSummary {
        let activeInsights = insights.filter { !$0.hasBeenDismissed }
        let foodInsights = activeInsights.filter { $0.category == "food" }
        let movementInsights = activeInsights.filter { $0.category == "movement" }
        let positiveCount = activeInsights.filter { $0.isPositive }.count
        let newCount = activeInsights.filter { $0.isNew }.count

        return InsightSummary(
            totalInsights: activeInsights.count,
            foodInsights: foodInsights.count,
            movementInsights: movementInsights.count,
            positivePatterns: positiveCount,
            newInsights: newCount,
            topPositive: activeInsights.filter { $0.isPositive }.first,
            topNegative: activeInsights.filter { !$0.isPositive }.first
        )
    }

    /// Get insights relevant to current phase
    static func getInsightsForPhase(_ phase: CyclePhase, from insights: [PersonalInsight]) -> [PersonalInsight] {
        insights.filter { !$0.hasBeenDismissed && ($0.cyclePhase == phase.rawValue || $0.cyclePhase == nil) }
            .sorted { $0.confidenceScore > $1.confidenceScore }
    }
}

// MARK: - Insight Group

struct InsightGroup: Identifiable {
    let id = UUID()
    let title: String
    let insights: [PersonalInsight]

    var icon: String {
        switch title {
        case "This cycle":
            return "sparkles"
        case "Over time":
            return "chart.line.uptrend.xyaxis"
        case "Cycle patterns":
            return "moon.stars"
        default:
            return "lightbulb"
        }
    }
}

// MARK: - Insight Summary

struct InsightSummary {
    let totalInsights: Int
    let foodInsights: Int
    let movementInsights: Int
    let positivePatterns: Int
    let newInsights: Int
    let topPositive: PersonalInsight?
    let topNegative: PersonalInsight?

    var hasInsights: Bool {
        totalInsights > 0
    }

    var summaryText: String {
        if totalInsights == 0 {
            return "Keep logging to discover patterns"
        }

        var parts: [String] = []

        if foodInsights > 0 {
            parts.append("\(foodInsights) food pattern\(foodInsights == 1 ? "" : "s")")
        }

        if movementInsights > 0 {
            parts.append("\(movementInsights) movement pattern\(movementInsights == 1 ? "" : "s")")
        }

        return parts.joined(separator: " and ") + " discovered"
    }
}

// MARK: - Today Suggestion

struct TodaySuggestion: Identifiable {
    enum SuggestionType {
        case food
        case movement
    }

    let id = UUID()
    let type: SuggestionType
    let title: String
    let reason: String
    let confidence: Double

    var icon: String {
        switch type {
        case .food: return "fork.knife"
        case .movement: return "figure.run"
        }
    }
}
