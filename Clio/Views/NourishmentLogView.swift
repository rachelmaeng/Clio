import SwiftUI
import SwiftData

struct NourishmentLogView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var selectedMealType: MealEntry.MealType = .lunch
    @State private var descriptionText: String = ""
    @State private var selectedSensations: Set<MealEntry.Sensation> = []
    @State private var showDetails = false

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
                                                selectedMealType == type ? ClioTheme.background : Color.clear
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

                        // Food description
                        VStack(alignment: .leading, spacing: 12) {
                            Text("What nourished you?")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundStyle(ClioTheme.text)

                            ZStack(alignment: .topLeading) {
                                if descriptionText.isEmpty {
                                    Text("Warm grain bowl with avocado, seeds, and lemon tahini dressing...")
                                        .foregroundStyle(ClioTheme.textMuted.opacity(0.6))
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 16)
                                }

                                TextEditor(text: $descriptionText)
                                    .scrollContentBackground(.hidden)
                                    .foregroundStyle(ClioTheme.text)
                                    .frame(minHeight: 140)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 12)
                            }
                            .background(ClioTheme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(alignment: .bottomTrailing) {
                                HStack(spacing: 8) {
                                    Button {
                                        // Photo action
                                    } label: {
                                        Image(systemName: "camera.fill")
                                            .foregroundStyle(ClioTheme.textMuted)
                                            .padding(8)
                                    }

                                    Button {
                                        // Voice action
                                    } label: {
                                        Image(systemName: "mic.fill")
                                            .foregroundStyle(ClioTheme.textMuted)
                                            .padding(8)
                                    }
                                }
                                .padding(8)
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
            calories: Int(calories),
            protein: Int(protein),
            carbs: Int(carbs),
            fat: Int(fat)
        )

        modelContext.insert(entry)

        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Failed to save meal: \(error)")
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
