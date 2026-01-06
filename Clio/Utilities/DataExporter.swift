import Foundation
import SwiftData

struct ExportData: Codable {
    let exportDate: Date
    let feelChecks: [FeelCheckExport]
    let movements: [MovementExport]
    let meals: [MealExport]

    struct FeelCheckExport: Codable {
        let dateTime: Date
        let energyLevel: Int
        let moods: [String]
        let bodySensations: [String]
        let notes: String?
        let createdAt: Date
    }

    struct MovementExport: Codable {
        let dateTime: Date
        let type: String
        let intensityLevel: Int?
        let durationMinutes: Int?
        let notes: String?
        let createdAt: Date
    }

    struct MealExport: Codable {
        let dateTime: Date
        let mealType: String
        let description: String
        let bodyResponses: [String]
        let calories: Int?
        let protein: Int?
        let carbs: Int?
        let fat: Int?
        let createdAt: Date
    }
}

@MainActor
class DataExporter {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func exportToJSON() throws -> Data {
        // Fetch all data
        let feelCheckDescriptor = FetchDescriptor<FeelCheck>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        let movementDescriptor = FetchDescriptor<MovementEntry>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        let mealDescriptor = FetchDescriptor<MealEntry>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )

        let feelChecks = try modelContext.fetch(feelCheckDescriptor)
        let movements = try modelContext.fetch(movementDescriptor)
        let meals = try modelContext.fetch(mealDescriptor)

        // Convert to export format
        let exportFeelChecks = feelChecks.map { check in
            ExportData.FeelCheckExport(
                dateTime: check.dateTime,
                energyLevel: check.energyLevel,
                moods: check.moods,
                bodySensations: check.bodySensations,
                notes: check.notes,
                createdAt: check.createdAt
            )
        }

        let exportMovements = movements.map { movement in
            ExportData.MovementExport(
                dateTime: movement.dateTime,
                type: movement.type,
                intensityLevel: movement.intensityLevel,
                durationMinutes: movement.durationMinutes,
                notes: movement.notes,
                createdAt: movement.createdAt
            )
        }

        let exportMeals = meals.map { meal in
            ExportData.MealExport(
                dateTime: meal.dateTime,
                mealType: meal.mealType,
                description: meal.descriptionText,
                bodyResponses: meal.bodyResponses,
                calories: meal.calories,
                protein: meal.protein,
                carbs: meal.carbs,
                fat: meal.fat,
                createdAt: meal.createdAt
            )
        }

        let exportData = ExportData(
            exportDate: Date(),
            feelChecks: exportFeelChecks,
            movements: exportMovements,
            meals: exportMeals
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        return try encoder.encode(exportData)
    }

    func getExportURL() throws -> URL {
        let jsonData = try exportToJSON()

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: Date())

        let fileName = "clio-export-\(dateString).json"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        try jsonData.write(to: tempURL)
        return tempURL
    }

    func clearAllData() throws {
        // Fetch and delete all entries
        let feelChecks = try modelContext.fetch(FetchDescriptor<FeelCheck>())
        let movements = try modelContext.fetch(FetchDescriptor<MovementEntry>())
        let meals = try modelContext.fetch(FetchDescriptor<MealEntry>())

        for check in feelChecks {
            modelContext.delete(check)
        }
        for movement in movements {
            modelContext.delete(movement)
        }
        for meal in meals {
            modelContext.delete(meal)
        }

        try modelContext.save()
    }

    func getDataCounts() -> (feelChecks: Int, movements: Int, meals: Int) {
        do {
            let feelChecks = try modelContext.fetchCount(FetchDescriptor<FeelCheck>())
            let movements = try modelContext.fetchCount(FetchDescriptor<MovementEntry>())
            let meals = try modelContext.fetchCount(FetchDescriptor<MealEntry>())
            return (feelChecks, movements, meals)
        } catch {
            return (0, 0, 0)
        }
    }
}
