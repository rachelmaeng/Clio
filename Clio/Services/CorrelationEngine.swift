import Foundation
import SwiftData

/// Engine for detecting correlations between foods, movements, and how you feel
/// Uses neutral language: "has lined up with", "has correlated with"
/// Never uses causal language: "causes", "improves", "helps", "boosts"
class CorrelationEngine {

    // MARK: - Configuration

    /// Minimum check-ins needed for cross-signal insights
    static let minCheckIns = 3

    /// Minimum meals/movements needed for cross-signal insights
    static let minEntries = 3

    /// Minimum complete cycles for cycle-aware insights
    static let minCycles = 2

    /// Minimum correlation rate (60%)
    static let minCorrelationRate = 0.60

    /// Minimum days of data required for insights
    static let minDaysOfData = 3

    /// Minimum above baseline threshold (15%)
    static let minAboveBaseline = 0.15

    /// Minimum occurrences to establish a pattern
    static let minOccurrences = 3

    // MARK: - Data Requirements Check

    /// Check if user has minimum data for personalized insights
    static func hasMinimumDataForInsights(
        meals: [MealEntry],
        movements: [MovementEntry],
        feelChecks: [FeelCheck]
    ) -> Bool {
        let allDates = (meals.map { $0.dateTime } + movements.map { $0.dateTime } + feelChecks.map { $0.dateTime })
        guard let earliestDate = allDates.min() else { return false }
        let daysSinceStart = Calendar.current.dateComponents([.day], from: earliestDate, to: Date()).day ?? 0

        return daysSinceStart >= minDaysOfData &&
               feelChecks.count >= minCheckIns &&
               (meals.count >= minEntries || movements.count >= minEntries)
    }

    // MARK: - Main Analysis Entry Point

    /// Analyze all data and find correlations
    static func analyzePatterns(
        meals: [MealEntry],
        movements: [MovementEntry],
        feelChecks: [FeelCheck],
        existingInsights: [PersonalInsight]
    ) -> [DiscoveredPattern] {
        var patterns: [DiscoveredPattern] = []

        // Check minimum days of data requirement (14 days)
        let allDates = (meals.map { $0.dateTime } + movements.map { $0.dateTime } + feelChecks.map { $0.dateTime })
        guard let earliestDate = allDates.min() else { return patterns }
        let daysSinceStart = Calendar.current.dateComponents([.day], from: earliestDate, to: Date()).day ?? 0
        guard daysSinceStart >= minDaysOfData else { return patterns }

        // Check minimum data thresholds
        let hasEnoughForCrossSignal = feelChecks.count >= minCheckIns &&
            (meals.count >= minEntries || movements.count >= minEntries)

        // TYPE 1: Cross-signal correlations (movement/meal → check-in state)
        if hasEnoughForCrossSignal {
            patterns.append(contentsOf: analyzeMovementCheckInCorrelations(
                movements: movements,
                feelChecks: feelChecks
            ))
            patterns.append(contentsOf: analyzeMealCheckInCorrelations(
                meals: meals,
                feelChecks: feelChecks
            ))
            patterns.append(contentsOf: analyzeMealFeelAfterCorrelations(
                meals: meals,
                feelChecks: feelChecks
            ))

            // TYPE 2: Movement timing → check-in state
            patterns.append(contentsOf: analyzeMovementTimingCheckInCorrelations(
                movements: movements,
                feelChecks: feelChecks
            ))

            // TYPE 4: Meal timing → check-in state
            patterns.append(contentsOf: analyzeMealTimingCheckInCorrelations(
                meals: meals,
                feelChecks: feelChecks
            ))

            // TYPE 7: Movement feelAfter → check-in PrimaryState
            patterns.append(contentsOf: analyzeMovementFeelingCheckInCorrelations(
                movements: movements,
                feelChecks: feelChecks
            ))
        }

        // TYPE 6: Check-in PrimaryState → cycle phase
        if feelChecks.count >= minCheckIns {
            patterns.append(contentsOf: analyzeCheckInPhaseCorrelations(
                feelChecks: feelChecks
            ))
        }

        // Cycle-aware patterns (phase-specific)
        let completeCycles = countCompleteCycles(feelChecks: feelChecks)
        if completeCycles >= minCycles {
            patterns.append(contentsOf: analyzePhaseSpecificPatterns(
                meals: meals,
                movements: movements,
                feelChecks: feelChecks
            ))
        }

        // TYPE 3: Consistency observations (streaks, rest patterns)
        patterns.append(contentsOf: analyzeConsistencyPatterns(
            movements: movements,
            feelChecks: feelChecks
        ))

        // Filter out already existing insights
        let existingKeys = Set(existingInsights.map { "\($0.trigger)_\($0.outcome)_\($0.cyclePhase ?? "")" })
        patterns = patterns.filter { pattern in
            let key = "\(pattern.trigger)_\(pattern.outcome)_\(pattern.cyclePhase ?? "")"
            return !existingKeys.contains(key)
        }

        // Filter out dismissed patterns
        let dismissedKeys = Set(existingInsights.filter { $0.hasBeenDismissed }.map {
            "\($0.trigger)_\($0.outcome)_\($0.cyclePhase ?? "")"
        })
        patterns = patterns.filter { pattern in
            let key = "\(pattern.trigger)_\(pattern.outcome)_\(pattern.cyclePhase ?? "")"
            return !dismissedKeys.contains(key)
        }

        // Sort by confidence
        patterns.sort { $0.confidence > $1.confidence }

        // Deduplicate: keep only the strongest pattern per trigger
        patterns = deduplicatePatterns(patterns)

        // Ensure variety: max 2 per insight type, then cap at 5
        patterns = enforceVariety(patterns, maxPerType: 2, totalCap: 5)

        return patterns
    }

