import Foundation
import HealthKit

/// Service for integrating with Apple HealthKit
/// Handles reading cycle data, workouts, and writing workout data back to Health
@MainActor
class HealthKitService: ObservableObject {
    static let shared = HealthKitService()

    private let healthStore = HKHealthStore()

    @Published var isAuthorized = false
    @Published var authorizationError: String?

    // MARK: - Health Data Types

    /// Types we want to read from HealthKit
    private var readTypes: Set<HKObjectType> {
        var types: Set<HKObjectType> = [
            HKObjectType.workoutType(),
            HKQuantityType(.stepCount),
            HKQuantityType(.activeEnergyBurned),
            HKQuantityType(.distanceWalkingRunning)
        ]

        // Add menstrual cycle data if available
        if let menstrualFlow = HKCategoryType.categoryType(forIdentifier: .menstrualFlow) {
            types.insert(menstrualFlow)
        }
        if let ovulation = HKCategoryType.categoryType(forIdentifier: .ovulationTestResult) {
            types.insert(ovulation)
        }

        return types
    }

    /// Types we want to write to HealthKit
    private var writeTypes: Set<HKSampleType> {
        [
            HKObjectType.workoutType(),
            HKQuantityType(.activeEnergyBurned)
        ]
    }

    // MARK: - Authorization

    /// Check if HealthKit is available on this device
    var isHealthKitAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    /// Request authorization to access HealthKit data
    func requestAuthorization() async {
        guard isHealthKitAvailable else {
            authorizationError = "HealthKit is not available on this device"
            return
        }

        do {
            try await healthStore.requestAuthorization(toShare: writeTypes, read: readTypes)
            isAuthorized = true
            authorizationError = nil
        } catch {
            authorizationError = error.localizedDescription
            isAuthorized = false
        }
    }

    // MARK: - Reading Data

    /// Fetch today's step count
    func fetchTodaySteps() async -> Int? {
        guard isAuthorized else { return nil }

        let stepType = HKQuantityType(.stepCount)
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now)

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: stepType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, _ in
                let steps = statistics?.sumQuantity()?.doubleValue(for: .count())
                continuation.resume(returning: steps.map { Int($0) })
            }
            healthStore.execute(query)
        }
    }

    /// Fetch today's active calories burned
    func fetchTodayActiveCalories() async -> Double? {
        guard isAuthorized else { return nil }

        let calorieType = HKQuantityType(.activeEnergyBurned)
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now)

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: calorieType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, _ in
                let calories = statistics?.sumQuantity()?.doubleValue(for: .kilocalorie())
                continuation.resume(returning: calories)
            }
            healthStore.execute(query)
        }
    }

    /// Fetch recent workouts from HealthKit
    func fetchRecentWorkouts(limit: Int = 10) async -> [HKWorkout] {
        guard isAuthorized else { return [] }

        let workoutType = HKObjectType.workoutType()
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: workoutType,
                predicate: nil,
                limit: limit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, _ in
                let workouts = samples as? [HKWorkout] ?? []
                continuation.resume(returning: workouts)
            }
            healthStore.execute(query)
        }
    }

    /// Fetch menstrual flow data for cycle tracking
    func fetchMenstrualData(forLastDays days: Int = 90) async -> [Date] {
        guard isAuthorized,
              let menstrualType = HKCategoryType.categoryType(forIdentifier: .menstrualFlow) else {
            return []
        }

        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: endDate) ?? endDate
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: menstrualType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, _ in
                let dates = samples?.compactMap { $0.startDate } ?? []
                continuation.resume(returning: dates)
            }
            healthStore.execute(query)
        }
    }

    // MARK: - Writing Data

    /// Save a workout to HealthKit
    func saveWorkout(
        type: HKWorkoutActivityType,
        start: Date,
        end: Date,
        caloriesBurned: Double?
    ) async throws {
        guard isAuthorized else {
            throw HealthKitError.notAuthorized
        }

        var samples: [HKSample] = []

        // Add calories if provided
        if let calories = caloriesBurned, calories > 0 {
            let calorieType = HKQuantityType(.activeEnergyBurned)
            let calorieQuantity = HKQuantity(unit: .kilocalorie(), doubleValue: calories)
            let calorieSample = HKQuantitySample(
                type: calorieType,
                quantity: calorieQuantity,
                start: start,
                end: end
            )
            samples.append(calorieSample)
        }

        let workout = HKWorkout(
            activityType: type,
            start: start,
            end: end,
            workoutEvents: nil,
            totalEnergyBurned: caloriesBurned.map { HKQuantity(unit: .kilocalorie(), doubleValue: $0) },
            totalDistance: nil,
            metadata: [HKMetadataKeyWasUserEntered: true]
        )

        try await healthStore.save(workout)

        if !samples.isEmpty {
            try await healthStore.addSamples(samples, to: workout)
        }
    }

    /// Convert MovementEntry type to HealthKit workout type
    func workoutType(for movementType: String) -> HKWorkoutActivityType {
        switch movementType.lowercased() {
        case "cardio", "running", "run":
            return .running
        case "cycling", "bike":
            return .cycling
        case "swimming", "swim":
            return .swimming
        case "strength", "weights", "lifting":
            return .traditionalStrengthTraining
        case "yoga":
            return .yoga
        case "pilates":
            return .pilates
        case "hiit":
            return .highIntensityIntervalTraining
        case "walking", "walk":
            return .walking
        case "dance", "dancing":
            return .dance
        case "flexibility", "stretching":
            return .flexibility
        default:
            return .other
        }
    }
}

// MARK: - Errors

enum HealthKitError: LocalizedError {
    case notAuthorized
    case notAvailable
    case saveFailed(String)

    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "HealthKit access not authorized. Please enable in Settings."
        case .notAvailable:
            return "HealthKit is not available on this device."
        case .saveFailed(let message):
            return "Failed to save to HealthKit: \(message)"
        }
    }
}
