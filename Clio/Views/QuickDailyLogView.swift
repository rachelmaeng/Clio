import SwiftUI
import SwiftData

struct QuickDailyLogView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \UserSettings.createdAt, order: .reverse) private var settings: [UserSettings]

    // Energy
    @State private var energyLevel: Double = 5
    @State private var hasSetEnergy = false

    // Meal
    @State private var selectedMealType: MealType?
    @State private var selectedFoodTags: Set<String> = []

    // Movement
    @State private var didMove = false
    @State private var selectedMovementType: MovementEntry.MovementType?
    @State private var movementDuration: Double = 30

    private var userSettings: UserSettings? { settings.first }
    private var currentPhase: CyclePhase { userSettings?.currentPhase ?? .follicular }

    enum MealType: String, CaseIterable {
        case breakfast = "Breakfast"
        case lunch = "Lunch"
        case dinner = "Dinner"
        case snack = "Snack"

        var icon: String {
            switch self {
            case .breakfast: return "sunrise"
            case .lunch: return "sun.max"
            case .dinner: return "moon.stars"
            case .snack: return "leaf"
            }
        }
    }

    // Quick food tags based on phase
    private var quickFoodTags: [String] {
        switch currentPhase {
        case .menstrual:
            return ["Warm soup", "Iron-rich", "Comfort food", "Dark chocolate", "Ginger tea"]
        case .follicular:
            return ["Fresh salad", "Light protein", "Citrus", "Seeds", "Fermented"]
        case .ovulation:
            return ["Raw veggies", "Lean protein", "Berries", "Fiber-rich", "Smoothie"]
        case .luteal:
            return ["Complex carbs", "Root veggies", "Magnesium-rich", "Protein", "Warm meals"]
        }
    }

    // Quick movement types based on phase
    private var suggestedMovements: [MovementEntry.MovementType] {
        switch currentPhase {
        case .menstrual:
            return [.gentleYoga, .walking, .stretching, .restDay]
        case .follicular:
            return [.yoga, .running, .cycling, .swimming]
        case .ovulation:
            return [.hiit, .running, .dancing, .fullBody]
        case .luteal:
            return [.pilates, .yoga, .walking, .swimming]
        }
    }

    private var canSave: Bool {
        hasSetEnergy || selectedMealType != nil || selectedMovementType != nil
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ClioTheme.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 28) {
                        // Phase context
                        phaseHeader

                        // Energy section
                        energySection

                        // Meal section
                        mealSection

                        // Movement section
                        movementSection
                    }
                    .padding()
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle("Quick Log")
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
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Phase Header
    private var phaseHeader: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(ClioTheme.phaseColor(for: currentPhase))
                .frame(width: 8, height: 8)

            Text("\(currentPhase.description) phase")
                .font(.subheadline)
                .foregroundStyle(ClioTheme.textMuted)

            Spacer()

            Text(formattedDate)
                .font(.caption)
                .foregroundStyle(ClioTheme.textMuted)
        }
    }

    // MARK: - Energy Section
    private var energySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "bolt.fill")
                    .foregroundStyle(ClioTheme.feelColor)
                Text("How's your energy?")
                    .font(.headline)
                    .foregroundStyle(ClioTheme.text)
                Spacer()
                if hasSetEnergy {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(ClioTheme.primary)
                }
            }

            VStack(spacing: 12) {
                // Energy display
                Text("\(Int(energyLevel))")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(energyColor)
                    .contentTransition(.numericText())
                    .animation(.clioSpring, value: energyLevel)

                Text(energyDescription)
                    .font(.subheadline)
                    .foregroundStyle(ClioTheme.textMuted)

                // Slider
                Slider(value: $energyLevel, in: 1...10, step: 1) {
                    Text("Energy")
                } onEditingChanged: { editing in
                    if !editing {
                        hasSetEnergy = true
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                }
                .tint(energyColor)

                // Labels
                HStack {
                    Text("Low")
                        .font(.caption)
                        .foregroundStyle(ClioTheme.textMuted)
                    Spacer()
                    Text("High")
                        .font(.caption)
                        .foregroundStyle(ClioTheme.textMuted)
                }
            }
            .padding()
            .background(ClioTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    private var energyColor: Color {
        switch Int(energyLevel) {
        case 1...3: return ClioTheme.terracotta
        case 4...6: return ClioTheme.eatColor
        case 7...10: return ClioTheme.primary
        default: return ClioTheme.textMuted
        }
    }

    private var energyDescription: String {
        switch Int(energyLevel) {
        case 1...2: return "Running on empty"
        case 3...4: return "A bit tired"
        case 5...6: return "Feeling okay"
        case 7...8: return "Good energy"
        case 9...10: return "Full of energy!"
        default: return ""
        }
    }

    // MARK: - Meal Section
    private var mealSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "fork.knife")
                    .foregroundStyle(ClioTheme.eatColor)
                Text("What did you eat?")
                    .font(.headline)
                    .foregroundStyle(ClioTheme.text)
                Spacer()
                if selectedMealType != nil {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(ClioTheme.primary)
                }
            }

            // Meal type selection
            HStack(spacing: 10) {
                ForEach(MealType.allCases, id: \.self) { type in
                    mealTypeButton(type)
                }
            }

            // Food tags (show when meal type selected)
            if selectedMealType != nil {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Quick tags")
                        .font(.caption)
                        .foregroundStyle(ClioTheme.textMuted)

                    FlowLayout(spacing: 8) {
                        ForEach(quickFoodTags, id: \.self) { tag in
                            foodTagChip(tag)
                        }
                    }
                }
                .padding()
                .background(ClioTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.clioSpring, value: selectedMealType)
    }

    private func mealTypeButton(_ type: MealType) -> some View {
        let isSelected = selectedMealType == type

        return Button {
            withAnimation(.clioSpring) {
                if selectedMealType == type {
                    selectedMealType = nil
                    selectedFoodTags.removeAll()
                } else {
                    selectedMealType = type
                }
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            VStack(spacing: 6) {
                Image(systemName: type.icon)
                    .font(.system(size: 20))
                Text(type.rawValue)
                    .font(.caption2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? ClioTheme.eatColor.opacity(0.15) : ClioTheme.surface)
            .foregroundStyle(isSelected ? ClioTheme.eatColor : ClioTheme.text)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? ClioTheme.eatColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private func foodTagChip(_ tag: String) -> some View {
        let isSelected = selectedFoodTags.contains(tag)

        return Button {
            withAnimation(.clioSpring) {
                if isSelected {
                    selectedFoodTags.remove(tag)
                } else {
                    selectedFoodTags.insert(tag)
                }
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            Text(tag)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isSelected ? ClioTheme.eatColor.opacity(0.2) : ClioTheme.surfaceHighlight)
                .foregroundStyle(isSelected ? ClioTheme.eatColor : ClioTheme.text)
                .clipShape(Capsule())
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: - Movement Section
    private var movementSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "figure.run")
                    .foregroundStyle(ClioTheme.moveColor)
                Text("Did you move?")
                    .font(.headline)
                    .foregroundStyle(ClioTheme.text)
                Spacer()
                if selectedMovementType != nil {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(ClioTheme.primary)
                }
            }

            // Quick movement type selection
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(suggestedMovements, id: \.self) { type in
                        movementTypeCard(type)
                    }
                }
            }

            // Duration (show when movement selected)
            if selectedMovementType != nil {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Duration")
                            .font(.subheadline)
                            .foregroundStyle(ClioTheme.text)
                        Spacer()
                        Text("\(Int(movementDuration)) min")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(ClioTheme.moveColor)
                    }

                    // Quick duration chips
                    HStack(spacing: 8) {
                        ForEach([15, 30, 45, 60], id: \.self) { mins in
                            durationChip(mins)
                        }
                    }
                }
                .padding()
                .background(ClioTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.clioSpring, value: selectedMovementType)
    }

    private func movementTypeCard(_ type: MovementEntry.MovementType) -> some View {
        let isSelected = selectedMovementType == type
        let isSuggested = suggestedMovements.contains(type)

        return Button {
            withAnimation(.clioSpring) {
                if selectedMovementType == type {
                    selectedMovementType = nil
                } else {
                    selectedMovementType = type
                }
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(isSelected ? ClioTheme.moveColor.opacity(0.2) : ClioTheme.surface)
                        .frame(width: 48, height: 48)

                    Image(systemName: type.icon)
                        .font(.system(size: 20))
                        .foregroundStyle(isSelected ? ClioTheme.moveColor : ClioTheme.text)

                    // Phase suggestion dot
                    if isSuggested && !isSelected {
                        Circle()
                            .fill(ClioTheme.phaseColor(for: currentPhase))
                            .frame(width: 8, height: 8)
                            .offset(x: 18, y: -18)
                    }
                }

                Text(type.rawValue)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(isSelected ? ClioTheme.moveColor : ClioTheme.text)
                    .lineLimit(1)
            }
            .frame(width: 72)
            .padding(.vertical, 10)
            .background(isSelected ? ClioTheme.moveColor.opacity(0.1) : ClioTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? ClioTheme.moveColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private func durationChip(_ minutes: Int) -> some View {
        let isSelected = Int(movementDuration) == minutes

        return Button {
            withAnimation(.clioSpring) {
                movementDuration = Double(minutes)
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            Text("\(minutes)")
                .font(.subheadline)
                .fontWeight(.medium)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(isSelected ? ClioTheme.moveColor.opacity(0.2) : ClioTheme.surfaceHighlight)
                .foregroundStyle(isSelected ? ClioTheme.moveColor : ClioTheme.text)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: - Save Button
    private var saveButton: some View {
        Button {
            saveLog()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .semibold))
                Text("Save Log")
            }
        }
        .buttonStyle(ClioPrimaryButtonStyle())
        .disabled(!canSave)
        .opacity(canSave ? 1 : 0.5)
        .padding()
        .background(
            LinearGradient(
                colors: [ClioTheme.background.opacity(0), ClioTheme.background],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    // MARK: - Save Logic
    private func saveLog() {
        // Save feel check if energy was set
        if hasSetEnergy {
            let feelCheck = FeelCheck(
                energyLevel: Int(energyLevel),
                cyclePhase: currentPhase.rawValue,
                cycleDay: userSettings?.dayOfCycle
            )
            modelContext.insert(feelCheck)
        }

        // Save meal if selected
        if let mealType = selectedMealType {
            let meal = MealEntry(
                mealType: mealType.rawValue,
                descriptionText: selectedFoodTags.joined(separator: ", ")
            )
            modelContext.insert(meal)
        }

        // Save movement if selected
        if let movementType = selectedMovementType {
            let movement = MovementEntry(
                type: movementType.rawValue,
                durationMinutes: Int(movementDuration)
            )
            modelContext.insert(movement)
        }

        try? modelContext.save()

        UINotificationFeedbackGenerator().notificationOccurred(.success)
        dismiss()
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: Date())
    }
}

#Preview {
    QuickDailyLogView()
        .modelContainer(for: [UserSettings.self, FeelCheck.self, MovementEntry.self, MealEntry.self], inMemory: true)
}