    // MARK: - TYPE 1: Cross-Signal Correlations

    /// Analyze: Does doing X movement line up with feeling Y in check-ins?
    private static func analyzeMovementCheckInCorrelations(
        movements: [MovementEntry],
        feelChecks: [FeelCheck]
    ) -> [DiscoveredPattern] {
        var patterns: [DiscoveredPattern] = []
        let calendar = Calendar.current

        // Map check-ins by date
        var checkInsByDate: [Date: FeelCheck] = [:]
        for check in feelChecks {
            let dayStart = calendar.startOfDay(for: check.dateTime)
            if checkInsByDate[dayStart] == nil {
                checkInsByDate[dayStart] = check
            }
        }

        // Calculate baseline PrimaryState rates
        let baselineRates = calculatePrimaryStateBaselineRates(feelChecks: feelChecks)

        // Group movements by type
        var movementsByType: [String: [MovementEntry]] = [:]
        for movement in movements {
            let type = movement.type.lowercased()
            movementsByType[type, default: []].append(movement)
        }

        // For each movement type, find correlations with PrimaryState
        for (movementType, typeMovements) in movementsByType {
            guard typeMovements.count >= minOccurrences else { continue }

            // Count PrimaryState occurrences on movement days
            var stateCounts: [String: Int] = [:]
            var daysWithCheckIn = 0
            var processedDays = Set<Date>()

            for movement in typeMovements {
                let moveDay = calendar.startOfDay(for: movement.dateTime)
                guard !processedDays.contains(moveDay) else { continue }
                processedDays.insert(moveDay)

                guard let checkIn = checkInsByDate[moveDay],
                      let primaryState = checkIn.primaryState else { continue }

                daysWithCheckIn += 1
                stateCounts[primaryState, default: 0] += 1
            }

            guard daysWithCheckIn >= minOccurrences else { continue }

            // Check each PrimaryState for significant correlation
            for (state, count) in stateCounts {
                let correlationRate = Double(count) / Double(daysWithCheckIn)
                let baseline = baselineRates[state] ?? 0.0
                let aboveBaseline = correlationRate - baseline

                if correlationRate >= minCorrelationRate && aboveBaseline >= minAboveBaseline {
                    let isPositive = FeelCheck.PrimaryState(rawValue: state)?.isPositive ?? true

                    patterns.append(DiscoveredPattern(
                        category: .movement,
                        insightType: .crossSignal,
                        trigger: movementType.capitalized,
                        outcome: state,
                        occurrences: count,
                        totalOpportunities: daysWithCheckIn,
                        confidence: correlationRate,
                        aboveBaseline: aboveBaseline,
                        isPositive: isPositive,
                        cyclePhase: nil
                    ))
                }
            }
        }

        return patterns
    }

    /// Analyze: Does eating certain foods line up with feeling Y in check-ins?
    /// Uses PrimaryState from check-ins, not moods or body sensations
    private static func analyzeMealCheckInCorrelations(
        meals: [MealEntry],
        feelChecks: [FeelCheck]
    ) -> [DiscoveredPattern] {
        var patterns: [DiscoveredPattern] = []
        let calendar = Calendar.current

        // Map check-ins by date
        var checkInsByDate: [Date: FeelCheck] = [:]
        for check in feelChecks {
            let dayStart = calendar.startOfDay(for: check.dateTime)
            if checkInsByDate[dayStart] == nil {
                checkInsByDate[dayStart] = check
            }
        }

        // Calculate baseline PrimaryState rates
        let baselineRates = calculatePrimaryStateBaselineRates(feelChecks: feelChecks)

        // Group meals by food items and correlate with PrimaryState
        var foodItemDays: [String: [(date: Date, checkIn: FeelCheck)]] = [:]

        for meal in meals {
            let mealDay = calendar.startOfDay(for: meal.dateTime)
            guard let checkIn = checkInsByDate[mealDay],
                  checkIn.primaryState != nil else { continue }

            for item in meal.foodItems {
                let normalized = item.lowercased()
                foodItemDays[normalized, default: []].append((date: mealDay, checkIn: checkIn))
            }
        }

        // For each food item, check PrimaryState correlations
        for (foodItem, entries) in foodItemDays {
            // Deduplicate by day
            var uniqueDays: [Date: FeelCheck] = [:]
            for entry in entries {
                if uniqueDays[entry.date] == nil {
                    uniqueDays[entry.date] = entry.checkIn
                }
            }

            guard uniqueDays.count >= minOccurrences else { continue }

            var stateCounts: [String: Int] = [:]
            for (_, checkIn) in uniqueDays {
                if let state = checkIn.primaryState {
                    stateCounts[state, default: 0] += 1
                }
            }

            for (state, count) in stateCounts {
                let correlationRate = Double(count) / Double(uniqueDays.count)
                let baseline = baselineRates[state] ?? 0.0
                let aboveBaseline = correlationRate - baseline

                if correlationRate >= minCorrelationRate && aboveBaseline >= minAboveBaseline {
                    let isPositive = FeelCheck.PrimaryState(rawValue: state)?.isPositive ?? true

                    patterns.append(DiscoveredPattern(
                        category: .food,
                        insightType: .crossSignal,
                        trigger: foodItem.capitalized,
                        outcome: state,
                        occurrences: count,
                        totalOpportunities: uniqueDays.count,
                        confidence: correlationRate,
                        aboveBaseline: aboveBaseline,
                        isPositive: isPositive,
                        cyclePhase: nil
                    ))
                }
            }
        }

        return patterns
    }

