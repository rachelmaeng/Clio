import Foundation
import SwiftData

struct Reflection: Identifiable {
    let id = UUID()
    let category: ReflectionCard.ReflectionCategory
    let text: String
    let detail: String
}

@MainActor
class ReflectionGenerator {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func generateReflections() -> [Reflection] {
        var reflections: [Reflection] = []

        // Fetch recent data (last 14 days)
        let twoWeeksAgo = Calendar.current.date(byAdding: .day, value: -14, to: Date()) ?? Date()

        // Fetch check-ins
        let checkInDescriptor = FetchDescriptor<DailyCheckIn>(
            predicate: #Predicate { $0.createdAt >= twoWeeksAgo },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )

        // Fetch movements
        let movementDescriptor = FetchDescriptor<MovementEntry>(
            predicate: #Predicate { $0.createdAt >= twoWeeksAgo },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )

        // Fetch meals
        let mealDescriptor = FetchDescriptor<MealEntry>(
            predicate: #Predicate { $0.createdAt >= twoWeeksAgo },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )

        do {
            let checkIns = try modelContext.fetch(checkInDescriptor)
            let movements = try modelContext.fetch(movementDescriptor)
            let meals = try modelContext.fetch(mealDescriptor)

            // Generate movement reflections
            if movements.count >= 2 {
                let pilatesSessions = movements.filter { $0.type == "Pilates" }
                if pilatesSessions.count >= 2 {
                    let avgEnergy = pilatesSessions.reduce(0) { $0 + $1.energyLevel } / pilatesSessions.count
                    if avgEnergy > 60 {
                        reflections.append(Reflection(
                            category: .movement,
                            text: "Your energy for Pilates has been vibrant lately.",
                            detail: "Based on \(pilatesSessions.count) sessions this week."
                        ))
                    }
                }

                let totalMinutes = movements.compactMap { $0.durationMinutes }.reduce(0, +)
                if totalMinutes > 100 {
                    reflections.append(Reflection(
                        category: .movement,
                        text: "You've moved with intention this week.",
                        detail: "\(totalMinutes) minutes of mindful movement."
                    ))
                }
            }

            // Generate check-in reflections
            if checkIns.count >= 3 {
                let calmDays = checkIns.filter { $0.state == "Calm" }.count
                if calmDays >= 2 {
                    reflections.append(Reflection(
                        category: .rest,
                        text: "Calm has been a recurring feeling this week.",
                        detail: "You felt calm on \(calmDays) of the last \(checkIns.count) days."
                    ))
                }

                let energizedDays = checkIns.filter { $0.state == "Energized" }.count
                if energizedDays >= 2 {
                    reflections.append(Reflection(
                        category: .energy,
                        text: "Your energy has been present and strong.",
                        detail: "Energized on \(energizedDays) recent days."
                    ))
                }
            }

            // Generate nourishment reflections
            if meals.count >= 3 {
                let mindfulMeals = meals.filter { $0.sensationTags.contains("Mindful") }
                if mindfulMeals.count >= 2 {
                    reflections.append(Reflection(
                        category: .nourishment,
                        text: "You've been eating with awareness lately.",
                        detail: "\(mindfulMeals.count) mindful meals logged."
                    ))
                }

                let groundedMeals = meals.filter { $0.sensationTags.contains("Grounded") }
                if groundedMeals.count >= 2 {
                    reflections.append(Reflection(
                        category: .nourishment,
                        text: "Your meals have been grounding you.",
                        detail: "\(groundedMeals.count) meals brought a sense of grounding."
                    ))
                }
            }

            // If no data, show gentle prompt
            if reflections.isEmpty {
                reflections.append(Reflection(
                    category: .rest,
                    text: "Noticing is enough. Log anything you want today.",
                    detail: "Your patterns will emerge over time."
                ))
            }

        } catch {
            print("Failed to fetch data for reflections: \(error)")
            reflections.append(Reflection(
                category: .rest,
                text: "Noticing is enough. Log anything you want today.",
                detail: "Your patterns will emerge over time."
            ))
        }

        // Limit to 6 reflections
        return Array(reflections.prefix(6))
    }
}
