import Foundation
import SwiftData

/// Engine for detecting correlations between foods, movements, and how you feel
/// filtered by cycle phase
class CorrelationEngine {

    // MARK: - Configuration

    /// Minimum occurrences needed to establish a pattern
    static let minOccurrences = 3

    /// Minimum confidence score to surface an insight (0-1)
    static let minConfidence = 0.6

    // MARK: - Pattern Detection

    /// Analyze all data and find correlations
    static func analyzePatterns(
        meals: [MealEntry],
        movements: [MovementEntry],
        feelChecks: [FeelCheck],
        existingInsights: [PersonalInsight]
    ) -> [DiscoveredPattern] {
        var patterns: [DiscoveredPattern] = []

        // 1. Food → Body Response patterns
        patterns.append(contentsOf: analyzeFoodBodyPatterns(meals: meals))

        // 2. Movement → Feel After patterns
        patterns.append(contentsOf: analyzeMovementFeelPatterns(movements: movements))

        // 3. Food → Next Day Energy patterns
        patterns.append(contentsOf: analyzeFoodEnergyPatterns(meals: meals, feelChecks: feelChecks))

        // 4. Movement → Next Day Energy patterns
        patterns.append(contentsOf: analyzeMovementEnergyPatterns(movements: movements, feelChecks: feelChecks))

        // 5. Phase-specific patterns
        patterns.append(contentsOf: analyzePhasePatterns(meals: meals, movements: movements, feelChecks: feelChecks))

        // Filter out already existing insights
        let existingKeys = Set(existingInsights.map { "\($0.trigger)_\($0.outcome)_\($0.cyclePhase ?? "")" })
        patterns = patterns.filter { pattern in
            let key = "\(pattern.trigger)_\(pattern.outcome)_\(pattern.cyclePhase ?? "")"
            return !existingKeys.contains(key)
        }

        return patterns
    }

    // MARK: - Food → Body Response Analysis

    private static func analyzeFoodBodyPatterns(meals: [MealEntry]) -> [DiscoveredPattern] {
        var patterns: [DiscoveredPattern] = []

        // Group by food item
        var foodResponseCounts: [String: [String: Int]] = [:]  // food -> response -> count
        var foodTotalCounts: [String: Int] = [:]               // food -> total meals with that food

        for meal in meals {
            for food in meal.foodItems {
                let normalizedFood = food.lowercased().trimmingCharacters(in: .whitespaces)
                foodTotalCounts[normalizedFood, default: 0] += 1

                for response in meal.bodyResponses {
                    foodResponseCounts[normalizedFood, default: [:]][response, default: 0] += 1
                }
            }
        }

        // Find significant patterns
        for (food, responses) in foodResponseCounts {
            guard let totalCount = foodTotalCounts[food], totalCount >= minOccurrences else { continue }

            for (response, count) in responses {
                let confidence = Double(count) / Double(totalCount)

                if confidence >= minConfidence && count >= minOccurrences {
                    let isPositive = MealEntry.BodyResponse(rawValue: response)?.isPositive ?? true

                    patterns.append(DiscoveredPattern(
                        category: .food,
                        trigger: food.capitalized,
                        outcome: response,
                        occurrences: count,
                        confidence: confidence,
                        isPositive: isPositive,
                        cyclePhase: nil
                    ))
                }
            }
        }

        return patterns
    }

    // MARK: - Movement → Feel After Analysis

    private static func analyzeMovementFeelPatterns(movements: [MovementEntry]) -> [DiscoveredPattern] {
        var patterns: [DiscoveredPattern] = []

        var movementFeelCounts: [String: [String: Int]] = [:]
        var movementTotalCounts: [String: Int] = [:]

        for movement in movements {
            let type = movement.type.lowercased()
            movementTotalCounts[type, default: 0] += 1

            for feel in movement.feelAfter {
                movementFeelCounts[type, default: [:]][feel, default: 0] += 1
            }
        }

        for (movementType, feels) in movementFeelCounts {
            guard let totalCount = movementTotalCounts[movementType], totalCount >= minOccurrences else { continue }

            for (feel, count) in feels {
                let confidence = Double(count) / Double(totalCount)

                if confidence >= minConfidence && count >= minOccurrences {
                    let isPositive = MovementEntry.FeelAfter(rawValue: feel)?.isPositive ?? true

                    patterns.append(DiscoveredPattern(
                        category: .movement,
                        trigger: movementType.capitalized,
                        outcome: feel,
                        occurrences: count,
                        confidence: confidence,
                        isPositive: isPositive,
                        cyclePhase: nil
                    ))
                }
            }
        }

        return patterns
    }

