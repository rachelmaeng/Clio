import SwiftUI
import SwiftData

struct MealHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \MealEntry.dateTime, order: .reverse) private var meals: [MealEntry]

    @State private var mealToEdit: MealEntry?

    private var groupedMeals: [(String, [MealEntry])] {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"

        let grouped = Dictionary(grouping: meals) { meal in
            Calendar.current.startOfDay(for: meal.dateTime)
        }

        return grouped.sorted { $0.key > $1.key }.map { (date, meals) in
            let label: String
            if Calendar.current.isDateInToday(date) {
                label = "Today"
            } else if Calendar.current.isDateInYesterday(date) {
                label = "Yesterday"
            } else {
                label = formatter.string(from: date)
            }
            return (label, meals.sorted { $0.dateTime < $1.dateTime })
        }
    }

    private var timeFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ClioTheme.background
                    .ignoresSafeArea()

                if meals.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "fork.knife")
                            .font(.system(size: 28))
                            .foregroundStyle(ClioTheme.textMuted.opacity(0.5))
                        Text("No meals logged yet")
                            .font(ClioTheme.bodyFont())
                            .foregroundStyle(ClioTheme.textMuted)
                    }
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 20) {
                            ForEach(groupedMeals, id: \.0) { dateLabel, dayMeals in
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(dateLabel.uppercased())
                                        .font(ClioTheme.captionFont(11))
                                        .fontWeight(.medium)
                                        .foregroundStyle(ClioTheme.textMuted)
                                        .tracking(0.5)

                                    VStack(spacing: 0) {
                                        ForEach(Array(dayMeals.enumerated()), id: \.element.id) { index, meal in
                                            Button {
                                                mealToEdit = meal
                                            } label: {
                                                mealRow(meal: meal)
                                            }
                                            .buttonStyle(.plain)

                                            if index < dayMeals.count - 1 {
                                                Divider()
                                                    .background(ClioTheme.textMuted.opacity(0.15))
                                                    .padding(.horizontal, 16)
                                            }
                                        }
                                    }
                                    .background(ClioTheme.surface)
                                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                }
                            }
                        }
                        .padding(.horizontal, ClioTheme.spacing)
                        .padding(.vertical, 16)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle("Meal History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    ClioCloseButton { dismiss() }
                }
            }
            .sheet(item: $mealToEdit) { meal in
                EditMealView(meal: meal)
            }
        }
    }

    private func mealRow(meal: MealEntry) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(ClioTheme.eatColor.opacity(0.12))
                    .frame(width: 36, height: 36)

                Image(systemName: meal.meal?.icon ?? "fork.knife")
                    .font(.system(size: 14))
                    .foregroundStyle(ClioTheme.eatColor)
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(meal.mealType)
                        .font(ClioTheme.labelFont(15))
                        .foregroundStyle(ClioTheme.text)

                    Spacer()

                    Text(timeFormatter.string(from: meal.dateTime))
                        .font(ClioTheme.captionFont(12))
                        .foregroundStyle(ClioTheme.textMuted)
                }

                if !meal.foodItems.isEmpty {
                    Text(meal.foodItems.joined(separator: ", "))
                        .font(ClioTheme.captionFont(12))
                        .foregroundStyle(ClioTheme.textMuted)
                        .lineLimit(1)
                }
            }
        }
        .padding(14)
    }
}

#Preview {
    MealHistoryView()
        .modelContainer(for: [MealEntry.self], inMemory: true)
}
