import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DailyCheckIn.createdAt, order: .reverse) private var checkIns: [DailyCheckIn]
    @Query(sort: \MovementEntry.createdAt, order: .reverse) private var movements: [MovementEntry]
    @Query(sort: \MealEntry.createdAt, order: .reverse) private var meals: [MealEntry]

    @State private var showCheckIn = false
    @State private var showMovementLog = false
    @State private var showNourishmentLog = false

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<21: return "Good evening"
        default: return "Good night"
        }
    }

    private var todayCheckIn: DailyCheckIn? {
        let today = Calendar.current.startOfDay(for: Date())
        return checkIns.first { Calendar.current.isDate($0.createdAt, inSameDayAs: today) }
    }

    private var todayMeals: [MealEntry] {
        let today = Calendar.current.startOfDay(for: Date())
        return meals.filter { Calendar.current.isDate($0.createdAt, inSameDayAs: today) }
    }

    private var todayMovements: [MovementEntry] {
        let today = Calendar.current.startOfDay(for: Date())
        return movements.filter { Calendar.current.isDate($0.createdAt, inSameDayAs: today) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ClioTheme.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Greeting header
                        VStack(alignment: .leading, spacing: 8) {
                            Text(greeting)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundStyle(ClioTheme.text)

                            Text(formattedDate)
                                .font(.subheadline)
                                .foregroundStyle(ClioTheme.textMuted)
                        }
                        .padding(.top, 8)

                        // Contextual CTA Card
                        contextualCTACard

                        // Today's Activity Summary
                        if !todayMeals.isEmpty || !todayMovements.isEmpty || todayCheckIn != nil {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Today")
                                    .font(.headline)
                                    .foregroundStyle(ClioTheme.text)

                                VStack(spacing: 12) {
                                    if let checkIn = todayCheckIn {
                                        TodaySummaryRow(
                                            icon: "heart.fill",
                                            color: ClioTheme.primary,
                                            title: "Feeling \(checkIn.state)",
                                            subtitle: formatTime(checkIn.createdAt)
                                        )
                                    }

                                    if !todayMovements.isEmpty {
                                        let totalMinutes = todayMovements.compactMap { $0.durationMinutes }.reduce(0, +)
                                        TodaySummaryRow(
                                            icon: "figure.walk",
                                            color: ClioTheme.primary,
                                            title: "\(todayMovements.count) movement\(todayMovements.count == 1 ? "" : "s")",
                                            subtitle: "\(totalMinutes) minutes total"
                                        )
                                    }

                                    if !todayMeals.isEmpty {
                                        TodaySummaryRow(
                                            icon: "leaf.fill",
                                            color: Color(hex: "2DD4BF"),
                                            title: "\(todayMeals.count) meal\(todayMeals.count == 1 ? "" : "s") logged",
                                            subtitle: todayMeals.map { $0.mealType }.joined(separator: ", ")
                                        )
                                    }
                                }
                                .padding()
                                .background(ClioTheme.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                        }

                        // Quick Actions
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Log")
                                .font(.headline)
                                .foregroundStyle(ClioTheme.text)

                            HStack(spacing: 12) {
                                QuickActionButton(
                                    icon: "heart.fill",
                                    title: "Check-in",
                                    color: ClioTheme.primary
                                ) {
                                    showCheckIn = true
                                }

                                QuickActionButton(
                                    icon: "figure.walk",
                                    title: "Movement",
                                    color: ClioTheme.primary
                                ) {
                                    showMovementLog = true
                                }

                                QuickActionButton(
                                    icon: "leaf.fill",
                                    title: "Meal",
                                    color: Color(hex: "2DD4BF")
                                ) {
                                    showNourishmentLog = true
                                }
                            }
                        }

                        // Gentle reminder
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Clio")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(ClioTheme.textMuted)
                                .textCase(.uppercase)
                                .tracking(1.2)

                            Text("Noticing is enough. There's no right way to track.")
                                .font(.subheadline)
                                .foregroundStyle(ClioTheme.textMuted)
                                .lineSpacing(4)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(ClioTheme.surface.opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .padding()
                    .padding(.bottom, 100)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showCheckIn) {
                DailyCheckInView()
            }
            .sheet(isPresented: $showMovementLog) {
                MovementLogView()
            }
            .sheet(isPresented: $showNourishmentLog) {
                NourishmentLogView()
            }
        }
    }

    @ViewBuilder
    private var contextualCTACard: some View {
        let hour = Calendar.current.component(.hour, from: Date())

        VStack(alignment: .leading, spacing: 16) {
            if todayCheckIn == nil {
                // No check-in yet
                CTACard(
                    icon: "sun.horizon.fill",
                    title: "How are you feeling?",
                    subtitle: "Take a moment to notice your body's state",
                    buttonText: "Check in",
                    color: ClioTheme.primary
                ) {
                    showCheckIn = true
                }
            } else if hour >= 11 && hour < 14 && !todayMeals.contains(where: { $0.mealType == "Lunch" }) {
                // Lunch time, no lunch logged
                CTACard(
                    icon: "leaf.fill",
                    title: "Midday nourishment",
                    subtitle: "What's fueling your afternoon?",
                    buttonText: "Log meal",
                    color: Color(hex: "2DD4BF")
                ) {
                    showNourishmentLog = true
                }
            } else if hour >= 17 && hour < 20 && !todayMeals.contains(where: { $0.mealType == "Dinner" }) {
                // Dinner time
                CTACard(
                    icon: "moon.fill",
                    title: "Evening nourishment",
                    subtitle: "How are you closing the day?",
                    buttonText: "Log meal",
                    color: Color(hex: "818CF8")
                ) {
                    showNourishmentLog = true
                }
            } else if todayMovements.isEmpty {
                // No movement logged
                CTACard(
                    icon: "figure.wave",
                    title: "Any movement today?",
                    subtitle: "Even rest is a choice worth noting",
                    buttonText: "Log movement",
                    color: ClioTheme.primary
                ) {
                    showMovementLog = true
                }
            } else {
                // Default encouraging card
                CTACard(
                    icon: "sparkles",
                    title: "You're doing great",
                    subtitle: "Every moment of awareness matters",
                    buttonText: nil,
                    color: ClioTheme.primary
                ) {}
            }
        }
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: Date())
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

struct CTACard: View {
    let icon: String
    let title: String
    let subtitle: String
    let buttonText: String?
    let color: Color
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(ClioTheme.text)

                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(ClioTheme.textMuted)
                }

                Spacer()
            }

            if let buttonText = buttonText {
                Button(action: action) {
                    Text(buttonText)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(color)
                        .clipShape(Capsule())
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [color.opacity(0.15), ClioTheme.surface],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

struct TodaySummaryRow: View {
    let icon: String
    let color: Color
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(color)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(ClioTheme.text)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(ClioTheme.textMuted)
            }

            Spacer()
        }
    }
}

struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)

                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(ClioTheme.text)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(ClioTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HomeView()
        .modelContainer(for: [UserSettings.self, DailyCheckIn.self, MovementEntry.self, MealEntry.self], inMemory: true)
}
