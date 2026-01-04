import SwiftUI
import SwiftData

struct NourishmentLogView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var selectedMealType: MealEntry.MealType = .lunch
    @State private var descriptionText: String = ""
    @State private var selectedSensations: Set<MealEntry.Sensation> = []
    @State private var showDetails = false
    @State private var selectedPhotoData: Data?

    // Nutrition details (hidden by default)
    @State private var calories: String = ""
    @State private var protein: String = ""
    @State private var carbs: String = ""
    @State private var fat: String = ""

    var body: some View {
        NavigationStack {
            ZStack {
                ClioTheme.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Date header
                        VStack(spacing: 8) {
                            Text("Today, \(formattedDate)")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundStyle(ClioTheme.text)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 8)

                        // Meal type selector
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 0) {
                                ForEach(MealEntry.MealType.allCases) { type in
                                    Button {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            selectedMealType = type
                                        }
                                    } label: {
                                        Text(type.rawValue)
                                            .font(.subheadline)
                                            .fontWeight(selectedMealType == type ? .semibold : .medium)
                                            .foregroundStyle(selectedMealType == type ? ClioTheme.text : ClioTheme.textMuted)
                                            .padding(.vertical, 12)
                                            .padding(.horizontal, 20)
                                            .background(
                                                selectedMealType == type ? ClioTheme.mealColor.opacity(0.2) : Color.clear
                                            )
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(4)
                            .background(ClioTheme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }

                        // Photo capture
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Capture your meal")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundStyle(ClioTheme.text)

                            PhotoCapture(selectedImageData: $selectedPhotoData)
                        }

                        // Food description
                        VStack(alignment: .leading, spacing: 12) {
                            Text("What nourished you?")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundStyle(ClioTheme.text)

                            ZStack(alignment: .topLeading) {
                                if descriptionText.isEmpty {
                                    Text("Describe your meal, or let AI analyze your photo...")
                                        .foregroundStyle(ClioTheme.textMuted.opacity(0.6))
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 16)
                                }

                                TextEditor(text: $descriptionText)
                                    .scrollContentBackground(.hidden)
                                    .foregroundStyle(ClioTheme.text)
                                    .frame(minHeight: 100)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 12)
                            }
                            .background(ClioTheme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 16))

                            // Quick food suggestions
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(["Salad", "Sandwich", "Soup", "Rice bowl", "Pasta", "Smoothie"], id: \.self) { suggestion in
                                        Button {
                                            if descriptionText.isEmpty {
                                                descriptionText = suggestion
                                            } else {
                                                descriptionText += ", \(suggestion.lowercased())"
                                            }
                                        } label: {
                                            Text(suggestion)
                                                .font(.caption)
                                                .foregroundStyle(ClioTheme.textMuted)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 8)
                                                .background(ClioTheme.surface)
                                                .clipShape(Capsule())
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }

                        // Sensations
                        VStack(alignment: .leading, spacing: 12) {
                            Text("How did it feel?")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundStyle(ClioTheme.text)

                            SensationChipGroup(selectedSensations: $selectedSensations)
                        }

                        // Hidden Details section (calories/macros)
                        VStack(alignment: .leading, spacing: 12) {
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    showDetails.toggle()
                                }
                            } label: {
                                HStack {
                                    Text("Details")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundStyle(ClioTheme.textMuted)

                                    Image(systemName: showDetails ? "chevron.up" : "chevron.down")
                                        .font(.caption)
                                        .foregroundStyle(ClioTheme.textMuted)
                                }
                            }
                            .buttonStyle(.plain)

                            if showDetails {
                                VStack(spacing: 12) {
                                    Text("Optional nutrition context")
                                        .font(.caption)
                                        .foregroundStyle(ClioTheme.textMuted)
                                        .frame(maxWidth: .infinity, alignment: .leading)

                                    LazyVGrid(columns: [
                                        GridItem(.flexible()),
                                        GridItem(.flexible())
                                    ], spacing: 12) {
                                        NutritionField(label: "Calories", value: $calories, unit: "kcal")
                                        NutritionField(label: "Protein", value: $protein, unit: "g")
                                        NutritionField(label: "Carbs", value: $carbs, unit: "g")
                                        NutritionField(label: "Fat", value: $fat, unit: "g")
                                    }
                                }
                                .padding()
                                .background(ClioTheme.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                        }
                    }
                    .padding()
                    .padding(.bottom, 100)
                }
            }
            .safeAreaInset(edge: .bottom) {
                VStack {
                    Button {
                        saveMeal()
                    } label: {
                        HStack {
                            Image(systemName: "checkmark")
                            Text("Log Meal")
                        }
                    }
                    .buttonStyle(ClioPrimaryButtonStyle())
                    .disabled(descriptionText.isEmpty)
                    .opacity(descriptionText.isEmpty ? 0.5 : 1.0)
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
            .navigationTitle("Nourishment Log")
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
            .toolbarBackground(ClioTheme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: Date())
    }

    private func saveMeal() {
        let entry = MealEntry(
            mealType: selectedMealType.rawValue,
            descriptionText: descriptionText,
            sensationTags: selectedSensations.map { $0.rawValue },
            photoData: selectedPhotoData,
            calories: Int(calories),
            protein: Int(protein),
            carbs: Int(carbs),
            fat: Int(fat)
        )

        modelContext.insert(entry)

        do {
            try modelContext.save()
            HapticFeedback.success.trigger()
            dismiss()
        } catch {
            print("Failed to save meal: \(error)")
            HapticFeedback.error.trigger()
        }
    }
}

struct NutritionField: View {
    let label: String
    @Binding var value: String
    let unit: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption)
                .foregroundStyle(ClioTheme.textMuted)

            HStack(spacing: 4) {
                TextField("", text: $value)
                    .keyboardType(.numberPad)
                    .foregroundStyle(ClioTheme.text)
                    .font(.headline)

                Text(unit)
                    .font(.caption)
                    .foregroundStyle(ClioTheme.textMuted)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(ClioTheme.surfaceHighlight)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}

#Preview {
    NourishmentLogView()
        .modelContainer(for: [MealEntry.self], inMemory: true)
}
