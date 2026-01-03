import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var userSettings: [UserSettings]

    @State private var showExportSheet = false
    @State private var showClearConfirmation = false
    @State private var exportURL: URL?
    @State private var dataCounts: (checkIns: Int, movements: Int, meals: Int) = (0, 0, 0)

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

                            // Data summary
                            if dataCounts.checkIns > 0 || dataCounts.movements > 0 || dataCounts.meals > 0 {
                                HStack(spacing: 16) {
                                    DataCountBadge(count: dataCounts.checkIns, label: "Check-ins", icon: "heart.fill")
                                    DataCountBadge(count: dataCounts.movements, label: "Movements", icon: "figure.walk")
                                    DataCountBadge(count: dataCounts.meals, label: "Meals", icon: "leaf.fill")
                                }
                                .padding(.bottom, 8)
                            }

                            VStack(spacing: 0) {
                                SettingsNavigationRow(
                                    icon: "square.and.arrow.up",
                                    title: "Export data",
                                    subtitle: "Download your logs as JSON"
                                ) {
                                    exportData()
                                }

                                Divider()
                                    .background(Color.white.opacity(0.05))

                                SettingsNavigationRow(
                                    icon: "trash",
                                    title: "Clear all data",
                                    subtitle: "Remove all logged entries",
                                    isDestructive: true
                                ) {
                                    HapticFeedback.warning.trigger()
                                    showClearConfirmation = true
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
                loadDataCounts()
            }
            .sheet(isPresented: $showExportSheet) {
                if let url = exportURL {
                    ShareSheet(items: [url])
                }
            }
            .alert("Clear All Data?", isPresented: $showClearConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Clear", role: .destructive) {
                    clearAllData()
                }
            } message: {
                Text("This will permanently remove all your check-ins, movements, and meals. This action cannot be undone.")
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

    private func loadDataCounts() {
        let exporter = DataExporter(modelContext: modelContext)
        dataCounts = exporter.getDataCounts()
    }

    private func exportData() {
        let exporter = DataExporter(modelContext: modelContext)
        do {
            exportURL = try exporter.getExportURL()
            HapticFeedback.success.trigger()
            showExportSheet = true
        } catch {
            print("Export failed: \(error)")
            HapticFeedback.error.trigger()
        }
    }

    private func clearAllData() {
        let exporter = DataExporter(modelContext: modelContext)
        do {
            try exporter.clearAllData()
            HapticFeedback.success.trigger()
            loadDataCounts()
        } catch {
            print("Clear failed: \(error)")
            HapticFeedback.error.trigger()
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

struct DataCountBadge: View {
    let count: Int
    let label: String
    let icon: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(ClioTheme.primary)

            Text("\(count)")
                .font(.headline)
                .foregroundStyle(ClioTheme.text)

            Text(label)
                .font(.caption2)
                .foregroundStyle(ClioTheme.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(ClioTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
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
