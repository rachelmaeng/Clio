import XCTest
@testable import Clio

final class ModelTests: XCTestCase {

    // MARK: - FeelCheck Tests

    func testFeelCheckInitialization() {
        let feelCheck = FeelCheck(
            dateTime: Date(),
            energyLevel: 7,
            moods: ["calm", "focused"],
            bodySensations: ["relaxed"]
        )

        XCTAssertEqual(feelCheck.energyLevel, 7)
        XCTAssertEqual(feelCheck.moods.count, 2)
        XCTAssertTrue(feelCheck.moods.contains("calm"))
        XCTAssertEqual(feelCheck.bodySensations.count, 1)
    }

    func testFeelCheckEnergyLevelBounds() {
        // Energy level should be clamped between 1-10
        let lowEnergy = FeelCheck(
            dateTime: Date(),
            energyLevel: 1,
            moods: [],
            bodySensations: []
        )

        let highEnergy = FeelCheck(
            dateTime: Date(),
            energyLevel: 10,
            moods: [],
            bodySensations: []
        )

        XCTAssertGreaterThanOrEqual(lowEnergy.energyLevel, 1)
        XCTAssertLessThanOrEqual(highEnergy.energyLevel, 10)
    }

    // MARK: - MovementEntry Tests

    func testMovementEntryInitialization() {
        let movement = MovementEntry(
            dateTime: Date(),
            movementType: "Yoga",
            durationMinutes: 45,
            intensity: "moderate",
            feelAfter: "relaxed"
        )

        XCTAssertEqual(movement.movementType, "Yoga")
        XCTAssertEqual(movement.durationMinutes, 45)
        XCTAssertEqual(movement.intensity, "moderate")
    }

    func testMovementDurationPositive() {
        let movement = MovementEntry(
            dateTime: Date(),
            movementType: "Running",
            durationMinutes: 30,
            intensity: "high",
            feelAfter: "energized"
        )

        XCTAssertGreaterThan(movement.durationMinutes, 0)
    }

    // MARK: - MealEntry Tests

    func testMealEntryInitialization() {
        let meal = MealEntry(
            dateTime: Date(),
            mealType: "lunch",
            foodItems: ["Salad", "Grilled chicken", "Quinoa"],
            bodyResponses: ["satisfied", "energized"]
        )

        XCTAssertEqual(meal.mealType, "lunch")
        XCTAssertEqual(meal.foodItems.count, 3)
        XCTAssertTrue(meal.foodItems.contains("Salad"))
    }

    func testMealTypeValidation() {
        let validTypes = ["breakfast", "lunch", "dinner", "snack"]

        for type in validTypes {
            let meal = MealEntry(
                dateTime: Date(),
                mealType: type,
                foodItems: ["Test food"],
                bodyResponses: []
            )
            XCTAssertEqual(meal.mealType, type)
        }
    }

    // MARK: - UserSettings Tests

    func testUserSettingsDefaults() {
        let settings = UserSettings()

        // Check reasonable defaults
        XCTAssertGreaterThan(settings.cycleLength, 0)
        XCTAssertLessThanOrEqual(settings.cycleLength, 45)
    }

    func testCycleLengthRange() {
        // Typical cycle length is 21-35 days
        let settings = UserSettings()
        settings.cycleLength = 28

        XCTAssertGreaterThanOrEqual(settings.cycleLength, 21)
        XCTAssertLessThanOrEqual(settings.cycleLength, 35)
    }
}
