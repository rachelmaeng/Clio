import SwiftUI
import SwiftData

struct AddMealView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \UserSettings.createdAt, order: .reverse) private var settings: [UserSettings]
    @Query(sort: \SavedMeal.lastUsed, order: .reverse) private var savedMeals: [SavedMeal]

    // Optional date for logging past days
    var forDate: Date?

    // Optional pre-filled food tip (when user taps a suggested food)
    var prefilledTip: PhaseTip?

    // Optional pre-selected meal type (when user taps a quick-log tile)
    var preselectedMealType: MealEntry.MealType?

    @State private var mealType: MealEntry.MealType = .lunch
    @State private var foodItems: [String] = []
    @State private var whyFoodExpanded: Bool = false
    @State private var currentFoodInput = ""
    @State private var calories: String = ""
    @State private var protein: String = ""
    @State private var carbs: String = ""
    @State private var fat: String = ""
    @State private var notes: String = ""
    @State private var selectedResponses: Set<MealEntry.BodyResponse> = []
    @State private var specificReaction: String = ""
    @State private var saveAsTemplate: Bool = false
    @State private var templateName: String = ""

    // Guard against double-tap saving
    @State private var isSaving = false

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
                    VStack(alignment: .leading, spacing: 24) {
                        // Header
                        header
                            .fadeInFromBottom(delay: 0)

                        // "Why [food]?" card (if prefilled tip exists)
                        if let tip = prefilledTip {
                            whyFoodCard(tip: tip)
                                .fadeInFromBottom(delay: 0.05)
                        }

                        // Saved Meals (if any exist and no prefilled tip)
                        if !savedMeals.isEmpty && prefilledTip == nil {
                            savedMealsSection
                                .fadeInFromBottom(delay: 0.05)
                        }

                        // Meal Type
                        mealTypeSection
                            .fadeInFromBottom(delay: 0.1)

                        // Food Items
                        foodItemsSection
                            .fadeInFromBottom(delay: 0.2)

                        // Optional: Macros
                        if userSettings?.hasCalorieGoal == true {
                            macrosSection
                                .fadeInFromBottom(delay: 0.3)
                        }

                        // Body Response (optional)
                        bodyResponseSection
                            .fadeInFromBottom(delay: 0.4)

                        // Save as template
                        saveAsTemplateSection
                            .fadeInFromBottom(delay: 0.45)

                        // Notes
                        notesSection
                            .fadeInFromBottom(delay: 0.5)
                    }
                    .padding()
                    .padding(.bottom, 120)
                }
                .onAppear {
                    // Pre-fill food item if a tip was provided
                    if let tip = prefilledTip, !foodItems.contains(tip.name) {
                        foodItems.append(tip.name)
                    }
                    // Pre-select meal type if provided
                    if let preselected = preselectedMealType {
                        mealType = preselected
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(ClioTheme.textMuted)
                    }
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
            Text(isLoggingPastDay ? "Log a past meal" : "Log a meal")
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
            }
        }
    }

    private var pastDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter
    }

    // MARK: - Why Food Card (collapsible)
    private func whyFoodCard(tip: PhaseTip) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.clioQuick) {
                    whyFoodExpanded.toggle()
                }
            } label: {
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: tip.icon)
                            .font(.system(size: 14))
                            .foregroundStyle(ClioTheme.eatColor)

                        Text("Why \(tip.name)?")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(ClioTheme.text)
                    }

                    Spacer()

                    Image(systemName: whyFoodExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(ClioTheme.textMuted)
                }
                .padding()
                .background(ClioTheme.eatColor.opacity(0.08))
                .clipShape(
                    whyFoodExpanded
                        ? UnevenRoundedRectangle(topLeadingRadius: 12, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 12)
                        : UnevenRoundedRectangle(topLeadingRadius: 12, bottomLeadingRadius: 12, bottomTrailingRadius: 12, topTrailingRadius: 12)
                )
            }
            .buttonStyle(.plain)

            if whyFoodExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(tip.whyBenefits.prefix(3), id: \.self) { benefit in
                        HStack(alignment: .top, spacing: 8) {
                            Circle()
                                .fill(ClioTheme.eatColor)
                                .frame(width: 5, height: 5)
                                .padding(.top, 6)

                            Text(benefit)
                                .font(.caption)
                                .foregroundStyle(ClioTheme.textMuted)
                        }
                    }
                }
                .padding()
                .background(ClioTheme.surface)
                .clipShape(
                    UnevenRoundedRectangle(topLeadingRadius: 0, bottomLeadingRadius: 12, bottomTrailingRadius: 12, topTrailingRadius: 0)
                )
            }
        }
    }

    // MARK: - Meal Type
    private var mealTypeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Meal type")
                .font(.headline)
                .foregroundStyle(ClioTheme.text)

            HStack(spacing: 8) {
                ForEach(MealEntry.MealType.allCases) { type in
                    Button {
                        withAnimation(.clioQuick) {
                            mealType = type
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: type.icon)
                                .font(.system(size: 12))

                            Text(type.rawValue)
                                .font(.system(size: 13, weight: .medium))
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .background(mealType == type ? ClioTheme.eatColor.opacity(0.15) : ClioTheme.surface)
                        .foregroundStyle(mealType == type ? ClioTheme.eatColor : ClioTheme.textMuted)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(mealType == type ? ClioTheme.eatColor.opacity(0.3) : Color.clear, lineWidth: 1)
                        )
                    }
                    .buttonStyle(TipChipButtonStyle())
                }
            }
        }
    }

    // MARK: - Food Items
    private var foodItemsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("What did you eat?")
                .font(.headline)
                .foregroundStyle(ClioTheme.text)

            VStack(spacing: 12) {
                // Food input
                HStack {
                    TextField(foodItems.isEmpty ? "e.g., Grilled chicken" : "Add another item...", text: $currentFoodInput)
                        .foregroundStyle(ClioTheme.text)
                        .submitLabel(.done)
                        .onSubmit {
                            addFoodItem()
                        }

                    Button {
                        addFoodItem()
                    } label: {
                        Text("Add")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(currentFoodInput.isEmpty ? ClioTheme.textMuted : ClioTheme.eatColor)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(currentFoodInput.isEmpty ? ClioTheme.surface : ClioTheme.eatColor.opacity(0.15))
                            .clipShape(Capsule())
                    }
                    .disabled(currentFoodInput.isEmpty)
                }
                .padding()
                .background(ClioTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Added food items (below input)
                if !foodItems.isEmpty {
                    FlowLayout(spacing: 8) {
                        ForEach(foodItems, id: \.self) { item in
                            FoodItemChip(name: item) {
                                withAnimation {
                                    foodItems.removeAll { $0 == item }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private func addFoodItem() {
        let item = currentFoodInput.trimmingCharacters(in: .whitespacesAndNewlines)
        if !item.isEmpty && !foodItems.contains(item) {
            withAnimation {
                foodItems.append(item)
                currentFoodInput = ""
            }
        }
    }

    // MARK: - Macros Section
    private var macrosSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Nutrition")
                    .font(.headline)
                    .foregroundStyle(ClioTheme.text)

                Text("(optional)")
                    .font(.caption)
                    .foregroundStyle(ClioTheme.textMuted)
            }

            HStack(spacing: 12) {
                MacroInputField(label: "Calories", value: $calories, unit: "cal")
                MacroInputField(label: "Protein", value: $protein, unit: "g")
                MacroInputField(label: "Carbs", value: $carbs, unit: "g")
                MacroInputField(label: "Fat", value: $fat, unit: "g")
            }
        }
    }

    // MARK: - Body Response
    private var bodyResponseSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("How did it make you feel?")
                    .font(.headline)
                    .foregroundStyle(ClioTheme.text)

                Text("(optional)")
                    .font(.caption)
                    .foregroundStyle(ClioTheme.textMuted)
            }

            FlowLayout(spacing: 8) {
                ForEach(MealEntry.BodyResponse.allCases) { response in
                    Button {
                        withAnimation(.clioQuick) {
                            if selectedResponses.contains(response) {
                                selectedResponses.remove(response)
                            } else {
                                selectedResponses.insert(response)
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: response.icon)
                                .font(.caption)

                            Text(response.rawValue)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(selectedResponses.contains(response) ? responseColor(response).opacity(0.15) : ClioTheme.surface)
                        .foregroundStyle(selectedResponses.contains(response) ? responseColor(response) : ClioTheme.textMuted)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(selectedResponses.contains(response) ? responseColor(response).opacity(0.3) : Color.clear, lineWidth: 1)
                        )
                    }
                    .buttonStyle(TipChipButtonStyle())
                }
            }

            // Specific food reaction
            if selectedResponses.contains(where: { !$0.isPositive }) {
                TextField("Any specific food that caused this?", text: $specificReaction)
                    .font(.subheadline)
                    .foregroundStyle(ClioTheme.text)
                    .padding()
                    .background(ClioTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private func responseColor(_ response: MealEntry.BodyResponse) -> Color {
        response.isPositive ? ClioTheme.success : ClioTheme.terracotta
    }

    // MARK: - Saved Meals Section
    private var savedMealsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your saved meals")
                .font(.headline)
                .foregroundStyle(ClioTheme.text)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(savedMeals.prefix(10)) { saved in
                        Button {
                            loadSavedMeal(saved)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(saved.name)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundStyle(ClioTheme.text)
                                    .lineLimit(1)

                                if let macros = saved.macrosSummary {
                                    Text(macros)
                                        .font(.caption)
                                        .foregroundStyle(ClioTheme.textMuted)
                                        .lineLimit(1)
                                }
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(ClioTheme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(ClioTheme.eatColor.opacity(0.2), lineWidth: 1)
                            )
                        }
                        .buttonStyle(TipChipButtonStyle())
                    }
                }
            }
        }
    }

    private func loadSavedMeal(_ saved: SavedMeal) {
        foodItems = saved.foodItems
        if let cal = saved.calories { calories = String(cal) }
        if let prot = saved.protein { protein = String(prot) }
        if let carb = saved.carbs { carbs = String(carb) }
        if let fatVal = saved.fat { fat = String(fatVal) }
        if let type = saved.mealType, let mealEnum = MealEntry.MealType(rawValue: type) {
            mealType = mealEnum
        }
        templateName = saved.name
        saved.incrementUsage()
    }

    // MARK: - Save as Template Section
    private var saveAsTemplateSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation(.clioQuick) {
                    saveAsTemplate.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: saveAsTemplate ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(saveAsTemplate ? ClioTheme.eatColor : ClioTheme.textMuted)

                    Text("Save as a quick meal")
                        .font(.subheadline)
                        .foregroundStyle(ClioTheme.text)

                    Spacer()
                }
            }
            .buttonStyle(.plain)

            if saveAsTemplate {
                TextField("Meal name (e.g., Morning smoothie)", text: $templateName)
                    .font(.subheadline)
                    .foregroundStyle(ClioTheme.text)
                    .padding()
                    .background(ClioTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    // MARK: - Notes Section
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Notes")
                    .font(.headline)
                    .foregroundStyle(ClioTheme.text)

                Text("(optional)")
                    .font(.caption)
                    .foregroundStyle(ClioTheme.textMuted)
            }

            TextField("Any thoughts about this meal?", text: $notes, axis: .vertical)
                .lineLimit(2...4)
                .padding()
                .background(ClioTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .foregroundStyle(ClioTheme.text)
        }
    }

    // Check if we have food to save (either added items OR text in input)
    private var hasFoodToSave: Bool {
        !foodItems.isEmpty || !currentFoodInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Save Button
    private var saveButton: some View {
        VStack(spacing: 8) {
            if !hasFoodToSave {
                Text("Add at least one food item to save")
                    .font(.caption)
                    .foregroundStyle(ClioTheme.textMuted)
            }

            Button {
                saveMeal()
            } label: {
                Text(isSaving ? "Saving..." : "Save meal")
            }
            .buttonStyle(ClioPrimaryButtonStyle())
            .disabled(!hasFoodToSave || isSaving)
            .opacity(hasFoodToSave && !isSaving ? 1.0 : 0.5)
        }
        .padding()
        .background(
            LinearGradient(
                colors: [ClioTheme.background.opacity(0), ClioTheme.background],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private func saveMeal() {
        guard !isSaving else { return }
        isSaving = true

        // Auto-add any text in the input field before saving
        var allFoodItems = foodItems
        let pendingItem = currentFoodInput.trimmingCharacters(in: .whitespacesAndNewlines)
        if !pendingItem.isEmpty && !allFoodItems.contains(pendingItem) {
            allFoodItems.append(pendingItem)
        }

        let meal = MealEntry(
            mealType: mealType.rawValue,
            foodItems: allFoodItems
        )

        // Use target date for past day logging
        meal.dateTime = targetDate

        // Set optional values
        let calValue = Int(calories)
        let protValue = Int(protein)
        let carbValue = Int(carbs)
        let fatValue = Int(fat)

        if let cal = calValue, cal > 0 {
            meal.calories = cal
        }
        if let prot = protValue, prot > 0 {
            meal.protein = prot
        }
        if let carb = carbValue, carb > 0 {
            meal.carbs = carb
        }
        if let fatVal = fatValue, fatVal > 0 {
            meal.fat = fatVal
        }

        meal.bodyResponses = selectedResponses.map { $0.rawValue }
        meal.specificFoodReaction = specificReaction.isEmpty ? nil : specificReaction
        meal.bodyResponseNotes = notes.isEmpty ? nil : notes

        // Set cycle context for target date
        meal.setCycleContext(phase: phaseForTargetDate, day: dayOfCycleForTargetDate)

        modelContext.insert(meal)

        // Save as template if requested
        if saveAsTemplate && !templateName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let savedMeal = SavedMeal(
                name: templateName.trimmingCharacters(in: .whitespacesAndNewlines),
                foodItems: allFoodItems,
                calories: calValue,
                protein: protValue,
                carbs: carbValue,
                fat: fatValue,
                mealType: mealType.rawValue,
                usageCount: 1,
                lastUsed: Date()
            )
            modelContext.insert(savedMeal)
        }

        try? modelContext.save()
        dismiss()
    }
}


// MARK: - Food Item Chip
struct FoodItemChip: View {
    let name: String
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            Text(name)
                .font(.subheadline)
                .foregroundStyle(ClioTheme.text)

            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(ClioTheme.textMuted)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(ClioTheme.eatColor.opacity(0.15))
        .clipShape(Capsule())
    }
}

// MARK: - Macro Input Field
struct MacroInputField: View {
    let label: String
    @Binding var value: String
    let unit: String

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                if value.isEmpty {
                    Text("—")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(ClioTheme.textMuted)
                }
                TextField("", text: $value)
                    .keyboardType(.numberPad)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(ClioTheme.text)
            }

            Text("\(label) (\(unit))")
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(ClioTheme.textMuted)
        }
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(ClioTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    AddMealView()
        .modelContainer(for: [UserSettings.self, MealEntry.self, SavedMeal.self], inMemory: true)
}