    /// Analyze meal feelAfter correlations:
    /// - meal type → feelAfter
    /// - time of day → feelAfter
    /// - feelAfter → check-in body sensations
    private static func analyzeMealFeelAfterCorrelations(
        meals: [MealEntry],
        feelChecks: [FeelCheck]
    ) -> [DiscoveredPattern] {
        var patterns: [DiscoveredPattern] = []
        let calendar = Calendar.current

        // Filter meals with feelAfter data
        let mealsWithFeelAfter = meals.filter { $0.feelAfter != nil }
        guard mealsWithFeelAfter.count >= minOccurrences else { return patterns }

        // Map check-ins by date
        var checkInsByDate: [Date: FeelCheck] = [:]
        for check in feelChecks {
            let dayStart = calendar.startOfDay(for: check.dateTime)
            if checkInsByDate[dayStart] == nil {
                checkInsByDate[dayStart] = check
            }
        }

        // 1. Meal type → feelAfter correlation
        var mealTypeFeelAfter: [String: [String: Int]] = [:]
        var mealTypeTotals: [String: Int] = [:]

        for meal in mealsWithFeelAfter {
            guard let feelAfter = meal.feelAfter else { continue }
            let mealType = meal.mealType

            mealTypeTotals[mealType, default: 0] += 1
            mealTypeFeelAfter[mealType, default: [:]][feelAfter, default: 0] += 1
        }

        for (mealType, feelAfterCounts) in mealTypeFeelAfter {
            guard let total = mealTypeTotals[mealType], total >= minOccurrences else { continue }

            for (feelAfter, count) in feelAfterCounts {
                let correlationRate = Double(count) / Double(total)

                if correlationRate >= minCorrelationRate {
                    let isPositive = MealEntry.MealFeelAfter(rawValue: feelAfter)?.isPositive ?? true

                    patterns.append(DiscoveredPattern(
                        category: .food,
                        insightType: .crossSignal,
                        trigger: mealType,
                        outcome: feelAfter.lowercased(),
                        occurrences: count,
                        totalOpportunities: total,
                        confidence: correlationRate,
                        aboveBaseline: 0.0,
                        isPositive: isPositive,
                        cyclePhase: nil
                    ))
                }
            }
        }

        // 2. Time of day → feelAfter correlation
        var timeOfDayFeelAfter: [String: [String: Int]] = [:]
        var timeOfDayTotals: [String: Int] = [:]

        for meal in mealsWithFeelAfter {
            guard let feelAfter = meal.feelAfter else { continue }
            let hour = calendar.component(.hour, from: meal.dateTime)

            let timeOfDay: String
            switch hour {
            case 5..<11: timeOfDay = "Morning"
            case 11..<14: timeOfDay = "Midday"
            case 14..<18: timeOfDay = "Afternoon"
            case 18..<22: timeOfDay = "Evening"
            default: timeOfDay = "Night"
            }

            timeOfDayTotals[timeOfDay, default: 0] += 1
            timeOfDayFeelAfter[timeOfDay, default: [:]][feelAfter, default: 0] += 1
        }

        for (timeOfDay, feelAfterCounts) in timeOfDayFeelAfter {
            guard let total = timeOfDayTotals[timeOfDay], total >= minOccurrences else { continue }

            for (feelAfter, count) in feelAfterCounts {
                let correlationRate = Double(count) / Double(total)

                if correlationRate >= minCorrelationRate {
                    let isPositive = MealEntry.MealFeelAfter(rawValue: feelAfter)?.isPositive ?? true

                    patterns.append(DiscoveredPattern(
                        category: .food,
                        insightType: .crossSignal,
                        trigger: "\(timeOfDay) meals",
                        outcome: feelAfter.lowercased(),
                        occurrences: count,
                        totalOpportunities: total,
                        confidence: correlationRate,
                        aboveBaseline: 0.0,
                        isPositive: isPositive,
                        cyclePhase: nil
                    ))
                }
            }
        }

        // 3. feelAfter → check-in PrimaryState alignment
        var feelAfterCheckInMatches: [String: [String: Int]] = [:]
        var feelAfterTotals: [String: Int] = [:]

        let primaryStateBaselineRates = calculatePrimaryStateBaselineRates(feelChecks: feelChecks)

        for meal in mealsWithFeelAfter {
            guard let feelAfter = meal.feelAfter else { continue }
            let mealDay = calendar.startOfDay(for: meal.dateTime)
            guard let checkIn = checkInsByDate[mealDay],
                  let primaryState = checkIn.primaryState else { continue }

            feelAfterTotals[feelAfter, default: 0] += 1
            feelAfterCheckInMatches[feelAfter, default: [:]][primaryState, default: 0] += 1
        }

        for (feelAfter, stateCounts) in feelAfterCheckInMatches {
            guard let total = feelAfterTotals[feelAfter], total >= minOccurrences else { continue }

            for (state, count) in stateCounts {
                let correlationRate = Double(count) / Double(total)
                let baseline = primaryStateBaselineRates[state] ?? 0.0
                let aboveBaseline = correlationRate - baseline

                if correlationRate >= minCorrelationRate && aboveBaseline >= minAboveBaseline {
                    let isPositive = FeelCheck.PrimaryState(rawValue: state)?.isPositive ?? true

                    patterns.append(DiscoveredPattern(
                        category: .food,
                        insightType: .crossSignal,
                        trigger: "Feeling \(feelAfter.lowercased()) after meals",
                        outcome: state,
                        occurrences: count,
                        totalOpportunities: total,
                        confidence: correlationRate,
                        aboveBaseline: aboveBaseline,
                        isPositive: isPositive,
                        cyclePhase: nil
                    ))
                }
            }
        }

        return patterns
    }

