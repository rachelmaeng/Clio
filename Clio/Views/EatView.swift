import SwiftUI
import SwiftData

// Wrapper for sheet presentation to capture prefilled tip correctly
struct AddMealSheetItem: Identifiable {
    let id = UUID()
    let prefilledTip: PhaseTip?
    let preselectedMealType: MealEntry.MealType?
}

struct EatView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \UserSettings.createdAt, order: .reverse) private var settings: [UserSettings]
    @Query(sort: \MealEntry.dateTime, order: .reverse) private var meals: [MealEntry]

    @State private var addMealSheet: AddMealSheetItem? = nil
    @State private var mealToEdit: MealEntry?
    @State private var isTipsSectionExpanded: Bool = false

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
                // Background layer to prevent white flash
                ClioTheme.background
                    .withGrain(opacity: 0.025)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: ClioTheme.spacingLarge) {
                        // Illustration hero - full width, extends into safe area
                        // No fadeInFromBottom on hero to prevent white flash
                        eatHero
                            .padding(.horizontal, -ClioTheme.spacing) // Break out of VStack padding

                        // Header with phase context
                        phaseHeader
                            .fadeInFromBottom(delay: 0.05)

                        // Quick log by meal type (2x2 grid)
                        mealTypeGrid
                            .fadeInFromBottom(delay: 0.1)

                        // Today's Log Section (only if meals exist)
                        if !todayMeals.isEmpty {
                            todayLogSection
                                .fadeInFromBottom(delay: 0.15)
                        }

                        // Phase Tips Grid
                        tipsSection
                            .fadeInFromBottom(delay: 0.2)
                    }
                    .padding(.horizontal, ClioTheme.spacing)
                    .padding(.bottom, 100)
                }
                .scrollContentBackground(.hidden)
                .ignoresSafeArea(edges: .top)

                // Custom add button overlay
                VStack {
                    HStack {
                        Spacer()
                        Button {
                            addMealSheet = AddMealSheetItem(prefilledTip: nil, preselectedMealType: nil)
                        } label: {
                            Image(systemName: "plus")
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(ClioTheme.eatColor)
                                .frame(width: 44, height: 44)
                                .background(ClioTheme.surface.opacity(0.9))
                                .clipShape(Circle())
                        }
                        .padding(.trailing, ClioTheme.spacing)
                    }
                    .padding(.top, 60)
                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $addMealSheet) { item in
                AddMealView(prefilledTip: item.prefilledTip, preselectedMealType: item.preselectedMealType)
            }
            .sheet(item: $mealToEdit) { meal in
                EditMealView(meal: meal)
            }
        }
    }

    // MARK: - Eat Hero Illustration
    private var eatHero: some View {
        ZStack(alignment: .bottomLeading) {
            // Solid background to prevent any flash
            ClioTheme.background
                .frame(height: 380)

            // Full illustration - aligned to BOTTOM to show person
            loadBundleImage("eating-healthy")
                .resizable()
                .scaledToFill()
                .frame(height: 380, alignment: .bottom)
                .clipped()
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
                    MealLogRow(meal: meal) {
                        mealToEdit = meal
                    }
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

    // MARK: - Meal Type Grid (2x2)
    private var mealTypeGrid: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Quick log")
                    .font(.headline)
                    .foregroundStyle(ClioTheme.text)

                Text("Tap to start logging")
                    .font(.caption)
                    .foregroundStyle(ClioTheme.textMuted)
            }

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                ForEach(MealEntry.MealType.allCases) { type in
                    MealTypeTile(mealType: type) {
                        addMealSheet = AddMealSheetItem(prefilledTip: nil, preselectedMealType: type)
                    }
                }
            }
        }
    }

    // MARK: - Tips Section (Collapsible)
    private var tipsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Collapsible header
            Button {
                withAnimation(.clioQuick) {
                    isTipsSectionExpanded.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: isTipsSectionExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(ClioTheme.textMuted)

                    Text("Suggestions for this phase")
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

            // Expanded content
            if isTipsSectionExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Tap any to add to a meal")
                        .font(.caption)
                        .foregroundStyle(ClioTheme.textMuted)
                        .padding(.horizontal, 4)

                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12)
                    ], spacing: 12) {
                        ForEach(Array(PhaseTipDatabase.foodTips(for: currentPhase).enumerated()), id: \.element.id) { index, tip in
                            TipChip(tip: tip, colorIndex: index) {
                                // Open AddMealView with this food pre-filled
                                addMealSheet = AddMealSheetItem(prefilledTip: tip, preselectedMealType: nil)
                            }
                            .staggeredAppearance(index: index, delay: 0.03)
                        }
                    }
                }
            }
        }
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
    var onTap: (() -> Void)? = nil

    var body: some View {
        Button {
            onTap?()
        } label: {
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
                        // Show meal type label instead of time
                        Text(meal.mealType)
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

                // Body response indicator or edit chevron
                if meal.hasBodyResponse {
                    let positive = meal.bodyResponses.compactMap { MealEntry.BodyResponse(rawValue: $0) }.filter { $0.isPositive }.count
                    let total = meal.bodyResponses.count

                    Circle()
                        .fill(positive > total / 2 ? ClioTheme.success : ClioTheme.neutral)
                        .frame(width: 8, height: 8)
                } else if onTap != nil {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(ClioTheme.textMuted)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Meal Type Tile
struct MealTypeTile: View {
    let mealType: MealEntry.MealType
    let action: () -> Void

    private var tileColor: Color {
        switch mealType {
        case .breakfast: return Color(hex: "C8A060")  // Warm amber
        case .lunch: return Color(hex: "6B9B7A")      // Sage green
        case .dinner: return Color(hex: "7A9EB0")     // Soft blue
        case .snack: return Color(hex: "D4A090")      // Soft coral
        }
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(tileColor.opacity(0.15))
                        .frame(width: 52, height: 52)

                    Image(systemName: mealType.icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(tileColor)
                }

                VStack(spacing: 3) {
                    Text(mealType.rawValue)
                        .font(ClioTheme.subheadingFont())
                        .foregroundStyle(ClioTheme.text)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .padding(.horizontal, ClioTheme.spacing)
            .background(ClioTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(TipChipButtonStyle())
    }
}

#Preview {
    EatView()
        .modelContainer(for: [UserSettings.self, MealEntry.self], inMemory: true)
}