    // MARK: - Food → Next Day Energy Analysis

    private static func analyzeFoodEnergyPatterns(meals: [MealEntry], feelChecks: [FeelCheck]) -> [DiscoveredPattern] {
        var patterns: [DiscoveredPattern] = []
        let calendar = Calendar.current

        // Map feel checks by date for quick lookup
        var feelChecksByDate: [Date: FeelCheck] = [:]
        for check in feelChecks {
            let dayStart = calendar.startOfDay(for: check.dateTime)
            if feelChecksByDate[dayStart] == nil {
                feelChecksByDate[dayStart] = check  // Take first check of day
            }
        }

        // Track food -> next day energy correlation
        var foodEnergySum: [String: Double] = [:]
        var foodEnergyCount: [String: Int] = [:]

        for meal in meals {
            // Find next day's feel check
            let mealDay = calendar.startOfDay(for: meal.dateTime)
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: mealDay),
                  let nextDayCheck = feelChecksByDate[nextDay] else { continue }

            for food in meal.foodItems {
                let normalizedFood = food.lowercased().trimmingCharacters(in: .whitespaces)
                foodEnergySum[normalizedFood, default: 0] += Double(nextDayCheck.energyLevel)
                foodEnergyCount[normalizedFood, default: 0] += 1
            }
        }

        // Find foods that correlate with high or low energy
        for (food, totalEnergy) in foodEnergySum {
            guard let count = foodEnergyCount[food], count >= minOccurrences else { continue }

            let avgEnergy = totalEnergy / Double(count)

            // High energy pattern (avg > 7)
            if avgEnergy >= 7.0 {
                let confidence = min((avgEnergy - 5.0) / 5.0, 1.0)  // Scale 5-10 to 0-1
                patterns.append(DiscoveredPattern(
                    category: .food,
                    trigger: food.capitalized,
                    outcome: "high_energy",
                    occurrences: count,
                    confidence: confidence,
                    isPositive: true,
                    cyclePhase: nil
                ))
            }
            // Low energy pattern (avg < 4)
            else if avgEnergy <= 4.0 {
                let confidence = min((5.0 - avgEnergy) / 5.0, 1.0)
                patterns.append(DiscoveredPattern(
                    category: .food,
                    trigger: food.capitalized,
                    outcome: "low_energy",
                    occurrences: count,
                    confidence: confidence,
                    isPositive: false,
                    cyclePhase: nil
                ))
            }
        }

