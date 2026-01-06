import SwiftUI
import SwiftData

// MARK: - Intensity Enum

enum WorkoutIntensity: String, CaseIterable, Identifiable {
    case light = "Light"
    case moderate = "Moderate"
    case intense = "Intense"

    var id: String { rawValue }

    var multiplier: Double {
        switch self {
        case .light: return 0.7
        case .moderate: return 1.0
        case .intense: return 1.4
        }
    }

    var intensityLevel: Int {
        switch self {
        case .light: return 3
        case .moderate: return 6
        case .intense: return 9
        }
    }
}

// MARK: - Wizard Step Enum

private enum LoggingStep {
    case selectType
    case configure
}

// MARK: - Duration Notch Slider

private struct DurationNotchSlider: View {
    @Binding var value: Double

    let notches: [Double] = [5, 15, 30, 45, 60, 75, 90, 120]
    private let snapThreshold: Double = 4

    var body: some View {
        VStack(spacing: 16) {
            // Large duration display
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(Int(value))")
                    .font(ClioTheme.displayFont(48))
                    .foregroundStyle(ClioTheme.text)
                    .contentTransition(.numericText())
                    .animation(.clioQuick, value: value)

                Text("min")
                    .font(ClioTheme.bodyFont())
                    .foregroundStyle(ClioTheme.textMuted)
            }

            // Slider with notch track
            GeometryReader { geometry in
                let trackWidth = geometry.size.width

                ZStack(alignment: .leading) {
                    // Track background
                    Capsule()
                        .fill(ClioTheme.surfaceHighlight)
                        .frame(height: 6)

                    // Filled track
                    Capsule()
                        .fill(ClioTheme.moveColor)
                        .frame(width: progressWidth(for: trackWidth), height: 6)

                    // Notch markers
                    ForEach(notches, id: \.self) { notch in
                        Circle()
                            .fill(value >= notch ? ClioTheme.moveColor : ClioTheme.textLight)
                            .frame(width: 8, height: 8)
                            .offset(x: notchPosition(notch, in: trackWidth) - 4)
                    }

                    // Thumb
                    Circle()
                        .fill(.white)
                        .frame(width: 24, height: 24)
                        .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
                        .offset(x: thumbPosition(for: trackWidth) - 12)
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { gesture in
                                    updateValue(from: gesture.location.x, in: trackWidth)
                                }
                        )
                }
                .frame(height: 24)
            }
            .frame(height: 24)

            // Notch labels
            HStack {
                ForEach(notches, id: \.self) { notch in
                    Text("\(Int(notch))")
                        .font(ClioTheme.captionFont(11))
                        .foregroundStyle(value == notch ? ClioTheme.text : ClioTheme.textLight)
                        .fontWeight(value == notch ? .medium : .regular)

                    if notch != notches.last {
                        Spacer()
                    }
                }
            }
        }
    }

    private func progressWidth(for trackWidth: CGFloat) -> CGFloat {
        let progress = (value - 5) / (120 - 5)
        return trackWidth * CGFloat(progress)
    }

    private func thumbPosition(for trackWidth: CGFloat) -> CGFloat {
        let progress = (value - 5) / (120 - 5)
        return trackWidth * CGFloat(progress)
    }

    private func notchPosition(_ notch: Double, in trackWidth: CGFloat) -> CGFloat {
        let progress = (notch - 5) / (120 - 5)
        return trackWidth * CGFloat(progress)
    }

    private func updateValue(from x: CGFloat, in trackWidth: CGFloat) {
        let progress = max(0, min(1, x / trackWidth))
        var newValue = 5 + progress * (120 - 5)

        // Snap to nearby notch
        for notch in notches {
            if abs(newValue - notch) < snapThreshold {
                if newValue != notch {
                    newValue = notch
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                }
                break
            }
        }

        value = round(newValue)
    }
}

// MARK: - Workout Config Panel

private struct WorkoutConfigPanel: View {
    @Binding var duration: Double
    @Binding var intensity: WorkoutIntensity
    let movementType: MovementEntry.MovementType
    let showCalories: Bool

