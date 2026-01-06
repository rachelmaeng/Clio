import SwiftUI
import SwiftData

struct EatView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \UserSettings.createdAt, order: .reverse) private var settings: [UserSettings]
    @Query(sort: \MealEntry.dateTime, order: .reverse) private var meals: [MealEntry]

    @State private var showAddMeal = false
    @State private var selectedTip: PhaseTip?

    private var userSettings: UserSettings? {
        settings.first
    }

    private var currentPhase: CyclePhase {
        userSettings?.currentPhase ?? .follicular
    }

    private var todayMeals: [MealEntry] {
        let today = Calendar.current.startOfDay(for: Date())
        return meals.filter { Calendar.current.isDate($0.dateTime, inSameDayAs: today) }
    }

    private var todayCalories: Int {
        todayMeals.compactMap { $0.calories }.reduce(0, +)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ClioTheme.background
                    .withGrain(opacity: 0.02)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: ClioTheme.spacingLarge) {
                        // Illustration hero - full width, extends into safe area
                        eatHero
                            .padding(.horizontal, -ClioTheme.spacing) // Break out of VStack padding
                            .fadeInFromBottom(delay: 0)

                        // Header with phase context
                        phaseHeader
                            .fadeInFromBottom(delay: 0.05)

                        // Today's Log Section
                        if !todayMeals.isEmpty {
                            todayLogSection
                                .fadeInFromBottom(delay: 0.1)
                        }

                        // Phase Tips Grid
                        tipsSection
                            .fadeInFromBottom(delay: 0.2)
                    }
                    .padding(.horizontal, ClioTheme.spacing)
                    .padding(.bottom, 100)
                }
                .ignoresSafeArea(edges: .top)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddMeal = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(ClioTheme.eatColor)
                    }
                }
            }
            .sheet(isPresented: $showAddMeal) {
                AddMealView()
            }
            .sheet(item: $selectedTip) { tip in
                TipDetailSheet(tip: tip, onLog: {
                    logFromTip(tip)
                })
            }
        }
    }

    // MARK: - Eat Hero Illustration
    private var eatHero: some View {
        ZStack(alignment: .bottomLeading) {
            // Full illustration - extends to top edge
            loadBundleImage("eating-healthy")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .overlay(
                    GrainTexture(opacity: 0.05)
                        .blendMode(.overlay)
                )

            // Bottom fade into background
            LinearGradient(
                colors: [
                    ClioTheme.background,
                    ClioTheme.background.opacity(0.9),
                    ClioTheme.background.opacity(0.0)
                ],
                startPoint: .bottom,
                endPoint: .top
            )
            .frame(height: 120)
            .frame(maxHeight: .infinity, alignment: .bottom)

            // Text overlaid - more visible
            VStack(alignment: .leading, spacing: 4) {
                Text("Nourishment")
                    .font(ClioTheme.headingFont(22))
                    .foregroundStyle(ClioTheme.text)

                Text("Listen to what your body needs")
                    .font(ClioTheme.captionFont(13))
                    .foregroundStyle(ClioTheme.textMuted)
            }
            .padding(.horizontal, ClioTheme.spacing)
            .padding(.bottom, ClioTheme.spacingSmall)
        }
    }

    // Helper to load bundle images
    private func loadBundleImage(_ name: String) -> Image {
        if let uiImage = UIImage(named: name) {
            return Image(uiImage: uiImage)
        } else if let path = Bundle.main.path(forResource: name, ofType: "png"),
                  let uiImage = UIImage(contentsOfFile: path) {
            return Image(uiImage: uiImage)
        }
        return Image(systemName: "photo")
    }

    // MARK: - Phase Header
    private var phaseHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                // Calorie summary if they have goal
                if userSettings?.hasCalorieGoal == true, let range = userSettings?.calorieRangeText {
                    HStack(spacing: 4) {
                        Text("\(todayCalories)")
                            .font(ClioTheme.headingFont(24))
                            .foregroundStyle(ClioTheme.text)

                        Text("of \(range) cal")
                            .font(ClioTheme.captionFont())
                            .foregroundStyle(ClioTheme.textMuted)
                    }
                }

                // Phase context - subtle
                HStack(spacing: 6) {
                    Circle()
                        .fill(ClioTheme.phaseColor(for: currentPhase))
                        .frame(width: 6, height: 6)

                    Text("\(currentPhase.description)")
                        .font(ClioTheme.captionFont(12))
                        .foregroundStyle(ClioTheme.textMuted)
                }
            }

            Spacer()
        }
    }

    // MARK: - Today's Log Section
    private var todayLogSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Today")
                    .font(.headline)
                    .foregroundStyle(ClioTheme.text)

                Spacer()

                Text("\(todayMeals.count) meal\(todayMeals.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(ClioTheme.textMuted)
            }

            VStack(spacing: 8) {
                ForEach(todayMeals.prefix(3), id: \.id) { meal in
                    MealLogRow(meal: meal)
                }

                if todayMeals.count > 3 {
                    Button {
                        // Show all meals
                    } label: {
                        Text("View all \(todayMeals.count) meals")
                            .font(.subheadline)
                            .foregroundStyle(ClioTheme.eatColor)
                    }
                }
            }
            .padding()
            .background(ClioTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    // MARK: - Tips Section
    private var tipsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Foods for \(currentPhase.description)")
                .font(.headline)
                .foregroundStyle(ClioTheme.text)

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                ForEach(Array(PhaseTipDatabase.foodTips(for: currentPhase).enumerated()), id: \.element.id) { index, tip in
                    TipChip(tip: tip, colorIndex: index) {
                        selectedTip = tip
                    }
                    .staggeredAppearance(index: index, delay: 0.03)
                }
            }

            // Add custom food button
            Button {
                showAddMeal = true
            } label: {
                HStack {
                    Image(systemName: "plus")
                        .font(.caption)
                    Text("Log something else")
                        .font(.subheadline)
                }
                .foregroundStyle(ClioTheme.textMuted)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(ClioTheme.surface.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    // MARK: - Log from Tip
    private func logFromTip(_ tip: PhaseTip) {
        let meal = MealEntry(
            mealType: MealEntry.MealType.snack.rawValue,
            foodItems: [tip.name],
            fromTipId: tip.id
        )

        if let phase = userSettings?.currentPhase,
           let day = userSettings?.dayOfCycle {
            meal.setCycleContext(phase: phase, day: day)
        }

        modelContext.insert(meal)
        try? modelContext.save()

        selectedTip = nil
    }
}

// MARK: - Tip Chip
struct TipChip: View {
    let tip: PhaseTip
    var colorIndex: Int = 0
    let action: () -> Void

    // Food category colors - derived from eating-healthy illustration palette
    // Green (vegetables) - from the girl's green shirt
    private static let vegGreen = Color(hex: "6B9B7A")
    // Salmon pink (fish/seafood)
    private static let fishPink = Color(hex: "D4A090")
    // Warm amber (grains/carbs)
    private static let grainAmber = Color(hex: "C8A060")
    // Soft coral (fruits)
    private static let fruitCoral = Color(hex: "E8A090")
    // Earthy brown (meat/protein)
    private static let meatBrown = Color(hex: "A08070")
    // Soft teal (drinks/liquids)
    private static let drinkTeal = Color(hex: "7A9EB0")
    // Deep rose (comfort foods)
    private static let comfortRose = Color(hex: "C89898")

    private var accentColor: Color {
        let name = tip.name.lowercased()

        // Vegetables - green
        if name.contains("spinach") || name.contains("leafy") || name.contains("broccoli") ||
           name.contains("sprout") || name.contains("cruciferous") || name.contains("avocado") ||
           name.contains("vegetable") {
            return Self.vegGreen
        }
        // Fish/seafood - salmon pink
        if name.contains("salmon") || name.contains("fish") {
            return Self.fishPink
        }
        // Meat/protein - earthy brown
        if name.contains("chicken") || name.contains("turkey") || name.contains("meat") ||
           name.contains("protein") || name.contains("egg") {
            return Self.meatBrown
        }
        // Grains/carbs - warm amber
        if name.contains("oat") || name.contains("quinoa") || name.contains("grain") ||
           name.contains("lentil") || name.contains("chickpea") || name.contains("seed") {
            return Self.grainAmber
        }
        // Fruits - soft coral
        if name.contains("citrus") || name.contains("berr") || name.contains("banana") ||
           name.contains("fruit") || name.contains("water-rich") {
            return Self.fruitCoral
        }
        // Drinks - soft teal
        if name.contains("tea") || name.contains("soup") || name.contains("fermented") {
            return Self.drinkTeal
        }
        // Comfort foods - deep rose
        if name.contains("chocolate") || name.contains("almond") || name.contains("ginger") ||
           name.contains("spice") || name.contains("beetroot") || name.contains("root") ||
           name.contains("sweet potato") || name.contains("fat") {
            return Self.comfortRose
        }
        // Default fallback
        return ClioTheme.eatColor
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(accentColor.opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: tip.icon)
                        .font(.system(size: 18, weight: .medium))
                        .frame(width: 24, height: 24)
                        .minimumScaleFactor(0.5)
                        .foregroundStyle(accentColor)
                }

                Text(tip.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(ClioTheme.text)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(ClioTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(TipChipButtonStyle())
    }
}

struct TipChipButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.clioQuick, value: configuration.isPressed)
    }
}

