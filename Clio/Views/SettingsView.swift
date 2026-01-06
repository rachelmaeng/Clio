import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \UserSettings.createdAt, order: .reverse) private var userSettings: [UserSettings]
    @Query(sort: \MealEntry.dateTime, order: .reverse) private var meals: [MealEntry]
    @Query(sort: \MovementEntry.dateTime, order: .reverse) private var movements: [MovementEntry]
    @Query(sort: \FeelCheck.dateTime, order: .reverse) private var feelChecks: [FeelCheck]

    @State private var showCycleSettings = false
    @State private var showCalorieSettings = false
    @State private var showAllergenSettings = false
    @State private var showFertilitySettings = false
    @State private var showExportSheet = false
    @State private var showClearConfirmation = false
    @State private var exportURL: URL?

    private var settings: UserSettings? {
        userSettings.first
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ClioTheme.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Header
                        header
                            .fadeInFromBottom(delay: 0)

                        // Cycle Settings
                        cycleSection
                            .fadeInFromBottom(delay: 0.1)

                        // Nutrition Settings
                        nutritionSection
                            .fadeInFromBottom(delay: 0.2)

                        // Tracking Preferences
                        trackingSection
                            .fadeInFromBottom(delay: 0.3)

                        // Data section
                        dataSection
                            .fadeInFromBottom(delay: 0.4)

                        // About section
                        aboutSection
                            .fadeInFromBottom(delay: 0.5)

                        // Philosophy note
                        philosophyNote
                            .fadeInFromBottom(delay: 0.6)
                    }
                    .padding()
                    .padding(.bottom, 100)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                ensureSettingsExist()
            }
            .sheet(isPresented: $showCycleSettings) {
                CycleSettingsSheet()
            }
            .sheet(isPresented: $showCalorieSettings) {
                CalorieGoalSheet()
            }
            .sheet(isPresented: $showAllergenSettings) {
                AllergenSettingsSheet()
            }
            .sheet(isPresented: $showFertilitySettings) {
                FertilityGoalSheet()
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

    // MARK: - Header
    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Settings")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundStyle(ClioTheme.text)

            Text("Personalize your experience")
                .font(.subheadline)
                .foregroundStyle(ClioTheme.textMuted)
        }
    }

    // MARK: - Cycle Section
    private var cycleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Cycle")
                .font(.headline)
                .foregroundStyle(ClioTheme.text)

            VStack(spacing: 0) {
                Button {
                    showCycleSettings = true
                } label: {
                    HStack(spacing: 16) {
                        Image(systemName: "calendar")
                            .font(.body)
                            .foregroundStyle(ClioTheme.primary)
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Cycle settings")
                                .font(.body)
                                .foregroundStyle(ClioTheme.text)

                            if let phase = settings?.currentPhase, let day = settings?.dayOfCycle {
                                Text("\(phase.description) · Day \(day)")
                                    .font(.caption)
                                    .foregroundStyle(ClioTheme.textMuted)
                            } else {
                                Text("Set your cycle to get phase-aware tips")
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

                Divider()
                    .background(Color.white.opacity(0.05))

                // Fertility Goal (subtle, optional)
                Button {
                    showFertilitySettings = true
                } label: {
                    HStack(spacing: 16) {
                        Image(systemName: "leaf.circle")
                            .font(.body)
                            .foregroundStyle(ClioTheme.primary.opacity(0.8))
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Fertility awareness")
                                .font(.body)
                                .foregroundStyle(ClioTheme.text)

                            if let goalStr = settings?.fertilityGoal,
                               let goal = UserSettings.FertilityGoal(rawValue: goalStr),
                               goal != .none {
                                Text(goal.displayName)
                                    .font(.caption)
                                    .foregroundStyle(ClioTheme.textMuted)
                            } else {
                                Text("Optional")
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
            }
            .background(ClioTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    // MARK: - Nutrition Section
    private var nutritionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Nutrition")
                .font(.headline)
                .foregroundStyle(ClioTheme.text)

            VStack(spacing: 0) {
                // Calorie Goal
                Button {
                    showCalorieSettings = true
                } label: {
                    HStack(spacing: 16) {
                        Image(systemName: "flame")
                            .font(.body)
                            .foregroundStyle(ClioTheme.eatColor)
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Calorie goals")
                                .font(.body)
                                .foregroundStyle(ClioTheme.text)

                            if settings?.hasCalorieGoal == true, let range = settings?.calorieRangeText {
                                Text(range)
                                    .font(.caption)
                                    .foregroundStyle(ClioTheme.textMuted)
                            } else {
                                Text("Optional - set a target range")
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

                Divider()
                    .background(Color.white.opacity(0.05))

                // Allergens
                Button {
                    showAllergenSettings = true
                } label: {
                    HStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.body)
                            .foregroundStyle(ClioTheme.terracotta)
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Allergens & sensitivities")
                                .font(.body)
                                .foregroundStyle(ClioTheme.text)

                            if let allergens = settings?.allergens, !allergens.isEmpty {
                                Text(allergens.joined(separator: ", "))
                                    .font(.caption)
                                    .foregroundStyle(ClioTheme.textMuted)
                                    .lineLimit(1)
                            } else {
                                Text("None set")
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
            }
            .background(ClioTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    // MARK: - Tracking Section
    private var trackingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tracking")
                .font(.headline)
                .foregroundStyle(ClioTheme.text)

            VStack(spacing: 0) {
                SettingsToggleRow(
                    icon: "flame",
                    title: "Show calories",
                    subtitle: "Display calorie details in meal logs",
                    isOn: Binding(
                        get: { settings?.showCalories ?? true },
                        set: { updateSetting(\.showCalories, value: $0) }
                    )
                )

                Divider()
                    .background(Color.white.opacity(0.05))

                SettingsToggleRow(
                    icon: "bolt",
                    title: "Calorie burn estimates",
                    subtitle: "Show estimated calories burned for workouts",
                    isOn: Binding(
                        get: { settings?.showCalorieBurnEstimate ?? true },
                        set: { updateSetting(\.showCalorieBurnEstimate, value: $0) }
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
    }

    // MARK: - Data Section
    private var dataSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Data")
                .font(.headline)
                .foregroundStyle(ClioTheme.text)

            // Data summary
            HStack(spacing: 12) {
                DataCountBadge(count: feelChecks.count, label: "Check-ins", icon: "heart.fill", color: ClioTheme.feelColor)
                DataCountBadge(count: movements.count, label: "Workouts", icon: "figure.run", color: ClioTheme.moveColor)
                DataCountBadge(count: meals.count, label: "Meals", icon: "fork.knife", color: ClioTheme.eatColor)
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
                    showClearConfirmation = true
                }
            }
            .background(ClioTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    // MARK: - About Section
    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 12) {
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
    }

    // MARK: - Philosophy Note
    private var philosophyNote: some View {
        VStack(spacing: 12) {
            Text("Clio Philosophy")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(ClioTheme.textMuted)
                .textCase(.uppercase)
                .tracking(1.2)

            Text("Clio helps you discover what works for your body. Your data stays on your device. No streaks, no competition - just you, learning about yourself.")
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

    // MARK: - Helper Methods

    private func ensureSettingsExist() {
        if userSettings.isEmpty {
            let newSettings = UserSettings()
            modelContext.insert(newSettings)
            try? modelContext.save()
        }
    }

    private func exportData() {
        let exporter = DataExporter(modelContext: modelContext)
        do {
            exportURL = try exporter.getExportURL()
            showExportSheet = true
        } catch {
            print("Export failed: \(error)")
        }
    }

    private func clearAllData() {
        let exporter = DataExporter(modelContext: modelContext)
        do {
            try exporter.clearAllData()
        } catch {
            print("Clear failed: \(error)")
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

// MARK: - Cycle Settings Sheet
struct CycleSettingsSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \UserSettings.createdAt, order: .reverse) private var userSettings: [UserSettings]

    @State private var lastPeriodStart: Date = Date()
    @State private var cycleLength: Double = 28
    @State private var periodLength: Double = 5

    private var settings: UserSettings? {
        userSettings.first
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ClioTheme.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Last Period
                        VStack(alignment: .leading, spacing: 12) {
                            Text("When did your last period start?")
                                .font(.headline)
                                .foregroundStyle(ClioTheme.text)

                            DatePicker(
                                "Last period",
                                selection: $lastPeriodStart,
                                in: ...Date(),
                                displayedComponents: .date
                            )
                            .datePickerStyle(.graphical)
                            .tint(ClioTheme.primary)
                            .environment(\.colorScheme, .light)
                            .padding()
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }

                        // Cycle Length
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Cycle length")
                                    .font(.headline)
                                    .foregroundStyle(ClioTheme.text)

                                Spacer()

                                Text("\(Int(cycleLength)) days")
                                    .font(.headline)
                                    .foregroundStyle(ClioTheme.primary)
                            }

                            Slider(value: $cycleLength, in: 21...35, step: 1)
                                .tint(ClioTheme.primary)

                            Text("Most cycles are 21-35 days")
                                .font(.caption)
                                .foregroundStyle(ClioTheme.textMuted)
                        }
                        .padding()
                        .background(ClioTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                        // Period Length
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Period length")
                                    .font(.headline)
                                    .foregroundStyle(ClioTheme.text)

                                Spacer()

                                Text("\(Int(periodLength)) days")
                                    .font(.headline)
                                    .foregroundStyle(ClioTheme.primary)
                            }

                            Slider(value: $periodLength, in: 2...10, step: 1)
                                .tint(ClioTheme.primary)

                            Text("Average is 3-7 days")
                                .font(.caption)
                                .foregroundStyle(ClioTheme.textMuted)
                        }
                        .padding()
                        .background(ClioTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .padding()
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle("Cycle Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(ClioTheme.textMuted)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveCycleSettings()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(ClioTheme.primary)
                }
            }
            .onAppear {
                if let s = settings {
                    lastPeriodStart = s.lastPeriodStart ?? Date()
                    cycleLength = Double(s.cycleLength)
                    periodLength = Double(s.periodLength)
                }
            }
        }
    }

    private func saveCycleSettings() {
        if let s = settings {
            s.lastPeriodStart = lastPeriodStart
            s.cycleLength = Int(cycleLength)
            s.periodLength = Int(periodLength)
            s.updatedAt = Date()
            try? modelContext.save()
        }
        dismiss()
    }
}

// MARK: - Calorie Goal Sheet
struct CalorieGoalSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \UserSettings.createdAt, order: .reverse) private var userSettings: [UserSettings]

    @State private var hasGoal: Bool = false
    @State private var selectedGoal: UserSettings.GoalType = .getLeaner
    @State private var calorieRangeLow: String = "1600"
    @State private var calorieRangeHigh: String = "2000"

    private var settings: UserSettings? {
        userSettings.first
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ClioTheme.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Toggle
                        VStack(alignment: .leading, spacing: 12) {
                            SettingsToggleRow(
                                icon: "target",
                                title: "Track calorie goals",
                                subtitle: "Set a daily calorie range",
                                isOn: $hasGoal
                            )
                        }
                        .background(ClioTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                        if hasGoal {
                            // Goal Type
                            VStack(alignment: .leading, spacing: 12) {
                                Text("What's your goal?")
                                    .font(.headline)
                                    .foregroundStyle(ClioTheme.text)

                                VStack(spacing: 8) {
                                    ForEach(UserSettings.GoalType.allCases) { goal in
                                        Button {
                                            withAnimation {
                                                selectedGoal = goal
                                                let range = goal.suggestedRange
                                                calorieRangeLow = "\(range.low)"
                                                calorieRangeHigh = "\(range.high)"
                                            }
                                        } label: {
                                            HStack {
                                                Image(systemName: goal.icon)
                                                    .foregroundStyle(selectedGoal == goal ? ClioTheme.primary : ClioTheme.textMuted)

                                                Text(goal.displayName)
                                                    .foregroundStyle(selectedGoal == goal ? ClioTheme.text : ClioTheme.textMuted)

                                                Spacer()

                                                if selectedGoal == goal {
                                                    Image(systemName: "checkmark")
                                                        .foregroundStyle(ClioTheme.primary)
                                                }
                                            }
                                            .padding()
                                            .background(selectedGoal == goal ? ClioTheme.primary.opacity(0.1) : Color.clear)
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                            .padding()
                            .background(ClioTheme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 16))

                            // Calorie Range
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Daily calorie range")
                                    .font(.headline)
                                    .foregroundStyle(ClioTheme.text)

                                HStack(spacing: 16) {
                                    VStack(spacing: 4) {
                                        TextField("Min", text: $calorieRangeLow)
                                            .keyboardType(.numberPad)
                                            .font(.title2)
                                            .fontWeight(.bold)
                                            .multilineTextAlignment(.center)
                                            .foregroundStyle(ClioTheme.text)

                                        Text("minimum")
                                            .font(.caption)
                                            .foregroundStyle(ClioTheme.textMuted)
                                    }
                                    .padding()
                                    .background(ClioTheme.surfaceHighlight)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))

                                    Text("-")
                                        .foregroundStyle(ClioTheme.textMuted)

                                    VStack(spacing: 4) {
                                        TextField("Max", text: $calorieRangeHigh)
                                            .keyboardType(.numberPad)
                                            .font(.title2)
                                            .fontWeight(.bold)
                                            .multilineTextAlignment(.center)
                                            .foregroundStyle(ClioTheme.text)

                                        Text("maximum")
                                            .font(.caption)
                                            .foregroundStyle(ClioTheme.textMuted)
                                    }
                                    .padding()
                                    .background(ClioTheme.surfaceHighlight)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }

                                Text("This is just a guide - listen to your body")
                                    .font(.caption)
                                    .foregroundStyle(ClioTheme.textMuted)
                            }
                            .padding()
                            .background(ClioTheme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                    }
                    .padding()
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle("Calorie Goals")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(ClioTheme.textMuted)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveCalorieSettings()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(ClioTheme.primary)
                }
            }
            .onAppear {
                if let s = settings {
                    hasGoal = s.hasCalorieGoal
                    if let type = s.calorieGoalType, let goal = UserSettings.GoalType(rawValue: type) {
                        selectedGoal = goal
                    }
                    if let low = s.calorieRangeLow {
                        calorieRangeLow = "\(low)"
                    }
                    if let high = s.calorieRangeHigh {
                        calorieRangeHigh = "\(high)"
                    }
                }
            }
        }
    }

    private func saveCalorieSettings() {
        if let s = settings {
            s.hasCalorieGoal = hasGoal
            s.calorieGoalType = hasGoal ? selectedGoal.rawValue : nil
            s.calorieRangeLow = hasGoal ? Int(calorieRangeLow) : nil
            s.calorieRangeHigh = hasGoal ? Int(calorieRangeHigh) : nil
            s.updatedAt = Date()
            try? modelContext.save()
        }
        dismiss()
    }
}

// MARK: - Allergen Settings Sheet
struct AllergenSettingsSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \UserSettings.createdAt, order: .reverse) private var userSettings: [UserSettings]

    @State private var selectedAllergens: Set<String> = []
    @State private var customAllergen: String = ""

    private var settings: UserSettings? {
        userSettings.first
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ClioTheme.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        Text("Foods marked with your allergens won't be suggested in phase tips.")
                            .font(.subheadline)
                            .foregroundStyle(ClioTheme.textMuted)

                        // Common allergens
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Common allergens")
                                .font(.headline)
                                .foregroundStyle(ClioTheme.text)

                            FlowLayout(spacing: 8) {
                                ForEach(UserSettings.commonAllergens, id: \.self) { allergen in
                                    Button {
                                        withAnimation {
                                            if selectedAllergens.contains(allergen) {
                                                selectedAllergens.remove(allergen)
                                            } else {
                                                selectedAllergens.insert(allergen)
                                            }
                                        }
                                    } label: {
                                        Text(allergen)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 10)
                                            .background(selectedAllergens.contains(allergen) ? ClioTheme.terracotta.opacity(0.15) : ClioTheme.surface)
                                            .foregroundStyle(selectedAllergens.contains(allergen) ? ClioTheme.terracotta : ClioTheme.textMuted)
                                            .clipShape(Capsule())
                                            .overlay(
                                                Capsule()
                                                    .stroke(selectedAllergens.contains(allergen) ? ClioTheme.terracotta.opacity(0.3) : Color.clear, lineWidth: 1)
                                            )
                                    }
                                    .buttonStyle(TipChipButtonStyle())
                                }
                            }
                        }

                        // Custom allergen
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Add custom")
                                .font(.headline)
                                .foregroundStyle(ClioTheme.text)

                            HStack {
                                TextField("Other sensitivity...", text: $customAllergen)
                                    .foregroundStyle(ClioTheme.text)

                                if !customAllergen.isEmpty {
                                    Button {
                                        addCustomAllergen()
                                    } label: {
                                        Image(systemName: "plus.circle.fill")
                                            .foregroundStyle(ClioTheme.primary)
                                    }
                                }
                            }
                            .padding()
                            .background(ClioTheme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        // Selected allergens
                        if !selectedAllergens.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Your sensitivities")
                                    .font(.headline)
                                    .foregroundStyle(ClioTheme.text)

                                FlowLayout(spacing: 8) {
                                    ForEach(Array(selectedAllergens).sorted(), id: \.self) { allergen in
                                        AllergenChipView(
                                            allergen: allergen,
                                            onRemove: {
                                                selectedAllergens.remove(allergen)
                                            }
                                        )
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle("Allergens")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(ClioTheme.textMuted)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveAllergenSettings()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(ClioTheme.primary)
                }
            }
            .onAppear {
                if let s = settings {
                    selectedAllergens = Set(s.allergens)
                }
            }
        }
    }

    private func addCustomAllergen() {
        let allergen = customAllergen.trimmingCharacters(in: .whitespacesAndNewlines)
        if !allergen.isEmpty {
            selectedAllergens.insert(allergen)
            customAllergen = ""
        }
    }

    private func saveAllergenSettings() {
        if let s = settings {
            s.allergens = Array(selectedAllergens).sorted()
            s.updatedAt = Date()
            try? modelContext.save()
        }
        dismiss()
    }
}

// MARK: - Fertility Goal Sheet
struct FertilityGoalSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \UserSettings.createdAt, order: .reverse) private var userSettings: [UserSettings]

    @State private var selectedGoal: UserSettings.FertilityGoal = .none

    private var settings: UserSettings? {
        userSettings.first
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ClioTheme.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Explanation
                        VStack(alignment: .leading, spacing: 8) {
                            Text("This is completely optional")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(ClioTheme.text)

                            Text("Sharing your fertility goal helps Clio provide more relevant insights about your fertile window and cycle patterns. This information stays private on your device.")
                                .font(.caption)
                                .foregroundStyle(ClioTheme.textMuted)
                                .lineSpacing(4)
                        }
                        .padding()
                        .background(ClioTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                        // Goal Options
                        VStack(alignment: .leading, spacing: 12) {
                            Text("What describes you best?")
                                .font(.headline)
                                .foregroundStyle(ClioTheme.text)

                            VStack(spacing: 8) {
                                ForEach(UserSettings.FertilityGoal.allCases) { goal in
                                    Button {
                                        withAnimation(.clioQuick) {
                                            selectedGoal = goal
                                        }
                                    } label: {
                                        HStack(spacing: 14) {
                                            Image(systemName: goal.icon)
                                                .font(.body)
                                                .foregroundStyle(selectedGoal == goal ? ClioTheme.primary : ClioTheme.textMuted)
                                                .frame(width: 24)

                                            Text(goal.displayName)
                                                .font(.body)
                                                .foregroundStyle(selectedGoal == goal ? ClioTheme.text : ClioTheme.textMuted)

                                            Spacer()

                                            if selectedGoal == goal {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundStyle(ClioTheme.primary)
                                            } else {
                                                Image(systemName: "circle")
                                                    .foregroundStyle(ClioTheme.textMuted.opacity(0.5))
                                            }
                                        }
                                        .padding()
                                        .background(selectedGoal == goal ? ClioTheme.primary.opacity(0.1) : ClioTheme.surface)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(selectedGoal == goal ? ClioTheme.primary.opacity(0.3) : Color.clear, lineWidth: 1)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        // Privacy note
                        HStack(spacing: 8) {
                            Image(systemName: "lock.fill")
                                .font(.caption)
                                .foregroundStyle(ClioTheme.textMuted)

                            Text("This information is stored only on your device and never shared.")
                                .font(.caption)
                                .foregroundStyle(ClioTheme.textMuted)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(ClioTheme.surface.opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding()
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle("Fertility Awareness")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(ClioTheme.textMuted)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveFertilityGoal()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(ClioTheme.primary)
                }
            }
            .onAppear {
                if let s = settings,
                   let goalStr = s.fertilityGoal,
                   let goal = UserSettings.FertilityGoal(rawValue: goalStr) {
                    selectedGoal = goal
                }
            }
        }
    }

    private func saveFertilityGoal() {
        if let s = settings {
            s.fertilityGoal = selectedGoal.rawValue
            s.updatedAt = Date()
            try? modelContext.save()
        }
        dismiss()
    }
}

// MARK: - Supporting Views

struct DataCountBadge: View {
    let count: Int
    let label: String
    let icon: String
    var color: Color = ClioTheme.primary

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color)

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

struct AllergenChipView: View {
    let allergen: String
    let onRemove: () -> Void

    private let chipBackground: Color = ClioTheme.eatColor.opacity(0.15)

    var body: some View {
        HStack(spacing: 6) {
            Text(allergen)
                .font(.subheadline)
                .foregroundStyle(ClioTheme.text)

            Button {
                withAnimation {
                    onRemove()
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(ClioTheme.textMuted)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(chipBackground)
        .clipShape(Capsule())
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
        .modelContainer(for: [UserSettings.self, MealEntry.self, MovementEntry.self, FeelCheck.self], inMemory: true)
}