    private var estimatedCalories: Int {
        Int(movementType.caloriesPerMinute * intensity.multiplier * duration)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Duration slider
            DurationNotchSlider(value: $duration)
                .padding(ClioTheme.spacing)

            Divider()
                .background(ClioTheme.surfaceHighlight)

            // Intensity buttons
            VStack(alignment: .leading, spacing: ClioTheme.spacingSmall) {
                Text("Intensity")
                    .font(ClioTheme.captionFont(12))
                    .foregroundStyle(ClioTheme.textMuted)

                HStack(spacing: ClioTheme.spacingSmall) {
                    ForEach(WorkoutIntensity.allCases) { level in
                        IntensityButton(
                            level: level,
                            isSelected: intensity == level
                        ) {
                            withAnimation(.clioQuick) {
                                intensity = level
                            }
                        }
                    }
                }
            }
            .padding(ClioTheme.spacing)

            // Calorie estimate (if enabled)
            if showCalories {
                Divider()
                    .background(ClioTheme.surfaceHighlight)

                HStack {
                    Text("~")
                        .font(ClioTheme.captionFont())
                        .foregroundStyle(ClioTheme.textMuted)

                    Text("\(estimatedCalories)")
                        .font(ClioTheme.headingFont(20))
                        .foregroundStyle(ClioTheme.text)
                        .contentTransition(.numericText())
                        .animation(.clioQuick, value: estimatedCalories)

                    Text("calories")
                        .font(ClioTheme.captionFont())
                        .foregroundStyle(ClioTheme.textMuted)

                    Spacer()

                    Text("estimate")
                        .font(ClioTheme.captionFont(11))
                        .foregroundStyle(ClioTheme.textLight)
                }
                .padding(ClioTheme.spacing)
            }
        }
        .background(ClioTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: ClioTheme.cornerRadius, style: .continuous))
    }
}

// MARK: - Intensity Button