// MARK: - Meal Log Row
struct MealLogRow: View {
    let meal: MealEntry

    var body: some View {
        HStack(spacing: 12) {
            // Meal type icon
            ZStack {
                Circle()
                    .fill(ClioTheme.eatColor.opacity(0.15))
                    .frame(width: 36, height: 36)

                Image(systemName: meal.meal?.icon ?? "fork.knife")
                    .font(.system(size: 14))
                    .foregroundStyle(ClioTheme.eatColor)
            }

            // Meal info
            VStack(alignment: .leading, spacing: 2) {
                Text(meal.foodItems.isEmpty ? meal.mealType : meal.foodItems.joined(separator: ", "))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(ClioTheme.text)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Text(formatTime(meal.dateTime))
                        .font(.caption)
                        .foregroundStyle(ClioTheme.textMuted)

                    if let calories = meal.calories {
                        Text("·")
                            .foregroundStyle(ClioTheme.textMuted)
                        Text("\(calories) cal")
                            .font(.caption)
                            .foregroundStyle(ClioTheme.textMuted)
                    }
                }
            }

            Spacer()

            // Body response indicator
            if meal.hasBodyResponse {
                let positive = meal.bodyResponses.compactMap { MealEntry.BodyResponse(rawValue: $0) }.filter { $0.isPositive }.count
                let total = meal.bodyResponses.count

                Circle()
                    .fill(positive > total / 2 ? ClioTheme.success : ClioTheme.neutral)
                    .frame(width: 8, height: 8)
            }
        }
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

// MARK: - Tip Detail Sheet
struct TipDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    let tip: PhaseTip
    let onLog: () -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                ClioTheme.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Header
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(ClioTheme.eatColor.opacity(0.15))
                                    .frame(width: 80, height: 80)

