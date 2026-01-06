import Foundation
import SwiftData

/// Engine for calculating cycle phases from period data
class CyclePhaseEngine {

    /// Calculate the current cycle phase based on last period start and cycle length
    static func currentPhase(lastPeriodStart: Date, cycleLength: Int = 28) -> CyclePhase {
        let today = Date()
        let dayOfCycle = dayInCycle(from: lastPeriodStart, to: today, cycleLength: cycleLength)
        return phase(forDay: dayOfCycle, cycleLength: cycleLength)
    }

    /// Calculate the cycle phase for a specific date
    static func phaseForDate(_ date: Date, lastPeriodStart: Date, cycleLength: Int = 28) -> CyclePhase {
        let dayOfCycle = dayInCycle(from: lastPeriodStart, to: date, cycleLength: cycleLength)
        return phase(forDay: dayOfCycle, cycleLength: cycleLength)
    }

    /// Get the current day in the cycle (1-based)
    static func dayInCycle(from periodStart: Date, to date: Date = Date(), cycleLength: Int = 28) -> Int {
        let calendar = Calendar.current
        let startOfPeriod = calendar.startOfDay(for: periodStart)
        let startOfDate = calendar.startOfDay(for: date)

        let days = calendar.dateComponents([.day], from: startOfPeriod, to: startOfDate).day ?? 0

        // Handle cycles that have wrapped around
        let dayInCycle = (days % cycleLength) + 1
        return max(1, dayInCycle)
    }

    /// Determine phase for a given day in the cycle
    static func phase(forDay day: Int, cycleLength: Int = 28) -> CyclePhase {
        // Adjust phase lengths proportionally to cycle length
        let menstrualEnd = 5
        let follicularEnd = Int(Double(cycleLength) * 0.46) // ~13 for 28-day
        let ovulationEnd = Int(Double(cycleLength) * 0.57)  // ~16 for 28-day

        switch day {
        case 1...menstrualEnd:
            return .menstrual
        case (menstrualEnd + 1)...follicularEnd:
            return .follicular
        case (follicularEnd + 1)...ovulationEnd:
            return .ovulation
        default:
            return .luteal
        }
    }

    /// Predict next period start date
    static func nextPeriodDate(lastPeriodStart: Date, cycleLength: Int = 28) -> Date {
        let calendar = Calendar.current
        return calendar.date(byAdding: .day, value: cycleLength, to: lastPeriodStart) ?? lastPeriodStart
    }

    /// Get days until next period
    static func daysUntilNextPeriod(lastPeriodStart: Date, cycleLength: Int = 28) -> Int {
        let nextPeriod = nextPeriodDate(lastPeriodStart: lastPeriodStart, cycleLength: cycleLength)
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: Date(), to: nextPeriod).day ?? 0
        return max(0, days)
    }

    /// Get phase info for display
    static func phaseInfo(lastPeriodStart: Date, cycleLength: Int = 28) -> PhaseInfo {
        let phase = currentPhase(lastPeriodStart: lastPeriodStart, cycleLength: cycleLength)
        let day = dayInCycle(from: lastPeriodStart, cycleLength: cycleLength)
        let daysUntilPeriod = daysUntilNextPeriod(lastPeriodStart: lastPeriodStart, cycleLength: cycleLength)

        return PhaseInfo(
            phase: phase,
            dayOfCycle: day,
            cycleLength: cycleLength,
            daysUntilNextPeriod: daysUntilPeriod
        )
    }

    /// Get all dates for each phase in the current cycle
    static func phaseDates(lastPeriodStart: Date, cycleLength: Int = 28) -> [CyclePhase: ClosedRange<Date>] {
        let calendar = Calendar.current
        var result: [CyclePhase: ClosedRange<Date>] = [:]

        let menstrualEnd = 5
        let follicularEnd = Int(Double(cycleLength) * 0.46)
        let ovulationEnd = Int(Double(cycleLength) * 0.57)

        // Menstrual: days 1-5
        let menstrualStart = lastPeriodStart
        let menstrualEndDate = calendar.date(byAdding: .day, value: menstrualEnd - 1, to: lastPeriodStart)!
        result[.menstrual] = menstrualStart...menstrualEndDate

        // Follicular: days 6-13
        let follicularStart = calendar.date(byAdding: .day, value: menstrualEnd, to: lastPeriodStart)!
        let follicularEndDate = calendar.date(byAdding: .day, value: follicularEnd - 1, to: lastPeriodStart)!
        result[.follicular] = follicularStart...follicularEndDate

        // Ovulation: days 14-16
        let ovulationStart = calendar.date(byAdding: .day, value: follicularEnd, to: lastPeriodStart)!
        let ovulationEndDate = calendar.date(byAdding: .day, value: ovulationEnd - 1, to: lastPeriodStart)!
        result[.ovulation] = ovulationStart...ovulationEndDate

        // Luteal: days 17-28
        let lutealStart = calendar.date(byAdding: .day, value: ovulationEnd, to: lastPeriodStart)!
        let lutealEndDate = calendar.date(byAdding: .day, value: cycleLength - 1, to: lastPeriodStart)!
        result[.luteal] = lutealStart...lutealEndDate

        return result
    }
}

// MARK: - Phase Info
struct PhaseInfo {
    let phase: CyclePhase
    let dayOfCycle: Int
    let cycleLength: Int
    let daysUntilNextPeriod: Int

    var phaseProgress: Double {
        let phaseDays: Int
        let dayInPhase: Int

        switch phase {
        case .menstrual:
            phaseDays = 5
            dayInPhase = dayOfCycle
        case .follicular:
            phaseDays = Int(Double(cycleLength) * 0.46) - 5
            dayInPhase = dayOfCycle - 5
        case .ovulation:
            let follicularEnd = Int(Double(cycleLength) * 0.46)
            phaseDays = Int(Double(cycleLength) * 0.57) - follicularEnd
            dayInPhase = dayOfCycle - follicularEnd
        case .luteal:
            let ovulationEnd = Int(Double(cycleLength) * 0.57)
            phaseDays = cycleLength - ovulationEnd
            dayInPhase = dayOfCycle - ovulationEnd
        }

        return min(1.0, Double(dayInPhase) / Double(max(1, phaseDays)))
    }

    var displayText: String {
        "Day \(dayOfCycle) · \(phase.description)"
    }

    var shortDisplayText: String {
        "Day \(dayOfCycle)"
    }
}
