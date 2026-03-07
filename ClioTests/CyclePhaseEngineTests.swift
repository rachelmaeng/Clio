import XCTest
@testable import Clio

final class CyclePhaseEngineTests: XCTestCase {

    // MARK: - Phase Calculation Tests

    func testMenstrualPhase() {
        // Day 1-5 should be menstrual phase
        let lastPeriodStart = Calendar.current.date(byAdding: .day, value: -3, to: Date())!
        let engine = CyclePhaseEngine(lastPeriodStart: lastPeriodStart, cycleLength: 28)

        XCTAssertEqual(engine.currentPhase, .menstrual)
        XCTAssertEqual(engine.currentDay, 4)
    }

    func testFollicularPhase() {
        // Day 6-13 should be follicular phase
        let lastPeriodStart = Calendar.current.date(byAdding: .day, value: -8, to: Date())!
        let engine = CyclePhaseEngine(lastPeriodStart: lastPeriodStart, cycleLength: 28)

        XCTAssertEqual(engine.currentPhase, .follicular)
    }

    func testOvulationPhase() {
        // Day 14-16 should be ovulation phase
        let lastPeriodStart = Calendar.current.date(byAdding: .day, value: -14, to: Date())!
        let engine = CyclePhaseEngine(lastPeriodStart: lastPeriodStart, cycleLength: 28)

        XCTAssertEqual(engine.currentPhase, .ovulation)
    }

    func testLutealPhase() {
        // Day 17-28 should be luteal phase
        let lastPeriodStart = Calendar.current.date(byAdding: .day, value: -20, to: Date())!
        let engine = CyclePhaseEngine(lastPeriodStart: lastPeriodStart, cycleLength: 28)

        XCTAssertEqual(engine.currentPhase, .luteal)
    }

    func testCycleWraparound() {
        // Day 30 of a 28-day cycle should wrap to day 2 (menstrual)
        let lastPeriodStart = Calendar.current.date(byAdding: .day, value: -29, to: Date())!
        let engine = CyclePhaseEngine(lastPeriodStart: lastPeriodStart, cycleLength: 28)

        // Should be in a new cycle
        XCTAssertEqual(engine.currentPhase, .menstrual)
    }

    func testCustomCycleLength() {
        // Test with a 35-day cycle
        let lastPeriodStart = Calendar.current.date(byAdding: .day, value: -18, to: Date())!
        let engine = CyclePhaseEngine(lastPeriodStart: lastPeriodStart, cycleLength: 35)

        // With longer cycle, day 19 should still be in follicular/ovulation
        XCTAssertNotEqual(engine.currentPhase, .menstrual)
    }

    // MARK: - Days Until Tests

    func testDaysUntilNextPhase() {
        let lastPeriodStart = Calendar.current.date(byAdding: .day, value: -2, to: Date())!
        let engine = CyclePhaseEngine(lastPeriodStart: lastPeriodStart, cycleLength: 28)

        // On day 3 of menstrual (days 1-5), should be 2-3 days until follicular
        let daysUntilNext = engine.daysUntilNextPhase
        XCTAssertGreaterThan(daysUntilNext, 0)
        XCTAssertLessThanOrEqual(daysUntilNext, 3)
    }

    func testDaysUntilPeriod() {
        let lastPeriodStart = Calendar.current.date(byAdding: .day, value: -20, to: Date())!
        let engine = CyclePhaseEngine(lastPeriodStart: lastPeriodStart, cycleLength: 28)

        // On day 21, should be about 7-8 days until next period
        let daysUntilPeriod = engine.daysUntilPeriod
        XCTAssertGreaterThan(daysUntilPeriod, 0)
        XCTAssertLessThanOrEqual(daysUntilPeriod, 10)
    }
}