                                Image(systemName: tip.icon)
                                    .font(.system(size: 32, weight: .medium))
                                    .frame(width: 40, height: 40)
                                    .foregroundStyle(ClioTheme.eatColor)
                            }

                            Text(tip.name)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(ClioTheme.text)

                            Text(tip.phase.description)
                                .font(.caption)
                                .foregroundStyle(ClioTheme.textMuted)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(ClioTheme.surface)
                                .clipShape(Capsule())
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top)

                        // Why Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Why")
                                .font(.headline)
                                .foregroundStyle(ClioTheme.text)

                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(tip.whyBenefits, id: \.self) { benefit in
                                    HStack(alignment: .top, spacing: 8) {
                                        Circle()
                                            .fill(ClioTheme.eatColor)
                                            .frame(width: 6, height: 6)
                                            .padding(.top, 6)

                                        Text(benefit)
                                            .font(.subheadline)
                                            .foregroundStyle(ClioTheme.textMuted)
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(ClioTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                        // How Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("How to enjoy")
                                .font(.headline)
                                .foregroundStyle(ClioTheme.text)

                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(tip.howToEnjoy, id: \.self) { how in
                                    HStack(alignment: .top, spacing: 8) {
                                        Image(systemName: "checkmark")
                                            .font(.caption)
                                            .foregroundStyle(ClioTheme.success)
                                            .padding(.top, 2)

                                        Text(how)
                                            .font(.subheadline)
                                            .foregroundStyle(ClioTheme.textMuted)
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(ClioTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .padding()
                    .padding(.bottom, 100)
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
                Button {
                    onLog()
                } label: {
                    Text("I ate this today")
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
        }
    }
}

#Preview {
    EatView()
        .modelContainer(for: [UserSettings.self, MealEntry.self], inMemory: true)
}
