import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var hasCompletedOnboarding: Bool
    @State private var currentStep = 0

    // Collected data
    @State private var lastPeriodStart: Date = Date()
    @State private var cycleLength: Double = 28
    @State private var hasCalorieGoal: Bool = false
    @State private var selectedGoal: UserSettings.GoalType = .getLeaner
    @State private var calorieRangeLow: Int = 1600
    @State private var calorieRangeHigh: Int = 2000
    @State private var selectedAllergens: Set<String> = []

    // Body metrics for calorie calculation
    @State private var heightCm: Double = 165
    @State private var weightKg: Double = 60
    @State private var birthYear: Int = 1995
    @State private var activityLevel: UserSettings.ActivityLevel = .moderate

    private let totalSteps = 5

    var body: some View {
        ZStack {
            ClioTheme.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress indicator
                if currentStep > 0 {
                    progressIndicator
                        .padding(.top, 16)
                }

                // Step content - using Group instead of TabView to avoid gesture conflicts
                Group {
                    switch currentStep {
                    case 0:
                        welcomeStep
                    case 1:
                        cycleStep
                    case 2:
                        goalsStep
                    case 3:
                        allergensStep
                    case 4:
                        readyStep
                    default:
                        welcomeStep
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                .animation(.easeInOut(duration: 0.3), value: currentStep)

                // Navigation buttons
                navigationButtons
                    .padding(.bottom, 32)
            }
        }
    }

    // MARK: - Progress Indicator
    private var progressIndicator: some View {
        HStack(spacing: 4) {
            ForEach(1..<totalSteps, id: \.self) { step in
                Capsule()
                    .fill(step <= currentStep ? ClioTheme.primary : ClioTheme.surfaceHighlight)
                    .frame(height: 4)
            }
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Step 0: Welcome
    private var welcomeStep: some View {
        VStack(spacing: 32) {
            Spacer()

            // Logo/Icon
            ZStack {
                Circle()
                    .fill(ClioTheme.primary.opacity(0.15))
                    .frame(width: 120, height: 120)

                Image(systemName: "leaf.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(ClioTheme.primary)
            }

            VStack(spacing: 16) {
                Text("Welcome to Clio")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(ClioTheme.text)

                Text("Discover what works for your body through your cycle. Log meals, movement, and how you feel - Clio finds the patterns.")
                    .font(.body)
                    .foregroundStyle(ClioTheme.textMuted)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 32)
            }

            Spacer()
            Spacer()
        }
    }

    // MARK: - Step 1: Cycle Setup
    private var cycleStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your cycle")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(ClioTheme.text)

                    Text("This helps Clio give you phase-aware suggestions")
                        .font(.subheadline)
                        .foregroundStyle(ClioTheme.textMuted)
                }

                // Last period
                VStack(alignment: .leading, spacing: 12) {
                    Text("When did your last period start?")
                        .font(.headline)
                        .foregroundStyle(ClioTheme.text)

                    // Selected date display
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundStyle(ClioTheme.primary)
                        Text(lastPeriodStart, format: .dateTime.month(.wide).day().year())
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(ClioTheme.text)
                        Spacer()
                    }
                    .padding()
                    .background(ClioTheme.primary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    DatePicker(
                        "Last period",
                        selection: $lastPeriodStart,
                        in: ...Date(),
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .tint(ClioTheme.primary)
                    .padding()
                    .background(ClioTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
                }

                // Cycle length
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

                    Text("Most cycles are 21-35 days. Not sure? 28 is a good default.")
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

    // MARK: - Step 2: Goals
    private var goalsStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Calorie goals")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(ClioTheme.text)

                    Text("Optional - skip if you just want to track without numbers")
                        .font(.subheadline)
                        .foregroundStyle(ClioTheme.textMuted)
                }

                // Toggle
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Track calorie goals")
                            .font(.body)
                            .foregroundStyle(ClioTheme.text)

                        Text("We'll calculate a personalized range for you")
                            .font(.caption)
                            .foregroundStyle(ClioTheme.textMuted)
                    }

                    Spacer()

                    Toggle("", isOn: $hasCalorieGoal)
                        .tint(ClioTheme.primary)
                }
                .padding()
                .background(ClioTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                if hasCalorieGoal {
                    // Body metrics
                    VStack(alignment: .leading, spacing: 16) {
                        Text("About you")
                            .font(.headline)
                            .foregroundStyle(ClioTheme.text)

                        // Height
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Height")
                                    .font(.subheadline)
                                    .foregroundStyle(ClioTheme.textMuted)
                                Spacer()
                                Text("\(Int(heightCm)) cm")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundStyle(ClioTheme.text)
                            }
                            Slider(value: $heightCm, in: 140...200, step: 1)
                                .tint(ClioTheme.primary)
                        }

                        // Weight
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Weight")
                                    .font(.subheadline)
                                    .foregroundStyle(ClioTheme.textMuted)
                                Spacer()
                                Text("\(Int(weightKg)) kg")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundStyle(ClioTheme.text)
                            }
                            Slider(value: $weightKg, in: 40...150, step: 1)
                                .tint(ClioTheme.primary)
                        }

                        // Birth year
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Birth year")
                                    .font(.subheadline)
                                    .foregroundStyle(ClioTheme.textMuted)
                                Spacer()
                                Picker("", selection: $birthYear) {
                                    ForEach((1950...2010).reversed(), id: \.self) { year in
                                        Text(String(year)).tag(year)
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(ClioTheme.text)
                            }
                        }
                    }
                    .padding()
                    .background(ClioTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    // Activity level
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Activity level")
                            .font(.headline)
                            .foregroundStyle(ClioTheme.text)

                        VStack(spacing: 8) {
                            ForEach(UserSettings.ActivityLevel.allCases) { level in
                                Button {
                                    withAnimation(.clioQuick) {
                                        activityLevel = level
                                        updateCalorieRange()
                                    }
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(level.displayName)
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                                .foregroundStyle(activityLevel == level ? ClioTheme.text : ClioTheme.textMuted)
                                            Text(level.description)
                                                .font(.caption)
                                                .foregroundStyle(ClioTheme.textMuted)
                                        }

                                        Spacer()

                                        if activityLevel == level {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundStyle(ClioTheme.primary)
                                        }
                                    }
                                    .padding()
                                    .background(activityLevel == level ? ClioTheme.primary.opacity(0.1) : Color.clear)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding()
                    .background(ClioTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    // Goal type
                    VStack(alignment: .leading, spacing: 12) {
                        Text("What's your goal?")
                            .font(.headline)
                            .foregroundStyle(ClioTheme.text)

                        VStack(spacing: 8) {
                            ForEach(UserSettings.GoalType.allCases) { goal in
                                Button {
                                    withAnimation(.clioQuick) {
                                        selectedGoal = goal
                                        updateCalorieRange()
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: goal.icon)
                                            .foregroundStyle(selectedGoal == goal ? ClioTheme.primary : ClioTheme.textMuted)
                                            .frame(width: 24)

                                        Text(goal.displayName)
                                            .foregroundStyle(selectedGoal == goal ? ClioTheme.text : ClioTheme.textMuted)

                                        Spacer()

                                        if selectedGoal == goal {
                                            Image(systemName: "checkmark.circle.fill")
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

                    // Calculated range display
                    VStack(spacing: 12) {
                        Text("Your personalized range")
                            .font(.caption)
                            .foregroundStyle(ClioTheme.textMuted)
                            .textCase(.uppercase)
                            .tracking(0.5)

                        HStack(spacing: 16) {
                            VStack {
                                Text("\(calorieRangeLow)")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundStyle(ClioTheme.text)

                                Text("minimum")
                                    .font(.caption)
                                    .foregroundStyle(ClioTheme.textMuted)
                            }
                            .frame(maxWidth: .infinity)

                            Text("—")
                                .foregroundStyle(ClioTheme.textMuted)

                            VStack {
                                Text("\(calorieRangeHigh)")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundStyle(ClioTheme.text)

                                Text("maximum")
                                    .font(.caption)
                                    .foregroundStyle(ClioTheme.textMuted)
                            }
                            .frame(maxWidth: .infinity)
                        }

                        if let tdee = calculatedTDEE {
                            Text("Based on your estimated \(tdee) cal/day maintenance")
                                .font(.caption)
                                .foregroundStyle(ClioTheme.textMuted)
                        }
                    }
                    .padding()
                    .background(ClioTheme.primary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    Text("You can adjust this anytime in settings")
                        .font(.caption)
                        .foregroundStyle(ClioTheme.textMuted)
                }
            }
            .padding()
            .padding(.bottom, 100)
        }
        .onChange(of: heightCm) { _, _ in updateCalorieRange() }
        .onChange(of: weightKg) { _, _ in updateCalorieRange() }
        .onChange(of: birthYear) { _, _ in updateCalorieRange() }
    }

    // MARK: - TDEE Calculation
    private var calculatedTDEE: Int? {
        let currentYear = Calendar.current.component(.year, from: Date())
        let age = currentYear - birthYear

        // Mifflin-St Jeor for women
        let bmr = (10.0 * weightKg) + (6.25 * heightCm) - (5.0 * Double(age)) - 161.0
        let tdee = bmr * activityLevel.multiplier

        return Int(tdee)
    }

    private func updateCalorieRange() {
        guard let tdee = calculatedTDEE else { return }

        switch selectedGoal {
        case .gainMuscle:
            calorieRangeLow = tdee + 200
            calorieRangeHigh = tdee + 400
        case .getLeaner:
            calorieRangeLow = tdee - 300
            calorieRangeHigh = tdee - 100
        case .loseWeight:
            calorieRangeLow = tdee - 500
            calorieRangeHigh = tdee - 300
        }
    }

    // MARK: - Step 3: Allergens
    private var allergensStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Any allergies?")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(ClioTheme.text)

                    Text("We won't suggest foods you can't eat")
                        .font(.subheadline)
                        .foregroundStyle(ClioTheme.textMuted)
                }

                // Allergen chips
                VStack(alignment: .leading, spacing: 12) {
                    Text("Common allergens")
                        .font(.headline)
                        .foregroundStyle(ClioTheme.text)

                    FlowLayout(spacing: 10) {
                        ForEach(UserSettings.commonAllergens, id: \.self) { allergen in
                            Button {
                                withAnimation(.clioQuick) {
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
                                    .padding(.vertical, 12)
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

                if !selectedAllergens.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Selected")
                            .font(.caption)
                            .foregroundStyle(ClioTheme.textMuted)

                        Text(selectedAllergens.sorted().joined(separator: ", "))
                            .font(.subheadline)
                            .foregroundStyle(ClioTheme.text)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(ClioTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Text("Skip this step if you don't have any allergies")
                    .font(.caption)
                    .foregroundStyle(ClioTheme.textMuted)
            }
            .padding()
            .padding(.bottom, 100)
        }
    }

    // MARK: - Step 4: Ready
    private var readyStep: some View {
        VStack(spacing: 32) {
            Spacer()

            // Success icon
            ZStack {
                Circle()
                    .fill(ClioTheme.success.opacity(0.15))
                    .frame(width: 120, height: 120)

                Image(systemName: "checkmark")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundStyle(ClioTheme.success)
            }

            VStack(spacing: 16) {
                Text("You're all set")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(ClioTheme.text)

                Text("Start logging what you eat, how you move, and how you feel. Clio will discover patterns unique to your body.")
                    .font(.body)
                    .foregroundStyle(ClioTheme.textMuted)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 32)
            }

            // Summary
            VStack(spacing: 12) {
                if let phase = currentPhase {
                    HStack {
                        Circle()
                            .fill(ClioTheme.phaseColor(for: phase))
                            .frame(width: 8, height: 8)

                        Text("Currently in \(phase.description)")
                            .font(.subheadline)
                            .foregroundStyle(ClioTheme.textMuted)
                    }
                }

                if hasCalorieGoal {
                    HStack {
                        Image(systemName: "flame")
                            .font(.caption)
                            .foregroundStyle(ClioTheme.eatColor)

                        Text("\(calorieRangeLow) - \(calorieRangeHigh) cal/day")
                            .font(.subheadline)
                            .foregroundStyle(ClioTheme.textMuted)
                    }
                }

                if !selectedAllergens.isEmpty {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.caption)
                            .foregroundStyle(ClioTheme.terracotta)

                        Text("Avoiding \(selectedAllergens.count) allergen\(selectedAllergens.count == 1 ? "" : "s")")
                            .font(.subheadline)
                            .foregroundStyle(ClioTheme.textMuted)
                    }
                }
            }
            .padding()
            .background(ClioTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16))

            Spacer()
            Spacer()
        }
    }

    private var currentPhase: CyclePhase? {
        CyclePhaseEngine.currentPhase(lastPeriodStart: lastPeriodStart, cycleLength: Int(cycleLength))
    }

    // MARK: - Navigation Buttons
    private var navigationButtons: some View {
        VStack(spacing: 16) {
            Button {
                if currentStep < totalSteps - 1 {
                    withAnimation {
                        currentStep += 1
                    }
                } else {
                    completeOnboarding()
                }
            } label: {
                HStack {
                    Text(currentStep == totalSteps - 1 ? "Let's go" : "Continue")
                    if currentStep == totalSteps - 1 {
                        Image(systemName: "sparkles")
                    } else {
                        Image(systemName: "arrow.right")
                    }
                }
            }
            .buttonStyle(ClioPrimaryButtonStyle())
            .padding(.horizontal)

            if currentStep > 0 && currentStep < totalSteps - 1 {
                Button {
                    withAnimation {
                        currentStep -= 1
                    }
                } label: {
                    Text("Back")
                        .font(.subheadline)
                        .foregroundStyle(ClioTheme.textMuted)
                }
            } else if currentStep == 0 {
                // Spacer to maintain layout
                Text(" ")
                    .font(.subheadline)
                    .opacity(0)
            }
        }
    }

    // MARK: - Complete Onboarding
    private func completeOnboarding() {
        // Create user settings with body metrics if calorie goal enabled
        let settings = UserSettings(
            lastPeriodStart: lastPeriodStart,
            cycleLength: Int(cycleLength),
            heightCm: hasCalorieGoal ? Int(heightCm) : nil,
            weightKg: hasCalorieGoal ? weightKg : nil,
            birthYear: hasCalorieGoal ? birthYear : nil,
            activityLevel: hasCalorieGoal ? activityLevel.rawValue : nil,
            hasCalorieGoal: hasCalorieGoal,
            calorieGoalType: hasCalorieGoal ? selectedGoal.rawValue : nil,
            calorieRangeLow: hasCalorieGoal ? calorieRangeLow : nil,
            calorieRangeHigh: hasCalorieGoal ? calorieRangeHigh : nil,
            allergens: Array(selectedAllergens).sorted(),
            hasCompletedOnboarding: true
        )

        modelContext.insert(settings)
        try? modelContext.save()

        withAnimation(.spring(response: 0.4)) {
            hasCompletedOnboarding = true
        }
    }
}

#Preview {
    OnboardingView(hasCompletedOnboarding: .constant(false))
        .modelContainer(for: [UserSettings.self], inMemory: true)
}