    // MARK: - TYPE 2: Movement Timing → Check-in State

    /// Analyze: Does exercising at a particular time of day line up with a PrimaryState?
    /// "On days you move before noon, you tend to feel more Energized"
    private static func analyzeMovementTimingCheckInCorrelations(
        movements: [MovementEntry],
        feelChecks: [FeelCheck]
    ) -> [DiscoveredPattern] {
        var patterns: [DiscoveredPattern] = []
        let calendar = Calendar.current

        // Map check-ins by date
        var checkInsByDate: [Date: FeelCheck] = [:]
        for check in feelChecks {
            let dayStart = calendar.startOfDay(for: check.dateTime)
            if checkInsByDate[dayStart] == nil {
                checkInsByDate[dayStart] = check
            }
        }

        // Calculate baseline PrimaryState rates
        let baselineRates = calculatePrimaryStateBaselineRates(feelChecks: feelChecks)

        // Group movements by time of day
        var movementsByTimeOfDay: [String: [MovementEntry]] = [:]
        for movement in movements {
            let hour = calendar.component(.hour, from: movement.dateTime)
            let timeOfDay: String
            switch hour {
            case 5..<12: timeOfDay = "before noon"
            case 12..<17: timeOfDay = "in the afternoon"
            default: timeOfDay = "in the evening"
            }
            movementsByTimeOfDay[timeOfDay, default: []].append(movement)
        }

        // For each time bucket, check PrimaryState correlations
        for (timeOfDay, timeMovements) in movementsByTimeOfDay {
            guard timeMovements.count >= minOccurrences else { continue }

            var stateCounts: [String: Int] = [:]
            var daysWithCheckIn = 0
            var processedDays = Set<Date>()

            for movement in timeMovements {
                let moveDay = calendar.startOfDay(for: movement.dateTime)
                guard !processedDays.contains(moveDay) else { continue }
                processedDays.insert(moveDay)

                guard let checkIn = checkInsByDate[moveDay],
                      let primaryState = checkIn.primaryState else { continue }

                daysWithCheckIn += 1
                stateCounts[primaryState, default: 0] += 1
            }

            guard daysWithCheckIn >= minOccurrences else { continue }

            for (state, count) in stateCounts {
                let correlationRate = Double(count) / Double(daysWithCheckIn)
                let baseline = baselineRates[state] ?? 0.0
                let aboveBaseline = correlationRate - baseline

                if correlationRate >= minCorrelationRate && aboveBaseline >= minAboveBaseline {
                    let isPositive = FeelCheck.PrimaryState(rawValue: state)?.isPositive ?? true

                    patterns.append(DiscoveredPattern(
                        category: .movement,
                        insightType: .movementTimingCheckin,
                        trigger: "Moving \(timeOfDay)",
                        outcome: state,
                        occurrences: count,
                        totalOpportunities: daysWithCheckIn,
                        confidence: correlationRate,
                        aboveBaseline: aboveBaseline,
                        isPositive: isPositive,
                        cyclePhase: nil
                    ))
                }
            }
        }

        return patterns
    }

    // MARK: - TYPE 4: Meal Timing → Check-in State

    /// Analyze: Does first meal timing correlate with PrimaryState?
    /// "On days you eat first meal before 10am, you tend to feel more Energized"
    private static func analyzeMealTimingCheckInCorrelations(
        meals: [MealEntry],
        feelChecks: [FeelCheck]
    ) -> [DiscoveredPattern] {
        var patterns: [DiscoveredPattern] = []
        let calendar = Calendar.current

        // Map check-ins by date
        var checkInsByDate: [Date: FeelCheck] = [:]
        for check in feelChecks {
            let dayStart = calendar.startOfDay(for: check.dateTime)
            if checkInsByDate[dayStart] == nil {
                checkInsByDate[dayStart] = check
            }
        }

        // Calculate baseline PrimaryState rates
        let baselineRates = calculatePrimaryStateBaselineRates(feelChecks: feelChecks)

        // Group meals by date, find first meal each day
        var firstMealByDate: [Date: MealEntry] = [:]
        for meal in meals.sorted(by: { $0.dateTime < $1.dateTime }) {
            let dayStart = calendar.startOfDay(for: meal.dateTime)
            if firstMealByDate[dayStart] == nil {
                firstMealByDate[dayStart] = meal
            }
        }

        // Categorize first meal timing
        var timingBuckets: [String: [(date: Date, checkIn: FeelCheck)]] = [:]

        for (date, meal) in firstMealByDate {
            guard let checkIn = checkInsByDate[date],
                  checkIn.primaryState != nil else { continue }

            let hour = calendar.component(.hour, from: meal.dateTime)
            let timing: String
            switch hour {
            case 0..<10: timing = "before 10am"
            case 10..<12: timing = "between 10am and noon"
            default: timing = "after noon"
            }

            timingBuckets[timing, default: []].append((date: date, checkIn: checkIn))
        }

        // Analyze each timing bucket
        for (timing, entries) in timingBuckets {
            guard entries.count >= minOccurrences else { continue }

            var stateCounts: [String: Int] = [:]
            for entry in entries {
                if let state = entry.checkIn.primaryState {
                    stateCounts[state, default: 0] += 1
                }
            }

            for (state, count) in stateCounts {
                let correlationRate = Double(count) / Double(entries.count)
                let baseline = baselineRates[state] ?? 0.0
                let aboveBaseline = correlationRate - baseline

                if correlationRate >= minCorrelationRate && aboveBaseline >= minAboveBaseline {
                    let isPositive = FeelCheck.PrimaryState(rawValue: state)?.isPositive ?? true

                    patterns.append(DiscoveredPattern(
                        category: .food,
                        insightType: .mealTimingCheckin,
                        trigger: "First meal \(timing)",
                        outcome: state,
                        occurrences: count,
                        totalOpportunities: entries.count,
                        confidence: correlationRate,
                        aboveBaseline: aboveBaseline,
                        isPositive: isPositive,
                        cyclePhase: nil
                    ))
                }
            }
        }

        return patterns
    }