        return patterns
    }

    // MARK: - Movement → Next Day Energy Analysis

    private static func analyzeMovementEnergyPatterns(movements: [MovementEntry], feelChecks: [FeelCheck]) -> [DiscoveredPattern] {
        var patterns: [DiscoveredPattern] = []
        let calendar = Calendar.current

        var feelChecksByDate: [Date: FeelCheck] = [:]
        for check in feelChecks {
            let dayStart = calendar.startOfDay(for: check.dateTime)
            if feelChecksByDate[dayStart] == nil {
                feelChecksByDate[dayStart] = check
            }
        }

        var movementEnergySum: [String: Double] = [:]
        var movementEnergyCount: [String: Int] = [:]

        for movement in movements {
            let moveDay = calendar.startOfDay(for: movement.dateTime)
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: moveDay),
                  let nextDayCheck = feelChecksByDate[nextDay] else { continue }

            let type = movement.type.lowercased()
            movementEnergySum[type, default: 0] += Double(nextDayCheck.energyLevel)
            movementEnergyCount[type, default: 0] += 1
        }

        for (movementType, totalEnergy) in movementEnergySum {
            guard let count = movementEnergyCount[movementType], count >= minOccurrences else { continue }

            let avgEnergy = totalEnergy / Double(count)

            if avgEnergy >= 7.0 {
                let confidence = min((avgEnergy - 5.0) / 5.0, 1.0)
                patterns.append(DiscoveredPattern(
                    category: .movement,
                    trigger: movementType.capitalized,
                    outcome: "high_energy_next_day",
                    occurrences: count,
                    confidence: confidence,
                    isPositive: true,
                    cyclePhase: nil
                ))
            } else if avgEnergy <= 4.0 {
                let confidence = min((5.0 - avgEnergy) / 5.0, 1.0)
                patterns.append(DiscoveredPattern(
                    category: .movement,
                    trigger: movementType.capitalized,
                    outcome: "low_energy_next_day",
                    occurrences: count,
                    confidence: confidence,
                    isPositive: false,
                    cyclePhase: nil
                ))
            }
        }

        return patterns
    }

    // MARK: - Phase-Specific Analysis

    private static func analyzePhasePatterns(
        meals: [MealEntry],
        movements: [MovementEntry],
        feelChecks: [FeelCheck]
    ) -> [DiscoveredPattern] {
        var patterns: [DiscoveredPattern] = []

        // Analyze by phase
        for phase in CyclePhase.allCases {
            let phaseName = phase.rawValue

            // Food patterns during this phase
            let phaseMeals = meals.filter { $0.cyclePhase == phaseName }
            patterns.append(contentsOf: analyzeFoodBodyPatternsForPhase(meals: phaseMeals, phase: phase))

            // Movement patterns during this phase
            let phaseMovements = movements.filter { $0.cyclePhase == phaseName }
            patterns.append(contentsOf: analyzeMovementFeelPatternsForPhase(movements: phaseMovements, phase: phase))
        }

        return patterns
    }

    private static func analyzeFoodBodyPatternsForPhase(meals: [MealEntry], phase: CyclePhase) -> [DiscoveredPattern] {
        var patterns: [DiscoveredPattern] = []

        var foodResponseCounts: [String: [String: Int]] = [:]
        var foodTotalCounts: [String: Int] = [:]

        for meal in meals {
            for food in meal.foodItems {
                let normalizedFood = food.lowercased().trimmingCharacters(in: .whitespaces)
                foodTotalCounts[normalizedFood, default: 0] += 1

                for response in meal.bodyResponses {
                    foodResponseCounts[normalizedFood, default: [:]][response, default: 0] += 1
                }
            }
        }

        for (food, responses) in foodResponseCounts {
            guard let totalCount = foodTotalCounts[food], totalCount >= 2 else { continue }  // Lower threshold for phase-specific

            for (response, count) in responses {
                let confidence = Double(count) / Double(totalCount)

                if confidence >= 0.7 && count >= 2 {
                    let isPositive = MealEntry.BodyResponse(rawValue: response)?.isPositive ?? true

                    patterns.append(DiscoveredPattern(
                        category: .food,
                        trigger: food.capitalized,
                        outcome: response,
                        occurrences: count,
                        confidence: confidence,
                        isPositive: isPositive,
                        cyclePhase: phase.rawValue
                    ))
                }
            }
        }

        return patterns
    }

    private static func analyzeMovementFeelPatternsForPhase(movements: [MovementEntry], phase: CyclePhase) -> [DiscoveredPattern] {
        var patterns: [DiscoveredPattern] = []

        var movementFeelCounts: [String: [String: Int]] = [:]
        var movementTotalCounts: [String: Int] = [:]

        for movement in movements {
            let type = movement.type.lowercased()
            movementTotalCounts[type, default: 0] += 1

            for feel in movement.feelAfter {
                movementFeelCounts[type, default: [:]][feel, default: 0] += 1
            }
        }

        for (movementType, feels) in movementFeelCounts {
            guard let totalCount = movementTotalCounts[movementType], totalCount >= 2 else { continue }

            for (feel, count) in feels {
                let confidence = Double(count) / Double(totalCount)

                if confidence >= 0.7 && count >= 2 {
                    let isPositive = MovementEntry.FeelAfter(rawValue: feel)?.isPositive ?? true

                    patterns.append(DiscoveredPattern(
                        category: .movement,
                        trigger: movementType.capitalized,
                        outcome: feel,
                        occurrences: count,
                        confidence: confidence,
                        isPositive: isPositive,
                        cyclePhase: phase.rawValue
                    ))
                }
            }
        }

        return patterns
    }
}

// MARK: - Discovered Pattern

struct DiscoveredPattern {
    enum Category {
        case food
        case movement
    }

    let category: Category
    let trigger: String           // The food or movement type
    let outcome: String           // The body response or feel after
    let occurrences: Int          // How many times this pattern was observed
    let confidence: Double        // 0-1 confidence score
    let isPositive: Bool          // Is this a positive or negative pattern?
    let cyclePhase: String?       // If phase-specific, which phase?

