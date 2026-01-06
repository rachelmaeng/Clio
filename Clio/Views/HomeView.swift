import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \UserSettings.createdAt, order: .reverse) private var settings: [UserSettings]
    @Query(sort: \FeelCheck.dateTime, order: .reverse) private var feelChecks: [FeelCheck]
    @Query(sort: \MovementEntry.dateTime, order: .reverse) private var movements: [MovementEntry]
    @Query(sort: \MealEntry.dateTime, order: .reverse) private var meals: [MealEntry]
    @Query(sort: \PersonalInsight.createdAt, order: .reverse) private var insights: [PersonalInsight]

    @State private var showFeelCheck = false
    @State private var showAddMeal = false
    @State private var showAddMovement = false
    @State private var showQuickLog = false
    @State private var selectedTip: PhaseTip?

    private var userSettings: UserSettings? {
        settings.first
    }

    private var currentPhase: CyclePhase {
        userSettings?.currentPhase ?? .follicular
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<21: return "Good evening"
        default: return "Good night"
        }
    }

    private var todayFeelCheck: FeelCheck? {
        let today = Calendar.current.startOfDay(for: Date())
        return feelChecks.first { Calendar.current.isDate($0.dateTime, inSameDayAs: today) }
    }

    private var todayMeals: [MealEntry] {
        let today = Calendar.current.startOfDay(for: Date())
        return meals.filter { Calendar.current.isDate($0.dateTime, inSameDayAs: today) }
    }

    private var todayMovements: [MovementEntry] {
        let today = Calendar.current.startOfDay(for: Date())
        return movements.filter { Calendar.current.isDate($0.dateTime, inSameDayAs: today) }
    }

    private var todayCalories: Int {
        todayMeals.compactMap { $0.calories }.reduce(0, +)
    }

    private var todayMinutes: Int {
        todayMovements.compactMap { $0.durationMinutes }.reduce(0, +)
    }

    private var newInsights: [PersonalInsight] {
        insights.filter { $0.isNew && !$0.hasBeenDismissed }.prefix(2).map { $0 }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ClioTheme.background
                    .withGrain(opacity: 0.025)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Phase Hero Illustration - full width, extends into safe area
                        PhaseHeroView(phase: currentPhase, height: 180)
                            .padding(.horizontal, -ClioTheme.spacing) // Break out of VStack padding
                            .fadeInFromBottom(delay: 0)

                        // Header with greeting
                        header
                            .fadeInFromBottom(delay: 0.05)

                        // Feel Check CTA or Summary
                        feelCheckSection
                            .fadeInFromBottom(delay: 0.1)

                        // Today's Summary
                        todaySummary
                            .fadeInFromBottom(delay: 0.2)

                        // New Insights (if any)
                        if !newInsights.isEmpty {
                            insightsPreview
                                .fadeInFromBottom(delay: 0.3)
                        }

                        // Phase Tips Preview
                        phaseTips
                            .fadeInFromBottom(delay: 0.4)
                    }
                    .padding(.horizontal, ClioTheme.spacing)
                    .padding(.bottom, 100)
                }
                .scrollContentBackground(.hidden)
                .ignoresSafeArea(edges: .top)
            }
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showFeelCheck) {
                FeelCheckView()
            }
            .sheet(isPresented: $showAddMeal) {
                AddMealView()
            }
            .sheet(isPresented: $showAddMovement) {
                AddMovementView()
            }
            .sheet(item: $selectedTip) { tip in
                HomeTipDetailSheet(tip: tip, phase: currentPhase)
            }
            .sheet(isPresented: $showQuickLog) {
                QuickDailyLogView()
            }
        }
    }

    // MARK: - Header
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(greeting)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(ClioTheme.text)

                // Day indicator
                if let day = userSettings?.dayOfCycle {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(ClioTheme.phaseColor(for: currentPhase))
                            .frame(width: 6, height: 6)

                        Text("Day \(day) of your cycle")
                            .font(.subheadline)
                            .foregroundStyle(ClioTheme.textMuted)
                    }
                }
            }

            Spacer()

            // Quick Log button
            Button {
                showQuickLog = true
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .bold))
                    Text("Log")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Capsule().fill(ClioTheme.primary))
            }
            .buttonStyle(ScaleButtonStyle())
        }
    }

    // MARK: - Feel Check Section
    @ViewBuilder
    private var feelCheckSection: some View {
        if let feelCheck = todayFeelCheck {
            // Show today's feel check summary
            HStack(spacing: 16) {
                // Energy indicator
                VStack(spacing: 4) {
                    ZStack {
                        Circle()
                            .fill(ClioTheme.feelColor.opacity(0.15))
                            .frame(width: 56, height: 56)

                        Text("\(feelCheck.energyLevel)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(ClioTheme.feelColor)
                    }

                    Text("Energy")
                        .font(.caption2)
                        .foregroundStyle(ClioTheme.textMuted)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Feeling \(feelCheck.overallFeeling.lowercased()) today")
                        .font(.headline)
                        .foregroundStyle(ClioTheme.text)

                    if !feelCheck.moods.isEmpty {
                        HStack(spacing: 4) {
                            ForEach(feelCheck.moods.prefix(3), id: \.self) { mood in
                                if let moodEnum = FeelCheck.Mood(rawValue: mood) {
                                    Image(systemName: moodEnum.icon)
                                        .font(.caption)
                                        .foregroundStyle(ClioTheme.textMuted)
                                }
                            }

                            if feelCheck.moods.count > 3 {
                                Text("+\(feelCheck.moods.count - 3)")
                                    .font(.caption)
                                    .foregroundStyle(ClioTheme.textMuted)
                            }
                        }
                    }
                }

                Spacer()

                Button {
                    showFeelCheck = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(ClioTheme.feelColor)
                }
            }
            .padding()
            .background(ClioTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        } else {
            // CTA to check in
            Button {
                showFeelCheck = true
            } label: {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(ClioTheme.feelColor.opacity(0.15))
                            .frame(width: 56, height: 56)

                        Image(systemName: "heart.circle.fill")
                            .font(.title2)
                            .foregroundStyle(ClioTheme.feelColor)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("How are you feeling?")
                            .font(.headline)
                            .foregroundStyle(ClioTheme.text)

                        Text("Take a moment to check in")
                            .font(.subheadline)
                            .foregroundStyle(ClioTheme.textMuted)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(ClioTheme.textMuted)
                }
                .padding()
                .background(
                    LinearGradient(
                        colors: [ClioTheme.feelColor.opacity(0.1), ClioTheme.surface],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(ClioTheme.feelColor.opacity(0.2), lineWidth: 1)
                )
            }
            .buttonStyle(TipChipButtonStyle())
        }
    }

    // MARK: - Today's Summary
    private var todaySummary: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Today")
                .font(.headline)
                .foregroundStyle(ClioTheme.text)

            HStack(spacing: 12) {
                // Nutrition summary
                Button {
                    showAddMeal = true
                } label: {
                    VStack(spacing: 12) {
                        Image(systemName: "fork.knife")
                            .font(.title3)
                            .foregroundStyle(ClioTheme.eatColor)

                        VStack(spacing: 2) {
                            if userSettings?.hasCalorieGoal == true {
                                Text("\(todayCalories)")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundStyle(ClioTheme.text)

                                Text("cal")
                                    .font(.caption)
                                    .foregroundStyle(ClioTheme.textMuted)
                            } else {
                                Text("\(todayMeals.count)")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundStyle(ClioTheme.text)

                                Text("meals")
                                    .font(.caption)
                                    .foregroundStyle(ClioTheme.textMuted)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, ClioTheme.spacing)
                    .padding(.vertical, 20)
                    .background(ClioTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(TipChipButtonStyle())

                // Movement summary
                Button {
                    showAddMovement = true
                } label: {
                    VStack(spacing: 12) {
                        Image(systemName: "figure.run")
                            .font(.title3)
                            .foregroundStyle(ClioTheme.moveColor)

                        VStack(spacing: 2) {
                            Text("\(todayMinutes)")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundStyle(ClioTheme.text)

                            Text("min")
                                .font(.caption)
                                .foregroundStyle(ClioTheme.textMuted)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, ClioTheme.spacing)
                    .padding(.vertical, 20)
                    .background(ClioTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(TipChipButtonStyle())

                // Calorie burn summary (if enabled)
                if userSettings?.showCalorieBurnEstimate == true {
                    let burnedCals = todayMovements.compactMap { $0.estimatedCaloriesBurned }.reduce(0, +)

                    VStack(spacing: 12) {
                        Image(systemName: "flame.fill")
                            .font(.title3)
                            .foregroundStyle(ClioTheme.terracotta)

                        VStack(spacing: 2) {
                            Text("\(burnedCals)")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundStyle(ClioTheme.text)

                            Text("burned")
                                .font(.caption)
                                .foregroundStyle(ClioTheme.textMuted)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, ClioTheme.spacing)
                    .padding(.vertical, 20)
                    .background(ClioTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
        }
    }

    // MARK: - Insights Preview
    private var insightsPreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("New for you")
                    .font(.headline)
                    .foregroundStyle(ClioTheme.text)

                Circle()
                    .fill(ClioTheme.primary)
                    .frame(width: 8, height: 8)

                Spacer()
            }

            ForEach(newInsights) { insight in
                HStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .font(.caption)
                        .foregroundStyle(ClioTheme.insightColor)

                    Text(insight.title)
                        .font(.subheadline)
                        .foregroundStyle(ClioTheme.text)
                        .lineLimit(2)

                    Spacer()
                }
                .padding()
                .background(ClioTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    // MARK: - Phase Tips
    private var phaseTips: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Suggested for \(currentPhase.description)")
                .font(.headline)
                .foregroundStyle(ClioTheme.text)

            // Food tips
            VStack(alignment: .leading, spacing: 8) {
                Text("Nourishment")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(ClioTheme.textMuted)
                    .textCase(.uppercase)
                    .tracking(0.5)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Array(PhaseTipDatabase.foodTips(for: currentPhase).prefix(4).enumerated()), id: \.element.id) { index, tip in
                            Button {
                                selectedTip = tip
                            } label: {
                                HomeTipCard(tip: tip, color: ClioTheme.eatColor)
                            }
                            .buttonStyle(TipChipButtonStyle())
                            .staggeredAppearance(index: index, delay: 0.05)
                        }
                    }
                }
            }

            // Movement tips
            VStack(alignment: .leading, spacing: 8) {
                Text("Movement")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(ClioTheme.textMuted)
                    .textCase(.uppercase)
                    .tracking(0.5)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Array(PhaseTipDatabase.movementTips(for: currentPhase).prefix(4).enumerated()), id: \.element.id) { index, tip in
                            Button {
                                selectedTip = tip
                            } label: {
                                HomeTipCard(tip: tip, color: ClioTheme.moveColor)
                            }
                            .buttonStyle(TipChipButtonStyle())
                            .staggeredAppearance(index: index, delay: 0.05)
                        }
                    }
                }
            }
        }
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: Date())
    }
}

// MARK: - Home Tip Card
struct HomeTipCard: View {
    let tip: PhaseTip
    let color: Color // Base color (used as fallback)

    // Food category colors
    private static let vegGreen = Color(hex: "6B9B7A")
    private static let fishPink = Color(hex: "D4A090")
    private static let grainAmber = Color(hex: "C8A060")
    private static let fruitCoral = Color(hex: "E8A090")
    private static let meatBrown = Color(hex: "A08070")
    private static let drinkTeal = Color(hex: "7A9EB0")
    private static let comfortRose = Color(hex: "C89898")

    // Movement category colors
    private static let cardioTeal = Color(hex: "4A7070")
    private static let yogaSage = Color(hex: "6B9B7A")
    private static let waterBlue = Color(hex: "7A9EB0")
    private static let strengthBrown = Color(hex: "A08070")
    private static let restRose = Color(hex: "C89898")

    private var accentColor: Color {
        let name = tip.name.lowercased()

        if tip.category == .eat {
            // Food categories
            if name.contains("spinach") || name.contains("leafy") || name.contains("broccoli") ||
               name.contains("sprout") || name.contains("cruciferous") || name.contains("avocado") {
                return Self.vegGreen
            }
            if name.contains("salmon") || name.contains("fish") {
                return Self.fishPink
            }
            if name.contains("chicken") || name.contains("turkey") || name.contains("meat") ||
               name.contains("protein") || name.contains("egg") {
                return Self.meatBrown
            }
            if name.contains("oat") || name.contains("quinoa") || name.contains("grain") ||
               name.contains("lentil") || name.contains("chickpea") || name.contains("seed") {
                return Self.grainAmber
            }
            if name.contains("citrus") || name.contains("berr") || name.contains("banana") ||
               name.contains("fruit") {
                return Self.fruitCoral
            }
            if name.contains("tea") || name.contains("soup") || name.contains("fermented") {
                return Self.drinkTeal
            }
            if name.contains("chocolate") || name.contains("almond") || name.contains("ginger") ||
               name.contains("beetroot") || name.contains("root") || name.contains("sweet potato") {
                return Self.comfortRose
            }
        } else {
            // Movement categories
            if name.contains("yoga") || name.contains("stretch") || name.contains("pilates") {
                return Self.yogaSage
            }
            if name.contains("cardio") || name.contains("run") || name.contains("hiit") ||
               name.contains("spinning") || name.contains("speed") {
                return Self.cardioTeal
            }
            if name.contains("swim") || name.contains("water") {
                return Self.waterBlue
            }
            if name.contains("strength") || name.contains("lift") || name.contains("power") ||
               name.contains("heavy") || name.contains("group") {
                return Self.strengthBrown
            }
            if name.contains("rest") || name.contains("walk") || name.contains("gentle") {
                return Self.restRose
            }
        }
        return color
    }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: tip.icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 24, height: 16)
                    .foregroundStyle(accentColor)
            }

            Text(tip.name)
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
}