    // MARK: - TYPE 6: Check-in PrimaryState → Cycle Phase

    /// Analyze: Does a particular PrimaryState appear more often in certain phases?
    /// "You tend to report Heavy more often during menstrual phase"
    private static func analyzeCheckInPhaseCorrelations(
        feelChecks: [FeelCheck]
    ) -> [DiscoveredPattern] {
        var patterns: [DiscoveredPattern] = []

        // Calculate overall baseline PrimaryState rates
        let overallBaseline = calculatePrimaryStateBaselineRates(feelChecks: feelChecks)

        // Group check-ins by phase
        var checkInsByPhase: [String: [FeelCheck]] = [:]
        for check in feelChecks {
            guard let phase = check.cyclePhase else { continue }
            checkInsByPhase[phase, default: []].append(check)
        }

        for (phase, phaseChecks) in checkInsByPhase {
            guard phaseChecks.count >= minOccurrences else { continue }

            // Count PrimaryState occurrences in this phase
            var stateCounts: [String: Int] = [:]
            var totalWithState = 0

            for check in phaseChecks {
                guard let state = check.primaryState else { continue }
                totalWithState += 1
                stateCounts[state, default: 0] += 1
            }

            guard totalWithState >= minOccurrences else { continue }

            for (state, count) in stateCounts {
                let phaseRate = Double(count) / Double(totalWithState)
                let baseline = overallBaseline[state] ?? 0.0
                let aboveBaseline = phaseRate - baseline

                // Phase patterns use slightly lower threshold since data is segmented
                if phaseRate >= 0.50 && aboveBaseline >= 0.10 && count >= 3 {
                    let isPositive = FeelCheck.PrimaryState(rawValue: state)?.isPositive ?? true

                    patterns.append(DiscoveredPattern(
                        category: .checkin,
                        insightType: .checkinPhase,
                        trigger: state,
                        outcome: phase,
                        occurrences: count,
                        totalOpportunities: totalWithState,
                        confidence: phaseRate,
                        aboveBaseline: aboveBaseline,
                        isPositive: isPositive,
                        cyclePhase: phase
                    ))
                }
            }
        }

        return patterns
    }

    // MARK: - TYPE 7: Movement FeelAfter → Check-in PrimaryState

    /// Analyze: When movement leaves you feeling X, do you check in as Y?
    /// "On days your workout left you feeling Strong, you also checked in as Energized"
    private static func analyzeMovementFeelingCheckInCorrelations(
        movements: [MovementEntry],
        feelChecks: [FeelCheck]
    ) -> [DiscoveredPattern] {
        var patterns: [DiscoveredPattern] = []
        let calendar = Calendar.current

        // Map check-ins by date
        var checkInsByDate: [Date: FeelCheck] = [:]
        for check in feelChecks {
            let dayStart = calendar.startOfDay(for: check.dateTime)
            if checkInsByDate[dayStart] == nil {
                checkInsByDate[dayStart] = check
            }
        }

        // Calculate baseline PrimaryState rates
        let baselineRates = calculatePrimaryStateBaselineRates(feelChecks: feelChecks)

        // Group by movement feelAfter
        var movementsByFeelAfter: [String: [MovementEntry]] = [:]
        for movement in movements {
            for feeling in movement.feelAfter {
                movementsByFeelAfter[feeling, default: []].append(movement)
            }
        }

        for (feelAfter, feelMovements) in movementsByFeelAfter {
            guard feelMovements.count >= minOccurrences else { continue }

            var stateCounts: [String: Int] = [:]
            var daysWithCheckIn = 0
            var processedDays = Set<Date>()

            for movement in feelMovements {
                let moveDay = calendar.startOfDay(for: movement.dateTime)
                guard !processedDays.contains(moveDay) else { continue }
                processedDays.insert(moveDay)

                guard let checkIn = checkInsByDate[moveDay],
                      let primaryState = checkIn.primaryState else { continue }

                daysWithCheckIn += 1
                stateCounts[primaryState, default: 0] += 1
            }

            guard daysWithCheckIn >= minOccurrences else { continue }

            for (state, count) in stateCounts {
                let correlationRate = Double(count) / Double(daysWithCheckIn)
                let baseline = baselineRates[state] ?? 0.0
                let aboveBaseline = correlationRate - baseline

                if correlationRate >= minCorrelationRate && aboveBaseline >= minAboveBaseline {
                    let isPositive = FeelCheck.PrimaryState(rawValue: state)?.isPositive ?? true

                    patterns.append(DiscoveredPattern(
                        category: .movement,
                        insightType: .movementFeelingCheckin,
                        trigger: feelAfter,
                        outcome: state,
                        occurrences: count,
                        totalOpportunities: daysWithCheckIn,
                        confidence: correlationRate,
                        aboveBaseline: aboveBaseline,
                        isPositive: isPositive,
                        cyclePhase: nil
                    ))
                }
            }
        }

        return patterns
    }

    // MARK: - Cycle-Aware Patterns