    /// Generate human-readable title
    var title: String {
        let phasePrefix = cyclePhase != nil ? "During \(cyclePhase!.lowercased()) phase, " : ""

        switch category {
        case .food:
            switch outcome {
            case "high_energy":
                return "\(phasePrefix)\(trigger) gives you energy"
            case "low_energy":
                return "\(phasePrefix)\(trigger) might drain your energy"
            default:
                let feeling = outcome.replacingOccurrences(of: "_", with: " ").lowercased()
                if isPositive {
                    return "\(phasePrefix)\(trigger) makes you feel \(feeling)"
                } else {
                    return "\(phasePrefix)\(trigger) might make you feel \(feeling)"
                }
            }

        case .movement:
            switch outcome {
            case "high_energy_next_day":
                return "\(phasePrefix)\(trigger) boosts your next-day energy"
            case "low_energy_next_day":
                return "\(phasePrefix)\(trigger) might tire you out"
            default:
                let feeling = outcome.replacingOccurrences(of: "_", with: " ").lowercased()
                if isPositive {
                    return "\(phasePrefix)\(trigger) helps you feel \(feeling)"
                } else {
                    return "\(phasePrefix)\(trigger) might leave you feeling \(feeling)"
                }
            }
        }
    }

    /// Generate human-readable body text
    var body: String {
        let times = occurrences == 1 ? "time" : "times"
        let confidenceText = confidence >= 0.8 ? "consistently" : "often"

        switch category {
        case .food:
            if let phase = cyclePhase {
                return "We noticed that when you eat \(trigger.lowercased()) during your \(phase.lowercased()) phase, you \(confidenceText) report feeling \(outcomeDescription). This has happened \(occurrences) \(times)."
            } else {
                return "Based on your logs, eating \(trigger.lowercased()) \(confidenceText) correlates with feeling \(outcomeDescription). We've seen this pattern \(occurrences) \(times)."
            }

        case .movement:
            if let phase = cyclePhase {
                return "When you do \(trigger.lowercased()) during your \(phase.lowercased()) phase, you \(confidenceText) feel \(outcomeDescription) afterward. This has happened \(occurrences) \(times)."
            } else {
                return "Your logs show that \(trigger.lowercased()) \(confidenceText) leaves you feeling \(outcomeDescription). We've noticed this \(occurrences) \(times)."
            }
        }
    }

    private var outcomeDescription: String {
        switch outcome {
        case "high_energy", "high_energy_next_day":
            return "more energized"
        case "low_energy", "low_energy_next_day":
            return "more tired"
        default:
            return outcome.replacingOccurrences(of: "_", with: " ").lowercased()
        }
    }

    /// Generate a suggestion
    var suggestion: String? {
        if isPositive {
            switch category {
            case .food:
                if let phase = cyclePhase {
                    return "Consider adding more \(trigger.lowercased()) to your meals during your \(phase.lowercased()) phase."
                } else {
                    return "\(trigger) seems to work well for your body. Keep it up!"
                }
            case .movement:
                if let phase = cyclePhase {
                    return "\(trigger) seems to be great for you during \(phase.lowercased()) phase. Try to include it in your routine."
                } else {
                    return "\(trigger) appears to be a good fit for your body. Consider making it a regular practice."
                }
            }
        } else {
            switch category {
            case .food:
                if let phase = cyclePhase {
                    return "You might want to be mindful of \(trigger.lowercased()) during your \(phase.lowercased()) phase and see if reducing it helps."
                } else {
                    return "Pay attention to how you feel after eating \(trigger.lowercased()). You might want to explore alternatives."
                }
            case .movement:
                if let phase = cyclePhase {
                    return "During your \(phase.lowercased()) phase, you might feel better with gentler alternatives to \(trigger.lowercased())."
                } else {
                    return "Consider gentler alternatives to \(trigger.lowercased()) when you're not feeling your best."
                }
            }
        }
    }

    /// Convert to PersonalInsight model
    func toInsight() -> PersonalInsight {
        PersonalInsight(
            category: category == .food ? "food" : "movement",
            trigger: trigger,
            outcome: outcome,
            cyclePhase: cyclePhase,
            occurrences: occurrences,
            confidenceScore: confidence,
            title: title,
            body: body,
            suggestion: suggestion,
            isPositive: isPositive
        )
    }
}
