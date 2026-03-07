import SwiftUI
import SwiftData

struct EditMealView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \UserSettings.createdAt, order: .reverse) private var settings: [UserSettings]

    let meal: MealEntry

    @State private var mealType: MealEntry.MealType
    @State private var foodItems: [String]
    @State private var currentFoodInput = ""
    @State private var calories: String
    @State private var protein: String
    @State private var carbs: String
    @State private var fat: String
    @State private var notes: String
    @State private var selectedResponses: Set<MealEntry.BodyResponse>
    @State private var specificReaction: String

    @State private var showDeleteConfirm = false

    private var userSettings: UserSettings? {
        settings.first
    }

    init(meal: MealEntry) {
        self.meal = meal
        _mealType = State(initialValue: MealEntry.MealType(rawValue: meal.mealType) ?? .lunch)
        _foodItems = State(initialValue: meal.foodItems)
        _calories = State(initialValue: meal.calories.map { String($0) } ?? "")
        _protein = State(initialValue: meal.protein.map { String($0) } ?? "")
        _carbs = State(initialValue: meal.carbs.map { String($0) } ?? "")
        _fat = State(initialValue: meal.fat.map { String($0) } ?? "")
        _notes = State(initialValue: meal.bodyResponseNotes ?? "")
        _selectedResponses = State(initialValue: Set(meal.bodyResponses.compactMap { MealEntry.BodyResponse(rawValue: $0) }))
        _specificReaction = State(initialValue: meal.specificFoodReaction ?? "")
    }

    // Check if we have food to save
    private var hasFoodToSave: Bool {
        !foodItems.isEmpty || !currentFoodInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
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

                        // Body Response
                        bodyResponseSection
                            .fadeInFromBottom(delay: 0.4)

                        // Notes
                        notesSection
                            .fadeInFromBottom(delay: 0.5)

                        // Delete button
                        deleteSection
                            .fadeInFromBottom(delay: 0.6)
                    }
                    .padding()
                    .padding(.bottom, 120)
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
            .alert("Delete Meal?", isPresented: $showDeleteConfirm) {
                Button("Delete", role: .destructive) {
                    deleteMeal()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This meal will be permanently deleted.")
            }
        }
    }

    // MARK: - Header
    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Edit meal")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundStyle(ClioTheme.text)

            Text(formatDate(meal.dateTime))
                .font(.subheadline)
                .foregroundStyle(ClioTheme.textMuted)
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: date)
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
            VStack(alignment: .leading, spacing: 4) {
                Text("What did you eat?")
                    .font(.headline)
                    .foregroundStyle(ClioTheme.text)

                Text("Add each food item separately")
                    .font(.caption)
                    .foregroundStyle(ClioTheme.textMuted)
            }

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

                // Added food items
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

    // MARK: - Delete Section
    private var deleteSection: some View {
        Button {
            showDeleteConfirm = true
        } label: {
            HStack {
                Image(systemName: "trash")
                Text("Delete meal")
            }
            .font(.subheadline)
            .foregroundStyle(ClioTheme.terracotta)
            .frame(maxWidth: .infinity)
            .padding()
            .background(ClioTheme.terracotta.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
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
                Text("Save changes")
            }
            .buttonStyle(ClioPrimaryButtonStyle())
            .disabled(!hasFoodToSave)
            .opacity(hasFoodToSave ? 1.0 : 0.5)
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
        // Auto-add any text in the input field before saving
        var allFoodItems = foodItems
        let pendingItem = currentFoodInput.trimmingCharacters(in: .whitespacesAndNewlines)
        if !pendingItem.isEmpty && !allFoodItems.contains(pendingItem) {
            allFoodItems.append(pendingItem)
        }

        // Update meal properties
        meal.mealType = mealType.rawValue
        meal.foodItems = allFoodItems

        // Set optional values
        let calValue = Int(calories)
        let protValue = Int(protein)
        let carbValue = Int(carbs)
        let fatValue = Int(fat)

        meal.calories = (calValue ?? 0) > 0 ? calValue : nil
        meal.protein = (protValue ?? 0) > 0 ? protValue : nil
        meal.carbs = (carbValue ?? 0) > 0 ? carbValue : nil
        meal.fat = (fatValue ?? 0) > 0 ? fatValue : nil

        meal.bodyResponses = selectedResponses.map { $0.rawValue }
        meal.specificFoodReaction = specificReaction.isEmpty ? nil : specificReaction
        meal.bodyResponseNotes = notes.isEmpty ? nil : notes

        try? modelContext.save()
        dismiss()
    }

    private func deleteMeal() {
        modelContext.delete(meal)
        try? modelContext.save()
        dismiss()
    }
}