    private static func analyzePhaseSpecificPatterns(
        meals: [MealEntry],
        movements: [MovementEntry],
        feelChecks: [FeelCheck]
    ) -> [DiscoveredPattern] {
        var patterns: [DiscoveredPattern] = []
        let calendar = Calendar.current

        // Map check-ins by date
        var checkInsByDate: [Date: FeelCheck] = [:]
        for check in feelChecks {
            let dayStart = calendar.startOfDay(for: check.dateTime)
            if checkInsByDate[dayStart] == nil {
                checkInsByDate[dayStart] = check
            }
        }

        // Calculate overall PrimaryState baseline (not phase-specific)
        let overallBaseline = calculatePrimaryStateBaselineRates(feelChecks: feelChecks)

        for phase in CyclePhase.allCases {
            let phaseName = phase.rawValue

            // Phase-specific movements
            let phaseMovements = movements.filter { $0.cyclePhase == phaseName }
            let phaseCheckIns = feelChecks.filter { $0.cyclePhase == phaseName }

            guard phaseMovements.count >= 3 && phaseCheckIns.count >= 3 else { continue }

            // Analyze movement → PrimaryState correlations for this phase
            var movementsByType: [String: [MovementEntry]] = [:]
            for movement in phaseMovements {
                let type = movement.type.lowercased()
                movementsByType[type, default: []].append(movement)
            }

            for (movementType, typeMovements) in movementsByType {
                guard typeMovements.count >= 2 else { continue }

                var stateCounts: [String: Int] = [:]
                var daysWithCheckIn = 0
                var processedDays = Set<Date>()

                for movement in typeMovements {
                    let moveDay = calendar.startOfDay(for: movement.dateTime)
                    guard !processedDays.contains(moveDay) else { continue }
                    processedDays.insert(moveDay)

                    guard let checkIn = checkInsByDate[moveDay],
                          let primaryState = checkIn.primaryState else { continue }

                    daysWithCheckIn += 1
                    stateCounts[primaryState, default: 0] += 1
                }

                guard daysWithCheckIn >= 2 else { continue }

                for (state, count) in stateCounts {
                    let correlationRate = Double(count) / Double(daysWithCheckIn)
                    let baseline = overallBaseline[state] ?? 0.0
                    let aboveBaseline = correlationRate - baseline

                    // Lower threshold for phase-specific (50% rate, 10% above)
                    if correlationRate >= 0.50 && aboveBaseline >= 0.10 {
                        let isPositive = FeelCheck.PrimaryState(rawValue: state)?.isPositive ?? true

                        patterns.append(DiscoveredPattern(
                            category: .movement,
                            insightType: .cycleAware,
                            trigger: movementType.capitalized,
                            outcome: state,
                            occurrences: count,
                            totalOpportunities: daysWithCheckIn,
                            confidence: correlationRate,
                            aboveBaseline: aboveBaseline,
                            isPositive: isPositive,
                            cyclePhase: phaseName
                        ))
                    }
                }
            }
        }

        return patterns
    }

    // MARK: - TYPE 3: Consistency Patterns

    private static func analyzeConsistencyPatterns(
        movements: [MovementEntry],
        feelChecks: [FeelCheck]
    ) -> [DiscoveredPattern] {
        var patterns: [DiscoveredPattern] = []
        let calendar = Calendar.current

        // Check for movement streaks
        let sortedMovements = movements.sorted { $0.dateTime < $1.dateTime }
        var currentStreak = 0
        var maxStreak = 0
        var lastMoveDate: Date?

        for movement in sortedMovements {
            let moveDay = calendar.startOfDay(for: movement.dateTime)

            if let last = lastMoveDate {
                let dayDiff = calendar.dateComponents([.day], from: last, to: moveDay).day ?? 0
                if dayDiff == 1 {
                    currentStreak += 1
                    maxStreak = max(maxStreak, currentStreak)
                } else if dayDiff > 1 {
                    currentStreak = 1
                }
            } else {
                currentStreak = 1
            }

            lastMoveDate = moveDay
        }

        // If they have a 5+ day streak, create a consistency insight
        if maxStreak >= 5 {
            patterns.append(DiscoveredPattern(
                category: .movement,
                insightType: .consistency,
                trigger: "Movement streak",
                outcome: "\(maxStreak) consecutive days",
                occurrences: maxStreak,
                totalOpportunities: maxStreak,
                confidence: 1.0,
                aboveBaseline: 0.0,
                isPositive: true,
                cyclePhase: nil
            ))
        }

        // Check rest day → next day energy pattern
        var checkInsByDate: [Date: FeelCheck] = [:]
        for check in feelChecks {
            let dayStart = calendar.startOfDay(for: check.dateTime)
            if checkInsByDate[dayStart] == nil {
                checkInsByDate[dayStart] = check
            }
        }

        let movementDays = Set(movements.map { calendar.startOfDay(for: $0.dateTime) })
        var restDayNextDayEnergy: [Int] = []

        for check in feelChecks {
            let checkDay = calendar.startOfDay(for: check.dateTime)
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: checkDay) else { continue }

            // If previous day was a rest day (no movement)
            if !movementDays.contains(previousDay) {
                restDayNextDayEnergy.append(check.energyLevel)
            }
        }

