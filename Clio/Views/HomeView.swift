import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \UserSettings.createdAt, order: .reverse) private var settings: [UserSettings]
    @Query(sort: \FeelCheck.dateTime, order: .reverse) private var feelChecks: [FeelCheck]
    @Query(sort: \MovementEntry.dateTime, order: .reverse) private var movements: [MovementEntry]
    @Query(sort: \MealEntry.dateTime, order: .reverse) private var meals: [MealEntry]
    @Query(sort: \PersonalInsight.confidenceScore, order: .reverse) private var insights: [PersonalInsight]

    @Binding var selectedTab: MainTabView.Tab

    @State private var showFeelCheck = false
    @State private var showAddMeal = false
    @State private var showAddMovement = false
    @State private var showQuickLog = false

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

    private var todayMinutes: Int {
        todayMovements.compactMap { $0.durationMinutes }.reduce(0, +)
    }

    /// Top high-confidence insight (70%+) for the home screen card — only shown when checked in
    private var topInsight: PersonalInsight? {
        guard todayFeelCheck != nil else { return nil }
        return insights.first { !$0.hasBeenDismissed && $0.confidenceScore >= 0.70 }
    }

    /// Movement summary text for today card
    private var movementSummaryText: String? {
        guard let first = todayMovements.first else { return nil }
        let type = first.movementType?.rawValue ?? first.type
        if let mins = first.durationMinutes {
            return "\(type) · \(mins) min"
        }
        return type
    }

    /// Meal types logged today (e.g., "Lunch, Snack")
    private var mealTypesSummary: String {
        let types = todayMeals.compactMap { $0.meal?.rawValue }
        let unique = Array(Set(types))
        return unique.joined(separator: ", ")
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Phase Hero - at very top, edge to edge (matches Eat/Move tabs)
                    homeHero
                        .padding(.horizontal, -ClioTheme.spacing) // Break out of VStack padding

                    // Feel Check CTA or compact summary
                    feelCheckSection
                        .fadeInFromBottom(delay: 0.1)

                    // Today's Summary (always visible with empty states)
                    todaySummary
                        .fadeInFromBottom(delay: 0.15)

                    // Insight card (only when checked in + 70%+ confidence)
                    if let insight = topInsight {
                        insightCard(insight)
                            .fadeInFromBottom(delay: 0.2)
                    }
                }
                .padding(.horizontal, ClioTheme.spacing)
            }
            .scrollIndicators(.hidden)
            .ignoresSafeArea(edges: .top)
            .background(
                ClioTheme.background
                    .withGrain(opacity: 0.025)
                    .ignoresSafeArea()
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .sheet(isPresented: $showFeelCheck) {
                FeelCheckView()
            }
            .sheet(isPresented: $showAddMeal) {
                AddMealView()
            }
            .sheet(isPresented: $showAddMovement) {
                AddMovementView()
            }
            .sheet(isPresented: $showQuickLog) {
                QuickDailyLogView()
            }
        }
    }

    // MARK: - Home Hero Illustration

    private var heroImageName: String {
        "eating-menstrual" // Same image as PhaseHeroView uses
    }

    private func loadBundleImage(_ name: String) -> Image {
        if let uiImage = UIImage(named: name) {
            return Image(uiImage: uiImage)
        } else if let path = Bundle.main.path(forResource: name, ofType: "png"),
                  let uiImage = UIImage(contentsOfFile: path) {
            return Image(uiImage: uiImage)
        }
        return Image(systemName: "photo")
    }

    private var homeHero: some View {
        ZStack(alignment: .bottomLeading) {
            // Solid background to prevent any flash
            ClioTheme.background
                .frame(height: 380)

            // Full illustration - aligned to BOTTOM to show person
            loadBundleImage(heroImageName)
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

            // Greeting + Log button overlaid on gradient
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(greeting)
                        .font(ClioTheme.headingFont(22))
                        .foregroundStyle(ClioTheme.text)

                    HStack(spacing: 6) {
                        Circle()
                            .fill(ClioTheme.phaseColor(for: currentPhase))
                            .frame(width: 6, height: 6)

                        if let day = userSettings?.dayOfCycle {
                            Text("\(currentPhase.description) · Day \(day)")
                                .font(ClioTheme.captionFont(13))
                                .foregroundStyle(ClioTheme.textMuted)
                        } else {
                            Text(currentPhase.description)
                                .font(ClioTheme.captionFont(13))
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
                    .background(ClioTheme.terracotta)
                    .clipShape(Capsule())
                }
            }
            .padding(.horizontal, ClioTheme.spacing)
            .padding(.bottom, 10)
        }
    }

    // MARK: - Header (legacy, now in hero)
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(greeting)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(ClioTheme.text)

                // Phase indicator with day
                HStack(spacing: 6) {
                    Circle()
                        .fill(ClioTheme.phaseColor(for: currentPhase))
                        .frame(width: 6, height: 6)

                    if let day = userSettings?.dayOfCycle {
                        Text("\(currentPhase.description) · Day \(day)")
                            .font(.subheadline)
                            .foregroundStyle(ClioTheme.textMuted)
                    } else {
                        Text(currentPhase.description)
                            .font(.subheadline)
                            .foregroundStyle(ClioTheme.textMuted)
                    }
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(greeting). \(currentPhase.description), day \(userSettings?.dayOfCycle ?? 1) of your cycle")

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
            .accessibilityLabel("Quick log")
            .accessibilityHint("Opens quick logging options for meals, movement, and check-ins")
        }
    }

    // MARK: - Feel Check Section
    @ViewBuilder
    private var feelCheckSection: some View {
        if let feelCheck = todayFeelCheck {
            // Compact checked-in state
            HStack(spacing: 10) {
                if let stateRaw = feelCheck.primaryState,
                   let state = FeelCheck.PrimaryState(rawValue: stateRaw) {
                    Image(systemName: state.icon)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(state.isPositive ? ClioTheme.success : ClioTheme.terracotta)

                    Text("Checked in: \(state.rawValue)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(ClioTheme.text)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(ClioTheme.success)

                    Text("Checked in")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(ClioTheme.text)
                }

                Spacer()

                Button {
                    showFeelCheck = true
                } label: {
                    Text("Update")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(ClioTheme.feelColor)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(ClioTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        } else {
            // CTA to check in - prominent card
            Button {
                showFeelCheck = true
            } label: {
                VStack(spacing: 16) {
                    VStack(spacing: 6) {
                        Text("How does your body feel?")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundStyle(ClioTheme.text)

                        Text("Take a moment to check in with yourself")
                            .font(.subheadline)
                            .foregroundStyle(ClioTheme.textMuted)
                    }

                    Text("Check in")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Capsule().fill(ClioTheme.terracotta))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .padding(.horizontal, ClioTheme.spacing)
                .background(
                    LinearGradient(
                        colors: [ClioTheme.feelColor.opacity(0.08), ClioTheme.surface],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(ClioTheme.feelColor.opacity(0.15), lineWidth: 1)
                )
            }
            .buttonStyle(TipChipButtonStyle())
        }
    }

    // MARK: - Insight Card
    private func insightCard(_ insight: PersonalInsight) -> some View {
        Button {
            selectedTab = .insights
        } label: {
            HStack(spacing: 14) {
                // Icon
                ZStack {
                    Circle()
                        .fill(ClioTheme.insightColor.opacity(0.15))
                        .frame(width: 40, height: 40)

                    Image(systemName: insight.insightTypeEnum?.icon ?? "lightbulb")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(ClioTheme.insightColor)
                }

                // Text
                VStack(alignment: .leading, spacing: 3) {
                    Text(insight.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(ClioTheme.text)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    Text(insight.confidenceText)
                        .font(.caption)
                        .foregroundStyle(ClioTheme.textMuted)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(ClioTheme.textMuted)
            }
            .padding()
            .background(ClioTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(ClioTheme.insightColor.opacity(0.15), lineWidth: 1)
            )
        }
        .buttonStyle(TipChipButtonStyle())
        .accessibilityLabel("Insight: \(insight.title)")
        .accessibilityHint("Double tap to view all insights")
    }

    // MARK: - Today's Summary (always visible, compact cards with empty states)
    private var todaySummary: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today")
                .font(.headline)
                .foregroundStyle(ClioTheme.text)

            HStack(spacing: 10) {
                // Meals card
                Button {
                    selectedTab = .eat
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "fork.knife")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(ClioTheme.eatColor)

                        if todayMeals.isEmpty {
                            VStack(alignment: .leading, spacing: 1) {
                                Text("No meals yet")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundStyle(ClioTheme.textMuted)
                                Text("Log eating")
                                    .font(.caption2)
                                    .foregroundStyle(ClioTheme.eatColor)
                            }
                        } else {
                            VStack(alignment: .leading, spacing: 1) {
                                Text("\(todayMeals.count) meal\(todayMeals.count == 1 ? "" : "s")")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(ClioTheme.text)
                                if !mealTypesSummary.isEmpty {
                                    Text(mealTypesSummary)
                                        .font(.caption2)
                                        .foregroundStyle(ClioTheme.textMuted)
                                        .lineLimit(1)
                                }
                            }
                        }

                        Spacer()
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(ClioTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(TipChipButtonStyle())
                .accessibilityLabel(todayMeals.isEmpty ? "No meals logged. Tap to log eating" : "\(todayMeals.count) meals logged today")
                .accessibilityHint("Double tap to view meals")

                // Movement card
                Button {
                    selectedTab = .move
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "figure.run")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(ClioTheme.moveColor)

                        if todayMovements.isEmpty {
                            VStack(alignment: .leading, spacing: 1) {
                                Text("No movement yet")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundStyle(ClioTheme.textMuted)
                                Text("Log activity")
                                    .font(.caption2)
                                    .foregroundStyle(ClioTheme.moveColor)
                            }
                        } else {
                            VStack(alignment: .leading, spacing: 1) {
                                if let summary = movementSummaryText {
                                    Text(summary)
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(ClioTheme.text)
                                        .lineLimit(1)
                                }
                                if todayMovements.count > 1 {
                                    Text("+\(todayMovements.count - 1) more")
                                        .font(.caption2)
                                        .foregroundStyle(ClioTheme.textMuted)
                                } else if todayMinutes > 0 {
                                    Text("\(todayMinutes) min total")
                                        .font(.caption2)
                                        .foregroundStyle(ClioTheme.textMuted)
                                }
                            }
                        }

                        Spacer()
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(ClioTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(TipChipButtonStyle())
                .accessibilityLabel(todayMovements.isEmpty ? "No movement logged. Tap to log activity" : "\(todayMinutes) minutes of movement today")
                .accessibilityHint("Double tap to view workouts")
            }
        }
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
    HomeView(selectedTab: .constant(.home))
        .modelContainer(for: [UserSettings.self, FeelCheck.self, MovementEntry.self, MealEntry.self, PersonalInsight.self], inMemory: true)
}