// MARK: - Home Tip Detail Sheet
struct HomeTipDetailSheet: View {
    let tip: PhaseTip
    let phase: CyclePhase
    @Environment(\.dismiss) private var dismiss
    @State private var showAddMeal = false
    @State private var showAddMovement = false

    private var accentColor: Color {
        tip.category == .eat ? ClioTheme.eatColor : ClioTheme.moveColor
    }

    private var relatedTips: [PhaseTip] {
        let tips = tip.category == .eat
            ? PhaseTipDatabase.foodTips(for: phase)
            : PhaseTipDatabase.movementTips(for: phase)
        return tips.filter { $0.id != tip.id }.prefix(3).map { $0 }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ClioTheme.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Header
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(accentColor.opacity(0.15))
                                    .frame(width: 72, height: 72)

                                Image(systemName: tip.icon)
                                    .font(.system(size: 28, weight: .medium))
                                    .frame(width: 36, height: 36)
                                    .foregroundStyle(accentColor)
                            }

                            Text(tip.name)
                                .font(ClioTheme.headingFont(22))
                                .foregroundStyle(ClioTheme.text)

                            HStack(spacing: 6) {
                                Circle()
                                    .fill(ClioTheme.phaseColor(for: phase))
                                    .frame(width: 6, height: 6)

                                Text("Great for \(phase.description.lowercased())")
                                    .font(ClioTheme.captionFont(13))
                                    .foregroundStyle(ClioTheme.textMuted)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 8)

