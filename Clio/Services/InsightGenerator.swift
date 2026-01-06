import Foundation
import SwiftData

/// Service that generates and manages personal insights
class InsightGenerator {

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

        // Save context
        try? modelContext.save()
    }

    /// Check if we should run insight generation
    /// Returns true if enough time has passed since last generation or enough new data exists
    static func shouldGenerateInsights(
        lastGenerationDate: Date?,
        newDataCount: Int
    ) -> Bool {
        // Generate if never run before
        guard let lastDate = lastGenerationDate else {
            return newDataCount >= 5  // Need minimum data
        }

        let hoursSinceLastGeneration = Date().timeIntervalSince(lastDate) / 3600

        // Run at least every 24 hours if there's new data
        if hoursSinceLastGeneration >= 24 && newDataCount >= 1 {
            return true
        }

        // Run immediately if lots of new data
        if newDataCount >= 10 {
            return true
        }

        return false
    }

    /// Get insight summaries for display
    static func getInsightSummary(insights: [PersonalInsight]) -> InsightSummary {
        let foodInsights = insights.filter { $0.category == "food" }
        let movementInsights = insights.filter { $0.category == "movement" }
        let positiveCount = insights.filter { $0.isPositive }.count
        let newCount = insights.filter { $0.isNew }.count

        return InsightSummary(
            totalInsights: insights.count,
            foodInsights: foodInsights.count,
            movementInsights: movementInsights.count,
            positivePatterns: positiveCount,
            newInsights: newCount,
            topPositive: foodInsights.filter { $0.isPositive }.first ?? movementInsights.filter { $0.isPositive }.first,
            topNegative: foodInsights.filter { !$0.isPositive }.first ?? movementInsights.filter { !$0.isPositive }.first
        )
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

// MARK: - Insight Categories

extension InsightGenerator {

    /// Group insights by category for display
    static func groupInsightsByCategory(_ insights: [PersonalInsight]) -> [String: [PersonalInsight]] {
        var grouped: [String: [PersonalInsight]] = [:]

        for insight in insights {
            let category = insight.category
            grouped[category, default: []].append(insight)
        }

        return grouped
    }

    /// Group insights by phase for display
    static func groupInsightsByPhase(_ insights: [PersonalInsight]) -> [CyclePhase: [PersonalInsight]] {
        var grouped: [CyclePhase: [PersonalInsight]] = [:]

        for insight in insights {
            if let phaseString = insight.cyclePhase,
               let phase = CyclePhase(rawValue: phaseString) {
                grouped[phase, default: []].append(insight)
            }
        }

        return grouped
    }

    /// Get insights relevant to current phase
    static func getInsightsForPhase(_ phase: CyclePhase, from insights: [PersonalInsight]) -> [PersonalInsight] {
        insights.filter { $0.cyclePhase == phase.rawValue || $0.cyclePhase == nil }
            .sorted { $0.confidenceScore > $1.confidenceScore }
    }

    /// Get actionable suggestions for today
    static func getTodaySuggestions(
        phase: CyclePhase,
        insights: [PersonalInsight],
        recentMeals: [MealEntry],
        recentMovements: [MovementEntry]
    ) -> [TodaySuggestion] {
        var suggestions: [TodaySuggestion] = []

        // Get positive patterns for current phase
        let relevantInsights = getInsightsForPhase(phase, from: insights)
            .filter { $0.isPositive && !$0.hasBeenDismissed }
            .prefix(5)

        // Foods to include
        let recentFoods = Set(recentMeals.flatMap { $0.foodItems.map { $0.lowercased() } })
        let foodSuggestions = relevantInsights
            .filter { $0.category == "food" && !recentFoods.contains($0.trigger.lowercased()) }
            .map { TodaySuggestion(
                type: .food,
                title: "Try \($0.trigger)",
                reason: $0.title,
                confidence: $0.confidenceScore
            )}

        suggestions.append(contentsOf: foodSuggestions)

        // Movements to try
        let recentMoveTypes = Set(recentMovements.map { $0.type.lowercased() })
        let movementSuggestions = relevantInsights
            .filter { $0.category == "movement" && !recentMoveTypes.contains($0.trigger.lowercased()) }
            .map { TodaySuggestion(
                type: .movement,
                title: "Try \($0.trigger)",
                reason: $0.title,
                confidence: $0.confidenceScore
            )}

        suggestions.append(contentsOf: movementSuggestions)

        return Array(suggestions.prefix(3))
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
