import SwiftUI
import SwiftData

@main
struct ClioApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some Scene {
        WindowGroup {
            Group {
                if hasCompletedOnboarding {
                    MainTabView()
                } else {
                    OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
                }
            }
            .preferredColorScheme(.light)
        }
        .modelContainer(for: [
            UserSettings.self,
            MovementEntry.self,
            MealEntry.self,
            FeelCheck.self,
            PersonalInsight.self,
            SavedMeal.self
        ])
    }
}

struct MainTabView: View {
    @State private var selectedTab: Tab = .home

    enum Tab: String, CaseIterable {
        case home = "Home"
        case eat = "Eat"
        case move = "Move"
        case insights = "Insights"
        case settings = "Settings"

        var icon: String {
            switch self {
            case .home: return "house"
            case .eat: return "leaf"
            case .move: return "figure.walk"
            case .insights: return "sparkles"
            case .settings: return "gearshape"
            }
        }

        var selectedIcon: String {
            switch self {
            case .home: return "house.fill"
            case .eat: return "leaf.fill"
            case .move: return "figure.walk"
            case .insights: return "sparkles"
            case .settings: return "gearshape.fill"
            }
        }

        var color: Color {
            switch self {
            case .home: return ClioTheme.primary       // Sage green
            case .eat: return ClioTheme.eatColor       // Terracotta
            case .move: return ClioTheme.moveColor     // Teal
            case .insights: return ClioTheme.insightColor // Blue
            case .settings: return ClioTheme.textMuted
            }
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Content
            Group {
                switch selectedTab {
                case .home: HomeView()
                case .eat: EatView()
                case .move: MoveView()
                case .insights: InsightsView()
                case .settings: SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Custom Tab Bar
            AnimatedTabBar(selectedTab: $selectedTab)
        }
        .ignoresSafeArea(.keyboard)
        .preferredColorScheme(.light)
    }
}

// MARK: - Tab Bar
struct AnimatedTabBar: View {
    @Binding var selectedTab: MainTabView.Tab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(MainTabView.Tab.allCases, id: \.self) { tab in
                tabButton(for: tab)
            }
        }
        .padding(.top, 12)
        .padding(.bottom, 28)
        .background(
            Rectangle()
                .fill(ClioTheme.surface)
                .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: -4)
                .ignoresSafeArea()
        )
    }

    private func tabButton(for tab: MainTabView.Tab) -> some View {
        Button {
            if selectedTab != tab {
                selectedTab = tab
                let impactMed = UIImpactFeedbackGenerator(style: .light)
                impactMed.impactOccurred()
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: selectedTab == tab ? tab.selectedIcon : tab.icon)
                    .font(.system(size: 22))
                    .frame(height: 24)

                Text(tab.rawValue)
                    .font(.caption2)
            }
            .foregroundStyle(selectedTab == tab ? tab.color : ClioTheme.textMuted)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [
            UserSettings.self,
            MovementEntry.self,
            MealEntry.self,
            FeelCheck.self,
            PersonalInsight.self,
            SavedMeal.self
        ], inMemory: true)
}
