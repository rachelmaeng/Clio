import SwiftUI
import SwiftData

@main
struct ClioApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    init() {
        // Configure navigation bar appearance to prevent white flash
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .clear
        appearance.shadowColor = .clear
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
    }

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
            return ClioTheme.terracotta  // All tabs use terracotta when active
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Base background that covers everything
            ClioTheme.background
                .ignoresSafeArea()

            // Content - all views pre-rendered to prevent flash
            ZStack {
                HomeView(selectedTab: $selectedTab)
                    .opacity(selectedTab == .home ? 1 : 0)
                    .allowsHitTesting(selectedTab == .home)

                EatView()
                    .opacity(selectedTab == .eat ? 1 : 0)
                    .allowsHitTesting(selectedTab == .eat)

                MoveView()
                    .opacity(selectedTab == .move ? 1 : 0)
                    .allowsHitTesting(selectedTab == .move)

                InsightsView()
                    .opacity(selectedTab == .insights ? 1 : 0)
                    .allowsHitTesting(selectedTab == .insights)

                SettingsView()
                    .opacity(selectedTab == .settings ? 1 : 0)
                    .allowsHitTesting(selectedTab == .settings)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(ClioTheme.background.ignoresSafeArea())
            .transaction { transaction in
                transaction.animation = nil
            }

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
                .shadow(color: Color(hex: "3D3532").opacity(0.06), radius: 12, x: 0, y: -4)
                .ignoresSafeArea()
        )
    }

    private func tabButton(for tab: MainTabView.Tab) -> some View {
        let isActive = selectedTab == tab
        return Button {
            if !isActive {
                selectedTab = tab
                let impactMed = UIImpactFeedbackGenerator(style: .light)
                impactMed.impactOccurred()
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: isActive ? tab.selectedIcon : tab.icon)
                    .font(.system(size: 22, weight: isActive ? .semibold : .regular))
                    .frame(height: 24)

                Text(tab.rawValue)
                    .font(.caption2)
                    .fontWeight(isActive ? .semibold : .regular)
            }
            .foregroundStyle(isActive ? tab.color : ClioTheme.textLight)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(tab.rawValue) tab")
        .accessibilityAddTraits(isActive ? .isSelected : [])
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
