import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var userSettings: [UserSettings]

    private var settings: UserSettings? {
        userSettings.first
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ClioTheme.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 32) {
                        // Header
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Settings")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundStyle(ClioTheme.text)

                            Text("Personalize your experience")
                                .font(.subheadline)
                                .foregroundStyle(ClioTheme.textMuted)
                        }
                        .padding(.top, 8)

                        // Preferences section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Preferences")
                                .font(.headline)
                                .foregroundStyle(ClioTheme.text)

                            VStack(spacing: 0) {
                                SettingsToggleRow(
                                    icon: "flame",
                                    title: "Show calories",
                                    subtitle: "Display calorie details in meal logs",
                                    isOn: Binding(
                                        get: { settings?.showCalories ?? false },
                                        set: { updateSetting(\.showCalories, value: $0) }
                                    )
                                )

                                Divider()
                                    .background(Color.white.opacity(0.05))

                                SettingsToggleRow(
                                    icon: "bell",
                                    title: "Gentle reminders",
                                    subtitle: "Occasional prompts to check in",
                                    isOn: Binding(
                                        get: { settings?.notificationsEnabled ?? true },
                                        set: { updateSetting(\.notificationsEnabled, value: $0) }
                                    )
                                )
                            }
                            .background(ClioTheme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }

                        // Data section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Your Data")
                                .font(.headline)
                                .foregroundStyle(ClioTheme.text)

                            VStack(spacing: 0) {
                                SettingsNavigationRow(
                                    icon: "square.and.arrow.up",
                                    title: "Export data",
                                    subtitle: "Download your logs as JSON"
                                ) {
                                    // Export action
                                }

                                Divider()
                                    .background(Color.white.opacity(0.05))

                                SettingsNavigationRow(
                                    icon: "trash",
                                    title: "Clear all data",
                                    subtitle: "Remove all logged entries",
                                    isDestructive: true
                                ) {
                                    // Clear data action
                                }
                            }
                            .background(ClioTheme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }

                        // About section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("About")
                                .font(.headline)
                                .foregroundStyle(ClioTheme.text)

                            VStack(spacing: 0) {
                                SettingsInfoRow(
                                    icon: "info.circle",
                                    title: "Version",
                                    value: "1.0.0"
                                )

                                Divider()
                                    .background(Color.white.opacity(0.05))

                                SettingsNavigationRow(
                                    icon: "doc.text",
                                    title: "Privacy Policy",
                                    subtitle: nil
                                ) {
                                    // Privacy policy
                                }

                                Divider()
                                    .background(Color.white.opacity(0.05))

                                SettingsNavigationRow(
                                    icon: "questionmark.circle",
                                    title: "Help & Support",
                                    subtitle: nil
                                ) {
                                    // Help
                                }
                            }
                            .background(ClioTheme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }

                        // Philosophy note
                        VStack(spacing: 12) {
                            Text("Clio Philosophy")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(ClioTheme.textMuted)
                                .textCase(.uppercase)
                                .tracking(1.2)

                            Text("Clio believes in awareness without judgment. Your data stays on your device. There are no streaks, no goals, no competition. Just you, noticing.")
                                .font(.caption)
                                .foregroundStyle(ClioTheme.textMuted)
                                .lineSpacing(4)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(ClioTheme.surface.opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .padding()
                    .padding(.bottom, 100)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                ensureSettingsExist()
            }
        }
    }

    private func ensureSettingsExist() {
        if userSettings.isEmpty {
            let newSettings = UserSettings()
            modelContext.insert(newSettings)
            try? modelContext.save()
        }
    }

    private func updateSetting<T>(_ keyPath: WritableKeyPath<UserSettings, T>, value: T) {
        if let existingSettings = settings {
            var mutableSettings = existingSettings
            mutableSettings[keyPath: keyPath] = value
            try? modelContext.save()
        }
    }
}

struct SettingsToggleRow: View {
    let icon: String
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(ClioTheme.primary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .foregroundStyle(ClioTheme.text)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(ClioTheme.textMuted)
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(ClioTheme.primary)
        }
        .padding()
    }
}

struct SettingsNavigationRow: View {
    let icon: String
    let title: String
    let subtitle: String?
    var isDestructive: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundStyle(isDestructive ? Color.red.opacity(0.8) : ClioTheme.primary)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .foregroundStyle(isDestructive ? Color.red.opacity(0.8) : ClioTheme.text)

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(ClioTheme.textMuted)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(ClioTheme.textMuted)
            }
            .padding()
        }
        .buttonStyle(.plain)
    }
}

struct SettingsInfoRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(ClioTheme.primary)
                .frame(width: 24)

            Text(title)
                .font(.body)
                .foregroundStyle(ClioTheme.text)

            Spacer()

            Text(value)
                .font(.body)
                .foregroundStyle(ClioTheme.textMuted)
        }
        .padding()
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [UserSettings.self], inMemory: true)
}