                        // Quick ideas chips
                        if !tip.howToEnjoy.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Quick ideas")
                                    .font(ClioTheme.captionFont(12))
                                    .fontWeight(.medium)
                                    .foregroundStyle(ClioTheme.textMuted)
                                    .textCase(.uppercase)
                                    .tracking(0.5)

                                FlowLayout(spacing: 8) {
                                    ForEach(tip.howToEnjoy.prefix(4), id: \.self) { idea in
                                        Text(idea)
                                            .font(ClioTheme.captionFont(13))
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(ClioTheme.surfaceHighlight)
                                            .foregroundStyle(ClioTheme.text)
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                        }

                        // Why it's good - more compact
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Why it helps")
                                .font(ClioTheme.subheadingFont(15))
                                .foregroundStyle(ClioTheme.text)

                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(tip.whyBenefits.prefix(3), id: \.self) { benefit in
                                    HStack(alignment: .top, spacing: 10) {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundStyle(accentColor)
                                            .padding(.top, 4)

                                        Text(benefit)
                                            .font(ClioTheme.bodyFont(14))
                                            .foregroundStyle(ClioTheme.text)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                }
                            }
                            .padding(ClioTheme.spacing)
                            .background(ClioTheme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: ClioTheme.cornerRadiusSmall))
                        }

                        // Related items
                        if !relatedTips.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("More for \(phase.description.lowercased())")
                                    .font(ClioTheme.captionFont(12))
                                    .fontWeight(.medium)
                                    .foregroundStyle(ClioTheme.textMuted)
                                    .textCase(.uppercase)
                                    .tracking(0.5)

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 10) {
                                        ForEach(relatedTips) { related in
                                            relatedTipChip(related)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    .padding(.bottom, 100)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    ClioCloseButton { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                logActionButton
            }
            .sheet(isPresented: $showAddMeal) {
                AddMealView()
            }
            .sheet(isPresented: $showAddMovement) {
                AddMovementView()
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func relatedTipChip(_ related: PhaseTip) -> some View {
        HStack(spacing: 8) {
            Image(systemName: related.icon)
                .font(.system(size: 14))
                .foregroundStyle(accentColor)

            Text(related.name)
                .font(ClioTheme.captionFont(13))
                .foregroundStyle(ClioTheme.text)
                .lineLimit(1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(ClioTheme.surface)
        .clipShape(Capsule())
    }

    private var logActionButton: some View {
        Button {
            if tip.category == .eat {
                showAddMeal = true
            } else {
                showAddMovement = true
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .semibold))
                Text(tip.category == .eat ? "Log this meal" : "Log this workout")
            }
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

#Preview {
    HomeView()
        .modelContainer(for: [UserSettings.self, FeelCheck.self, MovementEntry.self, MealEntry.self, PersonalInsight.self], inMemory: true)
}
