import SwiftUI
import SwiftData

@main
struct ClioApp: App {
    var body: some Scene {
        WindowGroup {
            MainTabView()
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
        case reflections = "Reflect"
        case settings = "Settings"

        var icon: String {
            switch self {
            case .home: return "house.fill"
            case .reflections: return "sparkles"
            case .settings: return "gearshape.fill"
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