private struct IntensityButton: View {
    let level: WorkoutIntensity
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: iconName)
                    .font(.system(size: 18, weight: .medium))

                Text(level.rawValue)
                    .font(ClioTheme.captionFont(12))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, ClioTheme.spacing)
            .background(isSelected ? ClioTheme.moveColor : ClioTheme.surfaceHighlight)
            .foregroundStyle(isSelected ? .white : ClioTheme.textMuted)
            .clipShape(RoundedRectangle(cornerRadius: ClioTheme.cornerRadiusSmall, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var iconName: String {
        switch level {
        case .light: return "circle"
        case .moderate: return "circle.lefthalf.filled"
        case .intense: return "circle.fill"
        }
    }
}

// MARK: - Movement Selection Step

private struct MovementSelectionStep: View {
    let phase: CyclePhase
    let isLoggingPastDay: Bool
    let targetDate: Date
    let onSelect: (MovementEntry.MovementType) -> Void
    @Binding var customWorkoutName: String

    @State private var showCustomInput = false

    private var suggestedMovements: [MovementEntry.MovementType] {
        switch phase {
        case .menstrual:
            return [.yoga, .walking, .stretching, .gentleYoga]
        case .follicular:
            return [.hiit, .running, .cycling, .dancing]
        case .ovulation:
            return [.hiit, .running, .fullBody, .cycling]
        case .luteal:
            return [.pilates, .swimming, .yoga, .walking]
        }
    }

    private var phaseContext: String {
        switch phase {
        case .menstrual: return "Gentle movement is perfect"
        case .follicular: return "Great for new challenges"
        case .ovulation: return "Push yourself today"
        case .luteal: return "Moderate intensity works best"
        }
    }

    private var pastDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter
    }

    private var displayCategories: [MovementEntry.MovementCategory] {
        [.cardio, .strength, .flexibility, .lowImpact, .rest]
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: ClioTheme.spacingLarge) {
                // Header
                header
                    .fadeInFromBottom(delay: 0)

                // Categories
                ForEach(Array(displayCategories.enumerated()), id: \.element.id) { index, category in
                    categorySection(category)
                        .fadeInFromBottom(delay: 0.05 * Double(index + 1))
                }

                // Custom input (if expanded)
                if showCustomInput {
                    customInputSection
                        .fadeInFromBottom(delay: 0.3)
                }
            }
            .padding(ClioTheme.spacing)
            .padding(.bottom, 40)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(isLoggingPastDay ? "Log past movement" : "What did you do?")
                .font(ClioTheme.displayFont(28))
                .foregroundStyle(ClioTheme.text)

            if isLoggingPastDay {
                Text(pastDateFormatter.string(from: targetDate))
                    .font(ClioTheme.labelFont())
                    .foregroundStyle(ClioTheme.primary)
            }

            // Phase context
            HStack(spacing: 8) {
                Circle()
                    .fill(ClioTheme.phaseColor(for: phase))
                    .frame(width: 6, height: 6)

                Text("\(phase.description) · \(phaseContext)")
                    .font(ClioTheme.captionFont(13))
                    .foregroundStyle(ClioTheme.textMuted)
            }
        }
    }

    private func categorySection(_ category: MovementEntry.MovementCategory) -> some View {
        VStack(alignment: .leading, spacing: ClioTheme.spacingSmall) {
            // Category header
            Text(category.rawValue)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(ClioTheme.textMuted)
                .textCase(.uppercase)
                .tracking(0.5)

            // Movement cards in horizontal scroll
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    let types = movementTypesForCategory(category)

                    ForEach(types, id: \.self) { type in
                        if type == .custom {
                            customCard
                        } else {
                            movementCard(type: type)
                        }
                    }
                }
            }
        }
    }

    private func movementTypesForCategory(_ category: MovementEntry.MovementCategory) -> [MovementEntry.MovementType] {
        var types = category.movementTypes

        if category == .rest {
            types.append(.custom)
        }

        return types.sorted { type1, type2 in
            let suggested1 = suggestedMovements.contains(type1)
            let suggested2 = suggestedMovements.contains(type2)
            if suggested1 && !suggested2 { return true }
            if !suggested1 && suggested2 { return false }
            return false
        }
    }

    private func movementCard(type: MovementEntry.MovementType) -> some View {
        let isSuggested = suggestedMovements.contains(type)
        let accentColor = cardColor(for: type)

        return Button {
            onSelect(type)
        } label: {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(accentColor.opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: type.icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(accentColor)

                    // Suggested indicator
                    if isSuggested {
                        Circle()
                            .fill(ClioTheme.phaseColor(for: phase))
                            .frame(width: 8, height: 8)
                            .offset(x: 16, y: -16)
                    }
                }

                Text(type.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(ClioTheme.text)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(height: 32, alignment: .top)
            }
            .frame(width: 80)
            .padding(.vertical, 12)
            .background(ClioTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private var customCard: some View {
        Button {
            withAnimation(.clioSpring) {
                showCustomInput.toggle()
            }
        } label: {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(showCustomInput ? ClioTheme.moveColor : ClioTheme.surfaceHighlight)
                        .frame(width: 44, height: 44)

                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(showCustomInput ? .white : ClioTheme.textMuted)
                }

                Text("Custom")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(ClioTheme.text)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(height: 32, alignment: .top)
            }
            .frame(width: 80)
            .padding(.vertical, 12)
            .background(ClioTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // Color mapping for movement types (matches HomeTipCard style)
    private func cardColor(for type: MovementEntry.MovementType) -> Color {
        switch type {
        // Cardio - teal
        case .running, .hiit, .cycling, .dancing, .jumpRope:
            return Color(hex: "4A7070")
        // Strength - brown
        case .upperBody, .lowerBody, .push, .pull, .fullBody, .core:
            return Color(hex: "A08070")
        // Flexibility - sage green
        case .yoga, .pilates, .stretching:
            return Color(hex: "6B9B7A")
        // Low Impact - varies
        case .walking, .gentleYoga:
            return Color(hex: "C89898") // rose
        case .hiking:
            return Color(hex: "6B9B7A") // sage
        case .swimming:
            return Color(hex: "7A9EB0") // blue
        case .taiChi:
            return Color(hex: "6B9B7A") // sage
        case .leisureCycling:
            return Color(hex: "7A9EB0") // blue
        // Rest
        case .restDay:
            return Color(hex: "C89898") // rose
        case .custom:
            return ClioTheme.moveColor
        }
    }

    private var customInputSection: some View {
        VStack(alignment: .leading, spacing: ClioTheme.spacingSmall) {
            Text("Name your workout")
                .font(ClioTheme.captionFont(12))
                .foregroundStyle(ClioTheme.textMuted)

            HStack(spacing: ClioTheme.spacingSmall) {
                TextField("e.g., Rock climbing, Dance class...", text: $customWorkoutName)
                    .font(ClioTheme.bodyFont())
                    .foregroundStyle(ClioTheme.text)
                    .padding(ClioTheme.spacing)
                    .background(ClioTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: ClioTheme.cornerRadiusSmall))

                Button {
                    if !customWorkoutName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        onSelect(.custom)
                    }
                } label: {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(
                            customWorkoutName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                ? ClioTheme.textLight
                                : ClioTheme.moveColor
                        )
                }
                .disabled(customWorkoutName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(ClioTheme.spacing)
        .background(ClioTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: ClioTheme.cornerRadius, style: .continuous))
    }
}

// MARK: - Movement Configuration Step

private struct MovementConfigurationStep: View {
    let selectedType: MovementEntry.MovementType
    let customName: String
    let showCalories: Bool
    let onBack: () -> Void

    @Binding var duration: Double
    @Binding var intensity: WorkoutIntensity
    @Binding var selectedFeelAfter: Set<MovementEntry.FeelAfter>
    @Binding var notes: String

    private var displayName: String {
        if selectedType == .custom && !customName.isEmpty {
            return customName
        }
        return selectedType.rawValue
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: ClioTheme.spacingLarge) {
                // Header with back and selected type
                header
                    .fadeInFromBottom(delay: 0)

                // Config panel
                WorkoutConfigPanel(
                    duration: $duration,
                    intensity: $intensity,
                    movementType: selectedType,
                    showCalories: showCalories
                )
                .fadeInFromBottom(delay: 0.1)

                // Feel after section
                feelAfterSection
                    .fadeInFromBottom(delay: 0.2)

                // Notes section
                notesSection
                    .fadeInFromBottom(delay: 0.3)
            }
            .padding(ClioTheme.spacing)
            .padding(.bottom, 140)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: ClioTheme.spacingSmall) {
            // Back button
            Button(action: onBack) {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .medium))

                    Text("Back")
                        .font(ClioTheme.captionFont(14))
                }
                .foregroundStyle(ClioTheme.textMuted)
            }

            // Selected workout display
            HStack(spacing: 12) {
                Image(systemName: selectedType.icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(ClioTheme.moveColor)

                Text(displayName)
                    .font(ClioTheme.displayFont(24))
                    .foregroundStyle(ClioTheme.text)
            }
            .padding(.top, ClioTheme.spacingSmall)
        }
    }

    private var feelAfterSection: some View {
        VStack(alignment: .leading, spacing: ClioTheme.spacingSmall) {
            HStack(spacing: 6) {
                Text("How do you feel?")
                    .font(ClioTheme.subheadingFont())
                    .foregroundStyle(ClioTheme.text)

                Text("optional")
                    .font(ClioTheme.captionFont(11))
                    .foregroundStyle(ClioTheme.textLight)
            }

            FlowLayout(spacing: 10) {
                ForEach(MovementEntry.FeelAfter.allCases) { feel in
                    Button {
                        withAnimation(.clioQuick) {
                            if selectedFeelAfter.contains(feel) {
                                selectedFeelAfter.remove(feel)
                            } else {
                                selectedFeelAfter.insert(feel)
                            }
                        }
                    } label: {
                        Text(feel.rawValue)
                            .font(ClioTheme.captionFont(13))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(selectedFeelAfter.contains(feel) ? feelColor(feel) : ClioTheme.surfaceHighlight)
                            .foregroundStyle(selectedFeelAfter.contains(feel) ? .white : ClioTheme.textMuted)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func feelColor(_ feel: MovementEntry.FeelAfter) -> Color {
        feel.isPositive ? ClioTheme.success : ClioTheme.terracotta
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: ClioTheme.spacingSmall) {
            HStack(spacing: 6) {
                Text("Notes")
                    .font(ClioTheme.subheadingFont())
                    .foregroundStyle(ClioTheme.text)

                Text("optional")
                    .font(ClioTheme.captionFont(11))
                    .foregroundStyle(ClioTheme.textLight)
            }

            TextField("Any thoughts about this workout?", text: $notes, axis: .vertical)
                .font(ClioTheme.bodyFont())
                .lineLimit(2...4)
                .padding(ClioTheme.spacing)
                .background(ClioTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: ClioTheme.cornerRadiusSmall))
                .foregroundStyle(ClioTheme.text)
        }
    }
}

// MARK: - Main View

struct AddMovementView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \UserSettings.createdAt, order: .reverse) private var settings: [UserSettings]

    var forDate: Date?
    var preselectedType: MovementEntry.MovementType?

    @State private var currentStep: LoggingStep = .selectType
    @State private var selectedType: MovementEntry.MovementType?
    @State private var customWorkoutName: String = ""
    @State private var durationMinutes: Double = 30
    @State private var intensity: WorkoutIntensity = .moderate
    @State private var selectedFeelAfter: Set<MovementEntry.FeelAfter> = []
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

    private var estimatedCalories: Int? {
        guard let type = selectedType else { return nil }
        return Int(type.caloriesPerMinute * intensity.multiplier * durationMinutes)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ClioTheme.background
                    .ignoresSafeArea()

                Group {
                    switch currentStep {
                    case .selectType:
                        MovementSelectionStep(
                            phase: phaseForTargetDate,
                            isLoggingPastDay: isLoggingPastDay,
                            targetDate: targetDate,
                            onSelect: { type in selectMovementType(type) },
                            customWorkoutName: $customWorkoutName
                        )
                        .transition(.asymmetric(
                            insertion: .move(edge: .leading).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))

                    case .configure:
                        if let type = selectedType {
                            MovementConfigurationStep(
                                selectedType: type,
                                customName: customWorkoutName,
                                showCalories: userSettings?.showCalorieBurnEstimate == true,
                                onBack: { goBackToSelection() },
                                duration: $durationMinutes,
                                intensity: $intensity,
                                selectedFeelAfter: $selectedFeelAfter,
                                notes: $notes
                            )
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .trailing).combined(with: .opacity)
                            ))
                        }
                    }
                }
                .animation(.clioSpring, value: currentStep)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    ClioCloseButton { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if currentStep == .configure {
                    saveButton
                }
            }
            .onAppear {
                if let type = preselectedType {
                    selectMovementType(type)
                }
            }
        }
    }

    private func selectMovementType(_ type: MovementEntry.MovementType) {
        selectedType = type
        withAnimation(.clioSpring) {
            currentStep = .configure
        }
    }

    private func goBackToSelection() {
        withAnimation(.clioSpring) {
            currentStep = .selectType
        }
    }

    private var saveButton: some View {
        Button {
            saveMovement()
        } label: {
            Text("Save movement")
        }
        .buttonStyle(ClioPrimaryButtonStyle())
        .padding(ClioTheme.spacing)
        .background(
            LinearGradient(
                colors: [ClioTheme.background.opacity(0), ClioTheme.background],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private func saveMovement() {
        guard let type = selectedType else { return }

        let workoutType: String
        if type == .custom && !customWorkoutName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            workoutType = customWorkoutName.trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            workoutType = type.rawValue
        }

        let movement = MovementEntry(type: workoutType)

        movement.dateTime = targetDate
        movement.durationMinutes = Int(durationMinutes)
        movement.intensityLevel = intensity.intensityLevel
        movement.feelAfter = selectedFeelAfter.map { $0.rawValue }
        movement.notes = notes.isEmpty ? nil : notes

        if userSettings?.showCalorieBurnEstimate == true, let cals = estimatedCalories {
            movement.estimatedCaloriesBurned = cals
        }

        movement.setCycleContext(phase: phaseForTargetDate, day: dayOfCycleForTargetDate)

        modelContext.insert(movement)
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    AddMovementView()
        .modelContainer(for: [UserSettings.self, MovementEntry.self], inMemory: true)
}
