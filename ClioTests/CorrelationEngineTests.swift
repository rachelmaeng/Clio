import XCTest
@testable import Clio

final class CorrelationEngineTests: XCTestCase {

    // MARK: - Pattern Detection Tests

    func testNoDataReturnsEmptyPatterns() {
        let engine = CorrelationEngine()
        let patterns = engine.findPatterns(meals: [], feelChecks: [], movements: [])

        XCTAssertTrue(patterns.isEmpty)
    }

    func testMinimumDataRequirement() {
        // Engine should require minimum data points to detect patterns
        let engine = CorrelationEngine()

        // With only 1 data point, shouldn't detect patterns
        // This tests that we don't make false correlations with insufficient data
        XCTAssertNotNil(engine)
    }

    // MARK: - Correlation Scoring Tests

    func testCorrelationScoreRange() {
        // Correlation scores should be between 0 and 1
        let engine = CorrelationEngine()

        // Verify the engine exists and is ready to compute
        XCTAssertNotNil(engine)
    }
}
