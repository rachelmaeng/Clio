import SwiftUI
import SwiftData

@main
struct ClioApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                MainTabView()
            } else {
                OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
            }
        }
        .modelContainer(for: [
            UserSettings.self,
            DailyCheckIn.self,
            MovementEntry.self,
            MealEntry.self
        ])
    }
}

struct MainTabView: View {
    @State private var selectedTab: Tab = .home

    enum Tab: String, CaseIterable {
        case home = "Home"
        case log = "Log"
        case reflections = "Reflect"
        case settings = "Settings"

        var icon: String {
            switch self {
            case .home: return "house.fill"
            case .log: return "plus.circle.fill"
            case .reflections: return "chart.line.uptrend.xyaxis"
            case .settings: return "gearshape.fill"
            }
        }

        var color: Color {
            switch self {
            case .home: return ClioTheme.primary
            case .log: return ClioTheme.primary
            case .reflections: return ClioTheme.primary
            case .settings: return ClioTheme.primary
            }
        }
    }

    var body: some View {
        ZStack {
            ClioTheme.background
                .ignoresSafeArea()

            TabView(selection: $selectedTab) {
                HomeView()
                    .tag(Tab.home)
                    .tabItem {
                        Label(Tab.home.rawValue, systemImage: Tab.home.icon)
                    }

                LogView()
                    .tag(Tab.log)
                    .tabItem {
                        Label(Tab.log.rawValue, systemImage: Tab.log.icon)
                    }

                ReflectionsView()
                    .tag(Tab.reflections)
                    .tabItem {
                        Label(Tab.reflections.rawValue, systemImage: Tab.reflections.icon)
                    }

                SettingsView()
                    .tag(Tab.settings)
                    .tabItem {
                        Label(Tab.settings.rawValue, systemImage: Tab.settings.icon)
                    }
            }
            .tint(ClioTheme.primary)
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [UserSettings.self, DailyCheckIn.self, MovementEntry.self, MealEntry.self], inMemory: true)
}