        if restDayNextDayEnergy.count >= 5 {
            let avgEnergy = Double(restDayNextDayEnergy.reduce(0, +)) / Double(restDayNextDayEnergy.count)
            let highEnergyCount = restDayNextDayEnergy.filter { $0 >= 7 }.count
            let highEnergyRate = Double(highEnergyCount) / Double(restDayNextDayEnergy.count)

            if highEnergyRate >= 0.60 {
                patterns.append(DiscoveredPattern(
                    category: .movement,
                    insightType: .consistency,
                    trigger: "Rest days",
                    outcome: "high_energy_next_day",
                    occurrences: highEnergyCount,
                    totalOpportunities: restDayNextDayEnergy.count,
                    confidence: highEnergyRate,
                    aboveBaseline: 0.0,
                    isPositive: true,
                    cyclePhase: nil
                ))
            }
        }

        return patterns
    }

    // MARK: - Deduplication & Variety

    /// Keep only the strongest pattern per trigger (e.g., one insight per "Yoga", one per "Salmon")
    private static func deduplicatePatterns(_ patterns: [DiscoveredPattern]) -> [DiscoveredPattern] {
        var bestByTrigger: [String: DiscoveredPattern] = [:]

        for pattern in patterns {
            let key = pattern.trigger.lowercased()
            if let existing = bestByTrigger[key] {
                // Keep the one with higher confidence
                if pattern.confidence > existing.confidence {
                    bestByTrigger[key] = pattern
                }
            } else {
                bestByTrigger[key] = pattern
            }
        }

        // Return sorted by confidence
        return bestByTrigger.values.sorted { $0.confidence > $1.confidence }
    }

    /// Ensure variety across insight types and cap total
    private static func enforceVariety(_ patterns: [DiscoveredPattern], maxPerType: Int, totalCap: Int) -> [DiscoveredPattern] {
        var result: [DiscoveredPattern] = []
        var countByType: [String: Int] = [:]

        for pattern in patterns {
            let typeKey = pattern.insightType.rawValue
            let currentCount = countByType[typeKey, default: 0]

            if currentCount < maxPerType {
                result.append(pattern)
                countByType[typeKey] = currentCount + 1
            }

            if result.count >= totalCap { break }
        }

        return result
    }

    // MARK: - Helper Methods

    /// Calculate baseline occurrence rates for moods and sensations
    private static func calculateMoodBaselineRates(feelChecks: [FeelCheck]) -> [String: Double] {
        var moodCounts: [String: Int] = [:]
        let totalDays = feelChecks.count

        guard totalDays > 0 else { return [:] }

        for check in feelChecks {
            for mood in check.moods {
                moodCounts[mood, default: 0] += 1
            }
            for sensation in check.bodySensations {
                moodCounts[sensation, default: 0] += 1
            }
            if check.energyLevel >= 7 {
                moodCounts["high_energy", default: 0] += 1
            }
            if check.energyLevel <= 4 {
                moodCounts["low_energy", default: 0] += 1
            }
        }

        var rates: [String: Double] = [:]
        for (mood, count) in moodCounts {
            rates[mood] = Double(count) / Double(totalDays)
        }

        return rates
    }

    /// Count complete menstrual cycles in the data
    private static func countCompleteCycles(feelChecks: [FeelCheck]) -> Int {
        let menstrualChecks = feelChecks.filter { $0.cyclePhase == CyclePhase.menstrual.rawValue }
        guard menstrualChecks.count >= 2 else { return 0 }

        let sorted = menstrualChecks.sorted { $0.dateTime < $1.dateTime }
        let calendar = Calendar.current

        var cycleCount = 0
        var lastMenstrualStart: Date?

        for check in sorted {
            let checkDay = calendar.startOfDay(for: check.dateTime)

            if let last = lastMenstrualStart {
                let daysSinceLast = calendar.dateComponents([.day], from: last, to: checkDay).day ?? 0
                // If at least 21 days since last menstrual start, count as new cycle
                if daysSinceLast >= 21 {
                    cycleCount += 1
                    lastMenstrualStart = checkDay
                }
            } else {
                lastMenstrualStart = checkDay
            }
        }

        return cycleCount
    }

    /// Calculate baseline occurrence rates for PrimaryState
    private static func calculatePrimaryStateBaselineRates(feelChecks: [FeelCheck]) -> [String: Double] {
        var stateCounts: [String: Int] = [:]
        var totalWithState = 0

        for check in feelChecks {
            guard let state = check.primaryState else { continue }
            totalWithState += 1
            stateCounts[state, default: 0] += 1
        }

        guard totalWithState > 0 else { return [:] }

        var rates: [String: Double] = [:]
        for (state, count) in stateCounts {
            rates[state] = Double(count) / Double(totalWithState)
        }

        return rates
    }

    /// Check if a mood or sensation is positive
    private static func isPositiveMoodOrSensation(_ state: String) -> Bool {
        let positiveMoods = ["Calm", "Happy", "Focused", "Motivated", "Content", "Hopeful"]
        let positiveSensations = ["Energized", "Rested", "Strong", "Light", "high_energy"]
        let positivePrimaryStates = ["Energized", "Calm", "Rested", "Balanced", "Neutral"]

        return positiveMoods.contains(state) ||
               positiveSensations.contains(state) ||
               positivePrimaryStates.contains(state) ||
               state == "high_energy"
    }
}

// MARK: - Discovered Pattern

struct DiscoveredPattern {
    enum Category {
        case food
        case movement
        case checkin
    }

    let category: Category
    let insightType: PersonalInsight.InsightType
    let trigger: String
    let outcome: String
    let occurrences: Int
    let totalOpportunities: Int
    let confidence: Double
    let aboveBaseline: Double
    let isPositive: Bool
    let cyclePhase: String?

