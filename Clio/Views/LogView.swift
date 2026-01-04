import SwiftUI
import SwiftData

struct LogView: View {
    @State private var showCheckIn = false
    @State private var showMovementLog = false
    @State private var showNourishmentLog = false

    var body: some View {
        NavigationStack {
            ZStack {
                ClioTheme.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Header
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Log")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundStyle(ClioTheme.text)

                            Text("What would you like to notice?")
                                .font(.subheadline)
                                .foregroundStyle(ClioTheme.textMuted)
                        }
                        .padding(.top, 8)
                        .fadeInFromBottom(delay: 0)

                        // Log Options
                        VStack(spacing: 16) {
                            LogOptionCard(
                                icon: "heart.circle.fill",
                                title: "Body Check-in",
                                subtitle: "How are you feeling right now?",
                                color: ClioTheme.checkInColor,
                                gradient: ClioTheme.checkInGradient
                            ) {
                                showCheckIn = true
                            }
                            .staggeredAppearance(index: 0, delay: 0.1)

                            LogOptionCard(
                                icon: "figure.walk",
                                title: "Movement",
                                subtitle: "Log any physical activity",
                                color: ClioTheme.movementColor,
                                gradient: ClioTheme.movementGradient
                            ) {
                                showMovementLog = true
                            }
                            .staggeredAppearance(index: 1, delay: 0.1)

                            LogOptionCard(
                                icon: "fork.knife",
                                title: "Nourishment",
                                subtitle: "What's fueling your body?",
                                color: ClioTheme.mealColor,
                                gradient: ClioTheme.mealGradient
                            ) {
                                showNourishmentLog = true
                            }
                            .staggeredAppearance(index: 2, delay: 0.1)
                        }

                        // Gentle reminder
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Remember")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(ClioTheme.textMuted)
                                .textCase(.uppercase)
                                .tracking(1.2)

                            Text("There's no wrong way to check in. Even noticing that you don't want to log is awareness.")
                                .font(.subheadline)
                                .foregroundStyle(ClioTheme.textMuted)
                                .lineSpacing(4)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(ClioTheme.surface.opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .fadeInFromBottom(delay: 0.4)
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
}

struct LogOptionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let gradient: LinearGradient
    let action: () -> Void

    var body: some View {
        Button(action: {
            HapticFeedback.medium.trigger()
            action()
        }) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 56, height: 56)

                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundStyle(color)
                }

                // Text
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(ClioTheme.text)

                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(ClioTheme.textMuted)
                }

                Spacer()

                // Arrow
                Image(systemName: "chevron.right")
                    .font(.body)
                    .foregroundStyle(color.opacity(0.6))
            }
            .padding()
            .background(ClioTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(color.opacity(0.15), lineWidth: 1)
            )
        }
        .buttonStyle(LogOptionCardStyle(color: color))
    }
}

struct LogOptionCardStyle: ButtonStyle {
    let color: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(color.opacity(configuration.isPressed ? 0.4 : 0), lineWidth: 2)
            )
            .animation(.clioQuick, value: configuration.isPressed)
    }
}

#Preview {
    LogView()
        .modelContainer(for: [DailyCheckIn.self, MovementEntry.self, MealEntry.self], inMemory: true)
}
