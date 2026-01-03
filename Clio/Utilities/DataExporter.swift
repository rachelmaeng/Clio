import Foundation
import SwiftData

struct ExportData: Codable {
    let exportDate: Date
    let checkIns: [CheckInExport]
    let movements: [MovementExport]
    let meals: [MealExport]

    struct CheckInExport: Codable {
        let date: Date
        let state: String
        let createdAt: Date
    }

    struct MovementExport: Codable {
        let dateTime: Date
        let type: String
        let energyLevel: Int
        let durationMinutes: Int?
        let notes: String?
        let createdAt: Date
    }

    struct MealExport: Codable {
        let dateTime: Date
        let mealType: String
        let description: String
        let sensations: [String]
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
        let checkInDescriptor = FetchDescriptor<DailyCheckIn>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        let movementDescriptor = FetchDescriptor<MovementEntry>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        let mealDescriptor = FetchDescriptor<MealEntry>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )

        let checkIns = try modelContext.fetch(checkInDescriptor)
        let movements = try modelContext.fetch(movementDescriptor)
        let meals = try modelContext.fetch(mealDescriptor)

        // Convert to export format
        let exportCheckIns = checkIns.map { checkIn in
            ExportData.CheckInExport(
                date: checkIn.date,
                state: checkIn.state,
                createdAt: checkIn.createdAt
            )
        }

        let exportMovements = movements.map { movement in
            ExportData.MovementExport(
                dateTime: movement.dateTime,
                type: movement.type,
                energyLevel: movement.energyLevel,
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
                sensations: meal.sensationTags,
                calories: meal.calories,
                protein: meal.protein,
                carbs: meal.carbs,
                fat: meal.fat,
                createdAt: meal.createdAt
            )
        }

        let exportData = ExportData(
            exportDate: Date(),
            checkIns: exportCheckIns,
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
        let checkIns = try modelContext.fetch(FetchDescriptor<DailyCheckIn>())
        let movements = try modelContext.fetch(FetchDescriptor<MovementEntry>())
        let meals = try modelContext.fetch(FetchDescriptor<MealEntry>())

        for checkIn in checkIns {
            modelContext.delete(checkIn)
        }
        for movement in movements {
            modelContext.delete(movement)
        }
        for meal in meals {
            modelContext.delete(meal)
        }

        try modelContext.save()
    }

    func getDataCounts() -> (checkIns: Int, movements: Int, meals: Int) {
        do {
            let checkIns = try modelContext.fetchCount(FetchDescriptor<DailyCheckIn>())
            let movements = try modelContext.fetchCount(FetchDescriptor<MovementEntry>())
            let meals = try modelContext.fetchCount(FetchDescriptor<MealEntry>())
            return (checkIns, movements, meals)
        } catch {
            return (0, 0, 0)
        }
    }
}