    /// Generate neutral title - uses "has lined up with", "tends to"
    var title: String {
        let phasePrefix = cyclePhase != nil ? "During \(cyclePhase!.lowercased()), " : ""
        let stateDescription = formatOutcome(outcome)

        switch insightType {
        case .crossSignal:
            return "\(phasePrefix)\(trigger) has lined up with feeling \(stateDescription)"

        case .cycleAware:
            return "\(phasePrefix)\(trigger) has lined up with feeling \(stateDescription)"

        case .consistency:
            if trigger == "Movement streak" {
                return "You've moved \(outcome)"
            } else if trigger == "Rest days" {
                return "Rest days have lined up with next-day energy"
            }
            return "\(trigger) pattern observed"

        case .movementTimingCheckin:
            let timeWindow = trigger.lowercased().replacingOccurrences(of: "moving ", with: "")
            return "On days you move \(timeWindow), you tend to feel \(stateDescription)"

        case .mealTimingCheckin:
            return "On days your \(trigger.lowercased()), you tend to feel \(stateDescription)"

        case .checkinPhase:
            return "You tend to report \(trigger) more often during \(cyclePhase?.lowercased() ?? "this") phase"

        case .movementFeelingCheckin:
            return "On days your workout left you feeling \(trigger), you also checked in as \(stateDescription)"

        default:
            return "\(phasePrefix)\(trigger) has correlated with \(stateDescription)"
        }
    }

    /// Generate neutral body text
    var body: String {
        let daysText = totalOpportunities == 1 ? "day" : "days"
        let percentageText = "\(Int(confidence * 100))%"

        switch insightType {
        case .crossSignal:
            let aboveText = aboveBaseline > 0 ? " That's \(Int(aboveBaseline * 100))% more than your usual rate." : ""
            if let phase = cyclePhase {
                return "On days when you did \(trigger.lowercased()) during your \(phase.lowercased()) phase, you checked in with \(formatOutcome(outcome).lowercased()) \(occurrences)/\(totalOpportunities) times (\(percentageText)).\(aboveText)"
            } else {
                return "On days when you did \(trigger.lowercased()), you checked in with \(formatOutcome(outcome).lowercased()) \(occurrences)/\(totalOpportunities) times (\(percentageText)).\(aboveText)"
            }

        case .cycleAware:
            let phase = cyclePhase ?? "this phase"
            return "During your \(phase.lowercased()) phase, \(trigger.lowercased()) has lined up with feeling \(formatOutcome(outcome).lowercased()) \(percentageText) of the time. This pattern spans multiple cycles."

        case .consistency:
            if trigger == "Movement streak" {
                return "You've logged movement for \(outcome). That's a consistent pattern."
            } else if trigger == "Rest days" {
                return "After rest days, you've tended to check in with higher energy \(percentageText) of the time."
            }
            return "This pattern has appeared in your data."

        case .movementTimingCheckin:
            let timeWindow = trigger.lowercased().replacingOccurrences(of: "moving ", with: "")
            let aboveText = aboveBaseline > 0 ? " That's \(Int(aboveBaseline * 100))% more than your usual rate." : ""
            return "When you exercised \(timeWindow), you reported \(formatOutcome(outcome).lowercased()) \(occurrences)/\(totalOpportunities) \(daysText) (\(percentageText)).\(aboveText)"

        case .mealTimingCheckin:
            let aboveText = aboveBaseline > 0 ? " That's \(Int(aboveBaseline * 100))% more than your usual rate." : ""
            return "When your \(trigger.lowercased()), you checked in as \(formatOutcome(outcome).lowercased()) \(occurrences)/\(totalOpportunities) \(daysText) (\(percentageText)).\(aboveText)"

        case .checkinPhase:
            let aboveText = aboveBaseline > 0 ? " That's \(Int(aboveBaseline * 100))% more than your average across all phases." : ""
            return "During your \(cyclePhase?.lowercased() ?? "this") phase, you reported \(trigger.lowercased()) \(percentageText) of the time.\(aboveText) Based on \(totalOpportunities) check-ins."

        case .movementFeelingCheckin:
            let aboveText = aboveBaseline > 0 ? " That's \(Int(aboveBaseline * 100))% more than your usual rate." : ""
            return "When your movement left you feeling \(trigger.lowercased()), you reported \(formatOutcome(outcome).lowercased()) in your check-in \(occurrences)/\(totalOpportunities) \(daysText) (\(percentageText)).\(aboveText)"

        default:
            return "Based on your logs, \(trigger.lowercased()) has lined up with \(formatOutcome(outcome).lowercased()) \(percentageText) of the time."
        }
    }

    /// Format outcome for display
    private func formatOutcome(_ outcome: String) -> String {
        switch outcome {
        case "high_energy", "high_energy_next_day":
            return "higher energy"
        case "low_energy", "low_energy_next_day":
            return "lower energy"
        default:
            return outcome.replacingOccurrences(of: "_", with: " ").lowercased()
        }
    }

    /// Convert to PersonalInsight model
    func toInsight() -> PersonalInsight {
        let categoryString: String
        let triggerCategoryString: String
        switch category {
        case .food:
            categoryString = "food"
            triggerCategoryString = "food"
        case .movement:
            categoryString = "movement"
            triggerCategoryString = "movement"
        case .checkin:
            categoryString = "general"
            triggerCategoryString = "general"
        }

        return PersonalInsight(
            category: categoryString,
            insightType: insightType.rawValue,
            trigger: trigger,
            triggerCategory: triggerCategoryString,
            outcome: outcome,
            cyclePhase: cyclePhase,
            occurrences: occurrences,
            totalOpportunities: totalOpportunities,
            confidenceScore: confidence,
            title: title,
            body: body,
            suggestion: nil,
            isPositive: isPositive
        )
    }
}
