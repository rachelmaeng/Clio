import SwiftUI
import SwiftData

struct FeelCheckView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \UserSettings.createdAt, order: .reverse) private var settings: [UserSettings]

    // Optional date for logging past days
    var forDate: Date?
    // Optional preselection from home screen feeling chips
    var preselectedState: String? = nil

    @State private var selectedPrimaryState: FeelCheck.PrimaryState? = nil
    @State private var selectedMoods: Set<FeelCheck.Mood> = []
    @State private var selectedSensations: Set<FeelCheck.BodySensation> = []
    @State private var notes: String = ""
    @State private var isMoodExpanded: Bool = false
    @State private var isSensationsExpanded: Bool = false
    @State private var isNotesExpanded: Bool = false

    // Simplified mood options (6 only)
    private let simplifiedMoods: [FeelCheck.Mood] = [.calm, .happy, .hopeful, .anxious, .irritable, .sad]

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

                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    header
                        .fadeInFromBottom(delay: 0)

                    // Primary State (Required - single selection)
                    primaryStateSection
                        .fadeInFromBottom(delay: 0.1)

                    // Collapsed Mood Section
                    moodSection
                        .fadeInFromBottom(delay: 0.2)

                    // Collapsed Body Sensations Section
                    sensationsSection
                        .fadeInFromBottom(delay: 0.3)

                    // Collapsed Notes Section
                    notesSection
                        .fadeInFromBottom(delay: 0.4)

                    Spacer()
                }
                .padding()
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
            .onAppear {
                if let preselected = preselectedState,
                   let match = FeelCheck.PrimaryState.allCases.first(where: { $0.rawValue == preselected }) {
                    selectedPrimaryState = match
                }
            }
        }
    }

    // MARK: - Header
    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("How are you feeling?")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(ClioTheme.text)

            Text(dateFormatter.string(from: targetDate))
                .font(.subheadline)
                .foregroundStyle(ClioTheme.textMuted)
        }
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = isLoggingPastDay ? "EEEE, MMMM d" : "EEEE, MMMM d"
        return formatter
    }

    // MARK: - Primary State Section (Required - single selection)
    private var primaryStateSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 3-column grid for primary states (plus extra row for 10th)
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8)
            ], spacing: 8) {
                ForEach(FeelCheck.PrimaryState.allCases) { state in
                    PrimaryStateChip(
                        state: state,
                        isSelected: selectedPrimaryState == state
                    ) {
                        selectPrimaryState(state)
                    }
                }
            }
        }
    }

    private func selectPrimaryState(_ state: FeelCheck.PrimaryState) {
        withAnimation(.clioQuick) {
            if selectedPrimaryState == state {
                selectedPrimaryState = nil
            } else {
                selectedPrimaryState = state
            }
        }
    }

    // MARK: - Body Sensations Section (Collapsible - optional)
    private var sensationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Expand/collapse button
            Button {
                withAnimation(.clioQuick) {
                    isSensationsExpanded.toggle()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: isSensationsExpanded ? "chevron.down" : "plus")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(ClioTheme.textMuted)

                    Text("Body sensations")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(ClioTheme.textMuted)

                    if !selectedSensations.isEmpty && !isSensationsExpanded {
                        Text("(\(selectedSensations.count) selected)")
                            .font(.caption)
                            .foregroundStyle(ClioTheme.feelColor)
                    }

                    Spacer()
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(ClioTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)

            // Expanded sensations options
            if isSensationsExpanded {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 8),
                    GridItem(.flexible(), spacing: 8),
                    GridItem(.flexible(), spacing: 8)
                ], spacing: 8) {
                    ForEach(FeelCheck.BodySensation.allCases) { sensation in
                        BodyStateChip(
                            sensation: sensation,
                            isSelected: selectedSensations.contains(sensation)
                        ) {
                            toggleSensation(sensation)
                        }
                    }
                }
                .padding(.top, 4)
            }
        }
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

    // MARK: - Mood Section (Collapsible)
    private var moodSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Expand/collapse button
            Button {
                withAnimation(.clioQuick) {
                    isMoodExpanded.toggle()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: isMoodExpanded ? "chevron.down" : "plus")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(ClioTheme.textMuted)

                    Text("How's your mood?")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(ClioTheme.textMuted)

                    if !selectedMoods.isEmpty && !isMoodExpanded {
                        Text("(\(selectedMoods.count) selected)")
                            .font(.caption)
                            .foregroundStyle(ClioTheme.feelColor)
                    }

                    Spacer()
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(ClioTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)

            // Expanded mood options
            if isMoodExpanded {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 8),
                    GridItem(.flexible(), spacing: 8),
                    GridItem(.flexible(), spacing: 8)
                ], spacing: 8) {
                    ForEach(simplifiedMoods) { mood in
                        MoodChip(
                            mood: mood,
                            isSelected: selectedMoods.contains(mood)
                        ) {
                            toggleMood(mood)
                        }
                    }
                }
                .padding(.top, 4)
            }
        }
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

    // MARK: - Notes Section (Collapsible)
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !isNotesExpanded {
                // Collapsed state
                Button {
                    withAnimation(.clioQuick) {
                        isNotesExpanded = true
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(ClioTheme.textMuted)

                        Text("Add note")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(ClioTheme.textMuted)

                        Spacer()
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(ClioTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            } else {
                // Expanded state
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Note")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(ClioTheme.textMuted)

                        Spacer()

                        Button {
                            withAnimation(.clioQuick) {
                                isNotesExpanded = false
                                notes = ""
                            }
                        } label: {
                            Image(systemName: "xmark")
                                .font(.caption)
                                .foregroundStyle(ClioTheme.textMuted)
                        }
                    }

                    TextField("Anything else on your mind?", text: $notes, axis: .vertical)
                        .font(ClioTheme.bodyFont())
                        .lineLimit(2...4)
                        .padding()
                        .background(ClioTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .foregroundStyle(ClioTheme.text)
                }
            }
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
            energyLevel: 5, // Default value since we removed the slider
            moods: selectedMoods.map { $0.rawValue },
            bodySensations: selectedSensations.map { $0.rawValue },
            primaryState: selectedPrimaryState?.rawValue,
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

// MARK: - Primary State Chip
struct PrimaryStateChip: View {
    let state: FeelCheck.PrimaryState
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: state.icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(isSelected ? .white : ClioTheme.text)

                Text(state.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(isSelected ? .white : ClioTheme.text)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(isSelected ? tileColor : ClioTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isSelected ? Color.clear : ClioTheme.surfaceHighlight, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(state.rawValue)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityHint("Double tap to \(isSelected ? "deselect" : "select")")
    }

    private var tileColor: Color {
        state.isPositive ? ClioTheme.feelColor : ClioTheme.terracotta
    }
}

// MARK: - Body State Chip
struct BodyStateChip: View {
    let sensation: FeelCheck.BodySensation
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(sensation.rawValue)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(isSelected ? .white : ClioTheme.text)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(isSelected ? tileColor : ClioTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(isSelected ? Color.clear : ClioTheme.surfaceHighlight, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(sensation.rawValue)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityHint("Double tap to \(isSelected ? "deselect" : "select")")
    }

    private var tileColor: Color {
        sensation.isPositive ? ClioTheme.success : ClioTheme.terracotta
    }
}

// MARK: - Mood Chip
struct MoodChip: View {
    let mood: FeelCheck.Mood
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(mood.rawValue)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(isSelected ? .white : ClioTheme.text)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(isSelected ? tileColor : ClioTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(isSelected ? Color.clear : ClioTheme.surfaceHighlight, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(mood.rawValue)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityHint("Double tap to \(isSelected ? "deselect" : "select")")
    }

    private var tileColor: Color {
        mood.isPositive ? ClioTheme.feelColor : ClioTheme.terracotta
    }
}

#Preview {
    FeelCheckView()
        .modelContainer(for: [UserSettings.self, FeelCheck.self], inMemory: true)
}
