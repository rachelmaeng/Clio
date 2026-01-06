import SwiftUI
import SwiftData

struct FeelCheckView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \UserSettings.createdAt, order: .reverse) private var settings: [UserSettings]

    // Optional date for logging past days
    var forDate: Date?

    @State private var energyLevel: Double = 5
    @State private var selectedMoods: Set<FeelCheck.Mood> = []
    @State private var selectedSensations: Set<FeelCheck.BodySensation> = []
    @State private var notes: String = ""

    private var userSettings: UserSettings? {
        settings.first
    }

    private var targetDate: Date {
        forDate ?? Date()
    }

    private var isLoggingPastDay: Bool {
        forDate != nil && !Calendar.current.isDateInToday(forDate!)
    }

    private var phaseForTargetDate: CyclePhase {
        guard let lastPeriod = userSettings?.lastPeriodStart else { return .follicular }
        return CyclePhaseEngine.phaseForDate(targetDate, lastPeriodStart: lastPeriod, cycleLength: userSettings?.cycleLength ?? 28)
    }

    private var dayOfCycleForTargetDate: Int {
        guard let lastPeriod = userSettings?.lastPeriodStart else { return 1 }
        return CyclePhaseEngine.dayInCycle(from: lastPeriod, to: targetDate, cycleLength: userSettings?.cycleLength ?? 28)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ClioTheme.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 32) {
                        // Header
                        header
                            .fadeInFromBottom(delay: 0)

                        // Energy Slider
                        energySection
                            .fadeInFromBottom(delay: 0.1)

                        // Mood Selection
                        moodSection
                            .fadeInFromBottom(delay: 0.2)

                        // Body Sensations
                        sensationsSection
                            .fadeInFromBottom(delay: 0.3)

                        // Notes
                        notesSection
                            .fadeInFromBottom(delay: 0.4)
                    }
                    .padding()
                    .padding(.bottom, 160)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    ClioCloseButton { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                saveButton
            }
        }
    }

    // MARK: - Header
    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(isLoggingPastDay ? "How did you feel?" : "How do you feel?")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundStyle(ClioTheme.text)

            if isLoggingPastDay {
                Text(pastDateFormatter.string(from: targetDate))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(ClioTheme.primary)
            }

            HStack(spacing: 6) {
                Circle()
                    .fill(ClioTheme.phaseColor(for: phaseForTargetDate))
                    .frame(width: 8, height: 8)

                Text(phaseForTargetDate.description)
                    .font(.subheadline)
                    .foregroundStyle(ClioTheme.textMuted)

                Text("· Day \(dayOfCycleForTargetDate)")
                    .font(.subheadline)
                    .foregroundStyle(ClioTheme.textMuted)
            }
        }
    }

    private var pastDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter
    }

    // MARK: - Energy Section
    private var energySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Energy")
                    .font(.headline)
                    .foregroundStyle(ClioTheme.text)

                Spacer()

                Text(energyLabel)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(energyColor)
            }

            VStack(spacing: 12) {
                Slider(value: $energyLevel, in: 1...10, step: 1)
                    .tint(energyColor)

                // Labels
                HStack {
                    Text("Depleted")
                        .font(.caption)
                        .foregroundStyle(ClioTheme.textMuted)
                    Spacer()
                    Text("Vibrant")
                        .font(.caption)
                        .foregroundStyle(ClioTheme.textMuted)
                }
            }
            .padding()
            .background(ClioTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    private var energyLabel: String {
        switch Int(energyLevel) {
        case 1...3: return "Low"
        case 4...6: return "Moderate"
        case 7...10: return "High"
        default: return "Moderate"
        }
    }

    private var energyColor: Color {
        switch Int(energyLevel) {
        case 1...3: return ClioTheme.honey
        case 4...6: return ClioTheme.terracotta
        case 7...10: return ClioTheme.success
        default: return ClioTheme.terracotta
        }
    }

    // MARK: - Mood Section (Primary - more prominent)
    private var moodSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "heart.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(ClioTheme.feelColor)
                Text("How's your mood?")
                    .font(ClioTheme.subheadingFont(18))
                    .foregroundStyle(ClioTheme.text)
            }

            // Use 3 columns for better balance (11 items = 3+3+3+2)
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 10),
                GridItem(.flexible(), spacing: 10),
                GridItem(.flexible(), spacing: 10)
            ], spacing: 10) {
                ForEach(FeelCheck.Mood.allCases) { mood in
                    MoodTile(
                        mood: mood,
                        isSelected: selectedMoods.contains(mood)
                    ) {
                        toggleMood(mood)
                    }
                }
            }
        }
        .padding(ClioTheme.spacing)
        .background(ClioTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: ClioTheme.cornerRadius, style: .continuous))
    }

    private func toggleMood(_ mood: FeelCheck.Mood) {
        withAnimation(.clioQuick) {
            if selectedMoods.contains(mood) {
                selectedMoods.remove(mood)
            } else {
                selectedMoods.insert(mood)
            }
        }
    }

    // MARK: - Sensations Section (Same grid style as Mood)
    private var sensationsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "figure.stand")
                    .font(.system(size: 16))
                    .foregroundStyle(ClioTheme.textMuted)
                Text("How does your body feel?")
                    .font(ClioTheme.captionFont(14))
                    .foregroundStyle(ClioTheme.textMuted)
            }

            // Same 3-column grid as Mood for consistency
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 10),
                GridItem(.flexible(), spacing: 10),
                GridItem(.flexible(), spacing: 10)
            ], spacing: 10) {
                ForEach(FeelCheck.BodySensation.allCases) { sensation in
                    BodyTile(
                        sensation: sensation,
                        isSelected: selectedSensations.contains(sensation)
                    ) {
                        toggleSensation(sensation)
                    }
                }
            }
        }
        .padding(ClioTheme.spacing)
        .background(ClioTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: ClioTheme.cornerRadius, style: .continuous))
    }

    private func toggleSensation(_ sensation: FeelCheck.BodySensation) {
        withAnimation(.clioQuick) {
            if selectedSensations.contains(sensation) {
                selectedSensations.remove(sensation)
            } else {
                selectedSensations.insert(sensation)
            }
        }
    }

    // MARK: - Notes Section
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Text("Notes")
                    .font(ClioTheme.captionFont(14))
                    .foregroundStyle(ClioTheme.textMuted)
                Text("optional")
                    .font(ClioTheme.captionFont(11))
                    .foregroundStyle(ClioTheme.textLight)
            }

            TextField("Anything else on your mind?", text: $notes, axis: .vertical)
                .font(ClioTheme.bodyFont())
                .lineLimit(3...6)
                .padding()
                .background(ClioTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(ClioTheme.surfaceHighlight, lineWidth: 1)
                )
                .foregroundStyle(ClioTheme.text)
        }
    }

    // MARK: - Save Button
    private var saveButton: some View {
        Button {
            saveFeelCheck()
        } label: {
            Text("Save check-in")
        }
        .buttonStyle(ClioPrimaryButtonStyle())
        .padding()
        .background(
            LinearGradient(
                colors: [ClioTheme.background.opacity(0), ClioTheme.background],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private func saveFeelCheck() {
        let feelCheck = FeelCheck(
            energyLevel: Int(energyLevel),
            moods: selectedMoods.map { $0.rawValue },
            bodySensations: selectedSensations.map { $0.rawValue },
            notes: notes.isEmpty ? nil : notes
        )

        // Use target date for past day logging
        feelCheck.dateTime = targetDate
        feelCheck.setCycleContext(phase: phaseForTargetDate, day: dayOfCycleForTargetDate)

        modelContext.insert(feelCheck)
        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Mood Tile (Grid style)
struct MoodTile: View {
    let mood: FeelCheck.Mood
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: mood.icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(isSelected ? .white : ClioTheme.textMuted)

                Text(mood.rawValue)
                    .font(ClioTheme.captionFont(11))
                    .foregroundStyle(isSelected ? .white : ClioTheme.textMuted)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(isSelected ? tileColor : ClioTheme.surfaceHighlight)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var tileColor: Color {
        mood.isPositive ? ClioTheme.feelColor : ClioTheme.terracotta
    }
}

// MARK: - Body Tile (Same grid style as Mood)
struct BodyTile: View {
    let sensation: FeelCheck.BodySensation
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: sensation.icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(isSelected ? .white : ClioTheme.textMuted)

                Text(sensation.rawValue)
                    .font(ClioTheme.captionFont(11))
                    .foregroundStyle(isSelected ? .white : ClioTheme.textMuted)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? tileColor : ClioTheme.surfaceHighlight)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var tileColor: Color {
        sensation.isPositive ? ClioTheme.success : ClioTheme.terracotta
    }
}

#Preview {
    FeelCheckView()
        .modelContainer(for: [UserSettings.self, FeelCheck.self], inMemory: true)
}
