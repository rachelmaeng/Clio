import SwiftUI
import SwiftData

struct InsightsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \UserSettings.createdAt, order: .reverse) private var settings: [UserSettings]
    @Query(sort: \PersonalInsight.createdAt, order: .reverse) private var insights: [PersonalInsight]
    @Query(sort: \MealEntry.dateTime, order: .reverse) private var meals: [MealEntry]
    @Query(sort: \MovementEntry.dateTime, order: .reverse) private var movements: [MovementEntry]
    @Query(sort: \FeelCheck.dateTime, order: .reverse) private var feelChecks: [FeelCheck]

    @State private var selectedMonth = Date()
    @State private var selectedInsight: PersonalInsight?
    @State private var selectedDate: Date?
    @State private var selectedPhase: CyclePhase?
    @State private var hasCheckedInsights = false
    @State private var calendarExpanded: Bool = false

    private var userSettings: UserSettings? {
        settings.first
    }

    private var currentPhase: CyclePhase {
        userSettings?.currentPhase ?? .follicular
    }

    private var activeInsights: [PersonalInsight] {
        insights.filter { !$0.hasBeenDismissed }
    }

    private var groupedInsights: [InsightGroup] {
        InsightGenerator.groupInsightsForDisplay(insights)
    }

    /// Check if user has minimum data for personalized insights (14+ days, enough entries)
    private var hasMinimumDataForInsights: Bool {
        CorrelationEngine.hasMinimumDataForInsights(
            meals: meals,
            movements: movements,
            feelChecks: feelChecks
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ClioTheme.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Hero illustration - full width
                        // No fadeInFromBottom on hero to prevent white flash
                        insightsHero
                            .padding(.horizontal, -ClioTheme.spacing)

                        // Header
                        header
                            .fadeInFromBottom(delay: 0.05)

                        // Grouped Insights OR Cold Start / Empty State
                        if !groupedInsights.isEmpty {
                            groupedInsightsSection
                                .fadeInFromBottom(delay: 0.1)
                        } else if !hasMinimumDataForInsights {
                            // Cold start: not enough data yet
                            coldStartSection
                                .fadeInFromBottom(delay: 0.1)
                        } else if activeInsights.isEmpty {
                            // Has enough data but no patterns found yet
                            emptyState
                                .fadeInFromBottom(delay: 0.1)
                        }

                        // Cycle Calendar - now collapsible
                        cycleCalendar
                            .fadeInFromBottom(delay: 0.25)

                        // Stats Summary - only show if there's data
                        if thisMonthMeals > 0 || thisMonthMovements > 0 || thisMonthFeelChecks > 0 {
                            statsSummary
                                .fadeInFromBottom(delay: 0.3)
                        }
                    }
                    .padding(.horizontal, ClioTheme.spacing)
                    .padding(.bottom, 100)
                }
                .ignoresSafeArea(edges: .top)
            }
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $selectedInsight) { insight in
                InsightDetailSheet(insight: insight)
            }
            .sheet(item: $selectedDate) { date in
                DayDetailSheet(
                    date: date,
                    meals: mealsForDate(date),
                    movements: movementsForDate(date),
                    feelChecks: feelChecksForDate(date),
                    phase: phaseForDate(date)
                )
            }
            .sheet(item: $selectedPhase) { phase in
                PhaseDetailSheet(phase: phase)
            }
            .onAppear {
                generateInsightsIfNeeded()
            }
        }
    }

    // MARK: - Insight Generation
    private func generateInsightsIfNeeded() {
        guard !hasCheckedInsights else { return }
        hasCheckedInsights = true

        if InsightGenerator.shouldGenerateInsights(modelContext: modelContext) {
            InsightGenerator.generateInsights(modelContext: modelContext)
        }
    }

    // MARK: - Helper Functions for Date Data
    private func mealsForDate(_ date: Date) -> [MealEntry] {
        meals.filter { Calendar.current.isDate($0.dateTime, inSameDayAs: date) }
    }

    private func movementsForDate(_ date: Date) -> [MovementEntry] {
        movements.filter { Calendar.current.isDate($0.dateTime, inSameDayAs: date) }
    }

    private func feelChecksForDate(_ date: Date) -> [FeelCheck] {
        feelChecks.filter { Calendar.current.isDate($0.dateTime, inSameDayAs: date) }
    }

    private func phaseForDate(_ date: Date) -> CyclePhase {
        guard let lastPeriod = userSettings?.lastPeriodStart else { return .follicular }
        return CyclePhaseEngine.phaseForDate(date, lastPeriodStart: lastPeriod, cycleLength: userSettings?.cycleLength ?? 28)
    }

    // MARK: - Insights Hero Illustration
    private var insightsHero: some View {
        ZStack(alignment: .bottomLeading) {
            // Solid background to prevent any flash
            ClioTheme.background
                .frame(height: 380)

            // Full illustration - aligned to BOTTOM to show person
            loadBundleImage("contemplation-luteal")
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

            // Text overlaid
            VStack(alignment: .leading, spacing: 4) {
                Text("Insights")
                    .font(ClioTheme.headingFont(22))
                    .foregroundStyle(ClioTheme.text)

                Text("Discover your patterns")
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

    // MARK: - Header
    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Insights")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundStyle(ClioTheme.text)

            Text("Patterns discovered from your logs")
                .font(.subheadline)
                .foregroundStyle(ClioTheme.textMuted)
        }
    }

    // MARK: - Cycle Calendar (Collapsible)
    private var cycleCalendar: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Collapsible header
            Button {
                withAnimation(.clioSpring) {
                    calendarExpanded.toggle()
                }
            } label: {
                HStack {
                    Text("Your Cycle")
                        .font(.headline)
                        .foregroundStyle(ClioTheme.text)

                    Spacer()

                    // Current phase indicator when collapsed
                    if !calendarExpanded {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(ClioTheme.phaseColor(for: currentPhase))
                                .frame(width: 6, height: 6)

                            Text(currentPhase.description)
                                .font(ClioTheme.captionFont(12))
                                .foregroundStyle(ClioTheme.textMuted)
                        }
                    }

                    Image(systemName: calendarExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(ClioTheme.textMuted)
                        .padding(.leading, 8)
                }
                .padding()
                .background(ClioTheme.surface)
            }
            .buttonStyle(.plain)

            // Expandable calendar content
            if calendarExpanded {
                VStack(alignment: .leading, spacing: 16) {
                    // Month navigation
                    HStack {
                        Spacer()

                        HStack(spacing: 16) {
                            Button {
                                withAnimation {
                                    selectedMonth = Calendar.current.date(byAdding: .month, value: -1, to: selectedMonth) ?? selectedMonth
                                }
                            } label: {
                                Image(systemName: "chevron.left")
                                    .foregroundStyle(ClioTheme.textMuted)
                            }

                            Text(monthYearString(selectedMonth))
                                .font(.subheadline)
                                .foregroundStyle(ClioTheme.text)

                            Button {
                                withAnimation {
                                    selectedMonth = Calendar.current.date(byAdding: .month, value: 1, to: selectedMonth) ?? selectedMonth
                                }
                            } label: {
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(ClioTheme.textMuted)
                            }
                        }

                        Spacer()
                    }

                    // Calendar Grid
                    CycleCalendarGrid(
                        month: selectedMonth,
                        lastPeriodStart: userSettings?.lastPeriodStart,
                        cycleLength: userSettings?.cycleLength ?? 28,
                        meals: meals,
                        movements: movements,
                        feelChecks: feelChecks,
                        onDateSelected: { date in
                            selectedDate = date
                        }
                    )

                    // Phase Legend - clear buttons for details
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tap to learn more")
                            .font(ClioTheme.captionFont(11))
                            .foregroundStyle(ClioTheme.textLight)

                        HStack(spacing: 8) {
                            ForEach(CyclePhase.allCases, id: \.self) { phase in
                                Button {
                                    selectedPhase = phase
                                } label: {
                                    HStack(spacing: 5) {
                                        Circle()
                                            .fill(ClioTheme.phaseColor(for: phase))
                                            .frame(width: 8, height: 8)
                                        Text(ClioTheme.phaseName(for: phase))
                                            .font(ClioTheme.captionFont(11))
                                            .foregroundStyle(ClioTheme.text)
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 8)
                                    .background(ClioTheme.surfaceHighlight)
                                    .clipShape(Capsule())
                                    .overlay(
                                        Capsule()
                                            .stroke(ClioTheme.phaseColor(for: phase).opacity(0.3), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding()
                .background(ClioTheme.surface)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Grouped Insights Section
    private var groupedInsightsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            ForEach(groupedInsights) { group in
                VStack(alignment: .leading, spacing: 12) {
                    // Group header with icon
                    HStack(spacing: 8) {
                        Image(systemName: group.icon)
                            .font(.subheadline)
                            .foregroundStyle(ClioTheme.primary)

                        Text(group.title)
                            .font(.headline)
                            .foregroundStyle(ClioTheme.text)
                    }

                    // Insights in this group
                    VStack(spacing: 10) {
                        ForEach(group.insights) { insight in
                            SwipeableInsightCard(
                                insight: insight,
                                isNew: insight.isNew,
                                onTap: {
                                    selectedInsight = insight
                                },
                                onDismiss: {
                                    dismissInsight(insight)
                                }
                            )
                        }
                    }
                }
            }
        }
    }

    private func dismissInsight(_ insight: PersonalInsight) {
        withAnimation(.easeOut(duration: 0.3)) {
            InsightGenerator.dismissInsight(insight, modelContext: modelContext)
        }
    }

    // MARK: - Cold Start Section (Not enough data yet)
    private var coldStartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            VStack(alignment: .leading, spacing: 4) {
                Text("Things to explore")
                    .font(.headline)
                    .foregroundStyle(ClioTheme.text)

                Text("General suggestions for your \(currentPhase.description.lowercased()) phase")
                    .font(.caption)
                    .foregroundStyle(ClioTheme.textMuted)
            }

            // Generic phase-based suggestions
            VStack(spacing: 10) {
                ForEach(coldStartSuggestions, id: \.title) { suggestion in
                    coldStartSuggestionCard(suggestion)
                }
            }

            // Progress indicator
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.subheadline)
                        .foregroundStyle(ClioTheme.primary)

                    Text("Building your insights")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(ClioTheme.text)
                }

                Text("Keep logging for 14+ days. Clio will find patterns from your unique data—no generic advice, just what works for your body.")
                    .font(.caption)
                    .foregroundStyle(ClioTheme.textMuted)
                    .lineSpacing(2)
            }
            .padding()
            .background(ClioTheme.surfaceHighlight)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func coldStartSuggestionCard(_ suggestion: ColdStartSuggestion) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(ClioTheme.phaseColor(for: currentPhase).opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: suggestion.icon)
                    .font(.system(size: 18))
                    .foregroundStyle(ClioTheme.phaseColor(for: currentPhase))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(suggestion.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(ClioTheme.text)

                Text(suggestion.body)
                    .font(.caption)
                    .foregroundStyle(ClioTheme.textMuted)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding()
        .background(ClioTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private struct ColdStartSuggestion {
        let icon: String
        let title: String
        let body: String
    }

    private var coldStartSuggestions: [ColdStartSuggestion] {
        switch currentPhase {
        case .menstrual:
            return [
                ColdStartSuggestion(
                    icon: "leaf",
                    title: "Gentle movement",
                    body: "Many find gentle yoga or walking helpful during this phase"
                ),
                ColdStartSuggestion(
                    icon: "flame",
                    title: "Warm, nourishing foods",
                    body: "Iron-rich foods like leafy greens and lentils may support energy"
                ),
                ColdStartSuggestion(
                    icon: "moon.zzz",
                    title: "Rest is productive",
                    body: "Honor your body's need for rest—it's part of the cycle"
                )
            ]
        case .follicular:
            return [
                ColdStartSuggestion(
                    icon: "bolt",
                    title: "Energy is building",
                    body: "This phase often brings rising energy—great for new challenges"
                ),
                ColdStartSuggestion(
                    icon: "figure.run",
                    title: "Try something new",
                    body: "Your body may respond well to varied workouts"
                ),
                ColdStartSuggestion(
                    icon: "sparkles",
                    title: "Fresh, light foods",
                    body: "Many feel good with fresh salads and lean proteins"
                )
            ]
        case .ovulation:
            return [
                ColdStartSuggestion(
                    icon: "sun.max",
                    title: "Peak energy window",
                    body: "Many experience highest energy and social drive now"
                ),
                ColdStartSuggestion(
                    icon: "figure.highintensity.intervaltraining",
                    title: "Higher intensity",
                    body: "Your body may handle more intense workouts well"
                ),
                ColdStartSuggestion(
                    icon: "carrot",
                    title: "Fiber-rich foods",
                    body: "Cruciferous veggies support estrogen metabolism"
                )
            ]
        case .luteal:
            return [
                ColdStartSuggestion(
                    icon: "heart",
                    title: "Be gentle with yourself",
                    body: "Energy may dip—adjust expectations accordingly"
                ),
                ColdStartSuggestion(
                    icon: "fork.knife",
                    title: "Complex carbs & magnesium",
                    body: "Cravings are normal—nuts, seeds, and dark chocolate may help"
                ),
                ColdStartSuggestion(
                    icon: "bed.double",
                    title: "Prioritize sleep",
                    body: "Good sleep supports mood and energy during this phase"
                )
            ]
        }
    }

    // MARK: - Empty State (Has data but no patterns found yet)
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 40))
                .foregroundStyle(ClioTheme.textMuted.opacity(0.5))

            VStack(spacing: 8) {
                Text("Patterns from your logs")
                    .font(.headline)
                    .foregroundStyle(ClioTheme.text)

                Text("Clio is analyzing your data. Keep logging meals, movements, and how you feel—personal insights will appear as patterns emerge.")
                    .font(.subheadline)
                    .foregroundStyle(ClioTheme.textMuted)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity)
        .background(ClioTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Stats Summary
    private var statsSummary: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("This Month")
                .font(.headline)
                .foregroundStyle(ClioTheme.text)

            HStack(spacing: 12) {
                if thisMonthMeals > 0 {
                    StatBox(
                        icon: "fork.knife",
                        value: "\(thisMonthMeals)",
                        label: "Meals",
                        color: ClioTheme.eatColor
                    )
                }

                if thisMonthMovements > 0 {
                    StatBox(
                        icon: "figure.run",
                        value: "\(thisMonthMovements)",
                        label: "Workouts",
                        color: ClioTheme.moveColor
                    )
                }

                if thisMonthFeelChecks > 0 {
                    StatBox(
                        icon: "heart.fill",
                        value: "\(thisMonthFeelChecks)",
                        label: "Check-ins",
                        color: ClioTheme.feelColor
                    )
                }
            }
        }
    }

    // MARK: - Computed Stats
    private var thisMonthMeals: Int {
        let startOfMonth = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: Date()))!
        return meals.filter { $0.dateTime >= startOfMonth }.count
    }

    private var thisMonthMovements: Int {
        let startOfMonth = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: Date()))!
        return movements.filter { $0.dateTime >= startOfMonth }.count
    }

    private var thisMonthFeelChecks: Int {
        let startOfMonth = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: Date()))!
        return feelChecks.filter { $0.dateTime >= startOfMonth }.count
    }

    private func monthYearString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
}

// MARK: - Cycle Calendar Grid
struct CycleCalendarGrid: View {
    let month: Date
    let lastPeriodStart: Date?
    let cycleLength: Int
    let meals: [MealEntry]
    let movements: [MovementEntry]
    let feelChecks: [FeelCheck]
    let onDateSelected: (Date) -> Void

    private let calendar = Calendar.current
    private let weekdays = ["S", "M", "T", "W", "T", "F", "S"]

    private var daysInMonth: [Date?] {
        guard let range = calendar.range(of: .day, in: .month, for: month),
              let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: month)) else {
            return []
        }

        let firstWeekday = calendar.component(.weekday, from: firstDay)
        var days: [Date?] = Array(repeating: nil, count: firstWeekday - 1)

        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDay) {
                days.append(date)
            }
        }

        return days
    }

    var body: some View {
        VStack(spacing: 8) {
            // Weekday headers
            HStack {
                ForEach(weekdays, id: \.self) { day in
                    Text(day)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(ClioTheme.textMuted)
                        .frame(maxWidth: .infinity)
                }
            }

            // Calendar grid
            let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(Array(daysInMonth.enumerated()), id: \.offset) { index, date in
                    if let date = date {
                        let hasData = hasDataForDate(date)
                        let streakInfo = calculateStreakConnectors(for: date, at: index)

                        CalendarDayCell(
                            date: date,
                            phase: phaseForDate(date),
                            isToday: calendar.isDateInToday(date),
                            hasData: hasData,
                            hasLeftStreak: streakInfo.left,
                            hasRightStreak: streakInfo.right
                        )
                        .onTapGesture {
                            onDateSelected(date)
                        }
                    } else {
                        Color.clear
                            .frame(height: 38)
                    }
                }
            }
        }
    }

    private func phaseForDate(_ date: Date) -> CyclePhase? {
        guard let lastPeriod = lastPeriodStart else { return nil }
        return CyclePhaseEngine.phaseForDate(date, lastPeriodStart: lastPeriod, cycleLength: cycleLength)
    }

    private func hasDataForDate(_ date: Date) -> Bool {
        let hasMeals = meals.contains { calendar.isDate($0.dateTime, inSameDayAs: date) }
        let hasMovements = movements.contains { calendar.isDate($0.dateTime, inSameDayAs: date) }
        let hasFeelChecks = feelChecks.contains { calendar.isDate($0.dateTime, inSameDayAs: date) }
        return hasMeals || hasMovements || hasFeelChecks
    }

    // Calculate streak connectors for a given date
    private func calculateStreakConnectors(for date: Date, at index: Int) -> (left: Bool, right: Bool) {
        let currentHasData = hasDataForDate(date)

        // If current day has no data, no connectors
        guard currentHasData else { return (false, false) }

        // Check previous day (index - 1) for left connector
        // But only if not at start of a row (not Sunday)
        let dayOfWeek = calendar.component(.weekday, from: date)
        var hasLeftStreak = false
        var hasRightStreak = false

        // Left connector: previous day has data AND not Sunday (start of row)
        if dayOfWeek != 1, // Not Sunday
           let previousDay = calendar.date(byAdding: .day, value: -1, to: date) {
            hasLeftStreak = hasDataForDate(previousDay)
        }

        // Right connector: next day has data AND not Saturday (end of row)
        if dayOfWeek != 7, // Not Saturday
           let nextDay = calendar.date(byAdding: .day, value: 1, to: date) {
            hasRightStreak = hasDataForDate(nextDay)
        }

        return (hasLeftStreak, hasRightStreak)
    }
}

struct CalendarDayCell: View {
    let date: Date
    let phase: CyclePhase?
    let isToday: Bool
    let hasData: Bool
    let hasLeftStreak: Bool  // Connected to previous day
    let hasRightStreak: Bool // Connected to next day

    private var dayNumber: Int {
        Calendar.current.component(.day, from: date)
    }

    private let circleSize: CGFloat = 28

    var body: some View {
        VStack(spacing: 2) {
            ZStack {
                // Phase circle background
                if let phase = phase {
                    Circle()
                        .fill(ClioTheme.phaseColor(for: phase).opacity(0.3))
                        .frame(width: circleSize, height: circleSize)
                }

                // Today ring
                if isToday {
                    Circle()
                        .stroke(ClioTheme.primary, lineWidth: 2)
                        .frame(width: circleSize, height: circleSize)
                }

                // Day number
                Text("\(dayNumber)")
                    .font(.caption)
                    .fontWeight(isToday ? .bold : .regular)
                    .foregroundStyle(isToday ? ClioTheme.primary : ClioTheme.text)
            }
            .frame(width: circleSize, height: circleSize)
            .background(
                // Streak connector lines - extend beyond cell bounds to bridge gaps
                GeometryReader { geo in
                    HStack(spacing: 0) {
                        // Left connector - extends 20pt past cell edge
                        Rectangle()
                            .fill(hasLeftStreak ? ClioTheme.primary : Color.clear)
                            .frame(width: 20, height: 1.5)

                        Spacer()

                        // Right connector - extends 20pt past cell edge
                        Rectangle()
                            .fill(hasRightStreak ? ClioTheme.primary : Color.clear)
                            .frame(width: 20, height: 1.5)
                    }
                    .frame(width: geo.size.width + 40, height: geo.size.height)
                    .offset(x: -20)
                }
            )

            // Data indicator dot
            Circle()
                .fill(hasData ? ClioTheme.primary : Color.clear)
                .frame(width: 4, height: 4)
        }
        .frame(height: 36)
    }
}

// MARK: - Insight Card
struct InsightCard: View {
    let insight: PersonalInsight
    let isNew: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Category icon
                ZStack {
                    Circle()
                        .fill(categoryColor.opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: categoryIcon)
                        .font(.system(size: 18))
                        .foregroundStyle(categoryColor)
                }

                // Content
                VStack(alignment: .leading, spacing: 4) {
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

                // New indicator or chevron
                if isNew {
                    Circle()
                        .fill(ClioTheme.primary)
                        .frame(width: 8, height: 8)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(ClioTheme.textMuted)
                }
            }
            .padding()
            .background(ClioTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(TipChipButtonStyle())
    }

    private var categoryColor: Color {
        switch insight.category {
        case "food": return ClioTheme.eatColor
        case "movement": return ClioTheme.moveColor
        default: return ClioTheme.insightColor
        }
    }

    private var categoryIcon: String {
        insight.categoryEnum?.icon ?? "sparkles"
    }
}

// MARK: - Swipeable Insight Card
struct SwipeableInsightCard: View {
    let insight: PersonalInsight
    let isNew: Bool
    let onTap: () -> Void
    let onDismiss: () -> Void

    @State private var offset: CGFloat = 0
    @State private var isDismissing = false

    private let dismissThreshold: CGFloat = -80
    private let maxOffset: CGFloat = -100

    var body: some View {
        ZStack(alignment: .trailing) {
            // Background dismiss indicator
            HStack {
                Spacer()
                VStack(spacing: 4) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                    Text("Dismiss")
                        .font(.caption2)
                }
                .foregroundStyle(.white)
                .frame(width: 80)
                .opacity(offset < dismissThreshold / 2 ? 1 : 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(ClioTheme.terracotta.opacity(0.8))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Main card
            InsightCard(insight: insight, isNew: isNew, action: onTap)
                .offset(x: offset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            // Only allow left swipe
                            if value.translation.width < 0 {
                                offset = max(value.translation.width, maxOffset)
                            }
                        }
                        .onEnded { value in
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                if offset < dismissThreshold {
                                    // Dismiss the card
                                    isDismissing = true
                                    offset = -UIScreen.main.bounds.width
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                        onDismiss()
                                    }
                                } else {
                                    // Snap back
                                    offset = 0
                                }
                            }
                        }
                )
        }
        .opacity(isDismissing ? 0 : 1)
    }
}

// MARK: - Stat Box
struct StatBox: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(ClioTheme.text)

            Text(label)
                .font(.caption)
                .foregroundStyle(ClioTheme.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(ClioTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Insight Detail Sheet
struct InsightDetailSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let insight: PersonalInsight

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
                                    .fill(categoryColor.opacity(0.15))
                                    .frame(width: 80, height: 80)

                                Image(systemName: categoryIcon)
                                    .font(.system(size: 32))
                                    .foregroundStyle(categoryColor)
                            }

                            Text(insight.title)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(ClioTheme.text)
                                .multilineTextAlignment(.center)

                            // Confidence badge
                            HStack(spacing: 8) {
                                Text(insight.confidenceLevel.rawValue)
                                    .font(.caption)
                                    .fontWeight(.medium)

                                Text("confidence")
                                    .font(.caption)
                            }
                            .foregroundStyle(ClioTheme.textMuted)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(ClioTheme.surface)
                            .clipShape(Capsule())
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top)

                        // Body
                        VStack(alignment: .leading, spacing: 12) {
                            Text("What we found")
                                .font(.headline)
                                .foregroundStyle(ClioTheme.text)

                            Text(insight.body)
                                .font(.subheadline)
                                .foregroundStyle(ClioTheme.textMuted)
                                .lineSpacing(4)
                        }
                        .padding()
                        .background(ClioTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                        // Suggestion
                        if let suggestion = insight.suggestion {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Try this")
                                    .font(.headline)
                                    .foregroundStyle(ClioTheme.text)

                                Text(suggestion)
                                    .font(.subheadline)
                                    .foregroundStyle(ClioTheme.textMuted)
                                    .lineSpacing(4)
                            }
                            .padding()
                            .background(ClioTheme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
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
            .onAppear {
                insight.markAsViewed()
                try? modelContext.save()
            }
        }
    }

    private var categoryColor: Color {
        switch insight.category {
        case "food": return ClioTheme.eatColor
        case "movement": return ClioTheme.moveColor
        default: return ClioTheme.insightColor
        }
    }

    private var categoryIcon: String {
        insight.categoryEnum?.icon ?? "sparkles"
    }
}

// MARK: - Date Extension for Sheet
extension Date: @retroactive Identifiable {
    public var id: TimeInterval { timeIntervalSince1970 }
}

// MARK: - Day Detail Sheet
struct DayDetailSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let date: Date
    let meals: [MealEntry]
    let movements: [MovementEntry]
    let feelChecks: [FeelCheck]
    let phase: CyclePhase

    @State private var showingFeelCheck = false
    @State private var showingAddMeal = false
    @State private var showingAddMovement = false

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter
    }

    private var isPastDay: Bool {
        !Calendar.current.isDateInToday(date)
    }

    private var phaseInsight: String {
        switch phase {
        case .menstrual: return "A time for rest and gentle self-care"
        case .follicular: return "Energy is building — great for new beginnings"
        case .ovulation: return "Peak energy and social drive"
        case .luteal: return "Wind down and prepare for your next cycle"
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Solid background - no bleed through
                ClioTheme.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Header with phase context
                        headerSection

                        // Quick add buttons
                        addDataSection

                        // Feel Check Section (with empty state)
                        feelSection

                        // Meals Section (with empty state)
                        mealsSection

                        // Movements Section (with empty state)
                        movementsSection
                    }
                    .padding()
                    .padding(.bottom, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    ClioCloseButton { dismiss() }
                }
            }
            .sheet(isPresented: $showingFeelCheck) {
                FeelCheckView(forDate: date)
            }
            .sheet(isPresented: $showingAddMeal) {
                AddMealView(forDate: date)
            }
            .sheet(isPresented: $showingAddMovement) {
                AddMovementView(forDate: date)
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(ClioTheme.background)
    }

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(dateFormatter.string(from: date))
                .font(ClioTheme.headingFont(24))
                .foregroundStyle(ClioTheme.text)

            // Phase context card
            HStack(spacing: 10) {
                Circle()
                    .fill(ClioTheme.phaseColor(for: phase))
                    .frame(width: 8, height: 8)

                Text(phase.description)
                    .font(ClioTheme.captionFont(13))
                    .fontWeight(.medium)
                    .foregroundStyle(ClioTheme.text)

                Text("·")
                    .foregroundStyle(ClioTheme.textMuted)

                Text(phaseInsight)
                    .font(ClioTheme.captionFont(13))
                    .foregroundStyle(ClioTheme.textMuted)
                    .lineLimit(1)
            }
        }
    }

    // MARK: - Add Data Section
    private var addDataSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(isPastDay ? "Add to this day" : "Log something")
                .font(ClioTheme.captionFont(12))
                .fontWeight(.medium)
                .foregroundStyle(ClioTheme.textMuted)
                .textCase(.uppercase)
                .tracking(0.5)

            HStack(spacing: 10) {
                // All buttons use same muted style for consistency
                DayAddButton(icon: "heart.circle", label: "Feel") {
                    showingFeelCheck = true
                }

                DayAddButton(icon: "fork.knife", label: "Meal") {
                    showingAddMeal = true
                }

                DayAddButton(icon: "figure.run", label: "Move") {
                    showingAddMovement = true
                }
            }
        }
    }

    // MARK: - Feel Section
    private var feelSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("How you felt")
                    .font(ClioTheme.subheadingFont(15))
                    .foregroundStyle(ClioTheme.text)

                Spacer()

                if !feelChecks.isEmpty {
                    Text("\(feelChecks.count) check-in\(feelChecks.count > 1 ? "s" : "")")
                        .font(ClioTheme.captionFont(12))
                        .foregroundStyle(ClioTheme.textMuted)
                }
            }

            if feelChecks.isEmpty {
                sectionEmptyState(
                    icon: "heart.circle",
                    message: "No check-ins logged"
                )
            } else {
                VStack(spacing: 10) {
                    ForEach(feelChecks) { check in
                        feelCheckCard(check)
                    }
                }
            }
        }
    }

    private func feelCheckCard(_ check: FeelCheck) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Energy bar with time
            HStack(spacing: 12) {
                // Energy indicator
                HStack(spacing: 6) {
                    ZStack {
                        Circle()
                            .fill(energyColor(for: check.energyLevel).opacity(0.15))
                            .frame(width: 32, height: 32)

                        Text("\(check.energyLevel)")
                            .font(ClioTheme.headingFont(14))
                            .foregroundStyle(energyColor(for: check.energyLevel))
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Energy")
                            .font(ClioTheme.captionFont(11))
                            .foregroundStyle(ClioTheme.textMuted)
                        Text(energyLabel(for: check.energyLevel))
                            .font(ClioTheme.captionFont(12))
                            .fontWeight(.medium)
                            .foregroundStyle(ClioTheme.text)
                    }
                }

                Spacer()

                Text(timeFormatter.string(from: check.dateTime))
                    .font(ClioTheme.captionFont(12))
                    .foregroundStyle(ClioTheme.textLight)
            }

            // Moods
            if !check.moods.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Mood")
                        .font(ClioTheme.captionFont(11))
                        .foregroundStyle(ClioTheme.textMuted)

                    FlowLayout(spacing: 6) {
                        ForEach(check.moods, id: \.self) { mood in
                            let moodEnum = FeelCheck.Mood(rawValue: mood)
                            HStack(spacing: 4) {
                                if let icon = moodEnum?.icon {
                                    Image(systemName: icon)
                                        .font(.system(size: 10))
                                }
                                Text(mood)
                                    .font(ClioTheme.captionFont(12))
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(ClioTheme.feelColor.opacity(0.12))
                            .foregroundStyle(ClioTheme.feelColor)
                            .clipShape(Capsule())
                        }
                    }
                }
            }

            // Body sensations
            if !check.bodySensations.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Body")
                        .font(ClioTheme.captionFont(11))
                        .foregroundStyle(ClioTheme.textMuted)

                    FlowLayout(spacing: 6) {
                        ForEach(check.bodySensations, id: \.self) { sensation in
                            let sensEnum = FeelCheck.BodySensation(rawValue: sensation)
                            HStack(spacing: 4) {
                                if let icon = sensEnum?.icon {
                                    Image(systemName: icon)
                                        .font(.system(size: 10))
                                }
                                Text(sensation)
                                    .font(ClioTheme.captionFont(12))
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(ClioTheme.surfaceHighlight)
                            .foregroundStyle(ClioTheme.text)
                            .clipShape(Capsule())
                        }
                    }
                }
            }

            // Notes
            if let notes = check.notes, !notes.isEmpty {
                Text("\"\(notes)\"")
                    .font(ClioTheme.bodyFont(13))
                    .foregroundStyle(ClioTheme.textMuted)
                    .italic()
                    .padding(.top, 4)
            }
        }
        .padding(ClioTheme.spacing)
        .background(ClioTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: ClioTheme.cornerRadiusSmall))
        .contextMenu {
            Button(role: .destructive) {
                deleteFeelCheck(check)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    // MARK: - Meals Section
    private var mealsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Meals")
                    .font(ClioTheme.subheadingFont(15))
                    .foregroundStyle(ClioTheme.text)

                Spacer()

                if !meals.isEmpty {
                    let totalCals = meals.compactMap { $0.calories }.reduce(0, +)
                    if totalCals > 0 {
                        Text("\(totalCals) cal total")
                            .font(ClioTheme.captionFont(12))
                            .foregroundStyle(ClioTheme.textMuted)
                    }
                }
            }

            if meals.isEmpty {
                sectionEmptyState(
                    icon: "fork.knife",
                    message: "No meals logged"
                )
            } else {
                VStack(spacing: 8) {
                    ForEach(meals) { meal in
                        mealCard(meal)
                    }
                }
            }
        }
    }

    private func mealCard(_ meal: MealEntry) -> some View {
        HStack(spacing: 12) {
            // Meal type icon
            ZStack {
                Circle()
                    .fill(ClioTheme.eatColor.opacity(0.12))
                    .frame(width: 36, height: 36)

                Image(systemName: mealIcon(for: meal.mealType))
                    .font(.system(size: 14))
                    .foregroundStyle(ClioTheme.eatColor)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(meal.mealType.capitalized)
                    .font(ClioTheme.bodyFont(14))
                    .fontWeight(.medium)
                    .foregroundStyle(ClioTheme.text)

                if !meal.foodItems.isEmpty {
                    Text(meal.foodItems.joined(separator: ", "))
                        .font(ClioTheme.captionFont(12))
                        .foregroundStyle(ClioTheme.textMuted)
                        .lineLimit(1)
                }
            }

            Spacer()

            if let cal = meal.calories {
                Text("\(cal)")
                    .font(ClioTheme.bodyFont(14))
                    .fontWeight(.medium)
                    .foregroundStyle(ClioTheme.text)
                +
                Text(" cal")
                    .font(ClioTheme.captionFont(12))
                    .foregroundStyle(ClioTheme.textMuted)
            }
        }
        .padding(ClioTheme.spacing)
        .background(ClioTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: ClioTheme.cornerRadiusSmall))
        .contextMenu {
            Button(role: .destructive) {
                deleteMeal(meal)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    // MARK: - Movements Section
    private var movementsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Movement")
                    .font(ClioTheme.subheadingFont(15))
                    .foregroundStyle(ClioTheme.text)

                Spacer()

                if !movements.isEmpty {
                    let totalMins = movements.compactMap { $0.durationMinutes }.reduce(0, +)
                    Text("\(totalMins) min total")
                        .font(ClioTheme.captionFont(12))
                        .foregroundStyle(ClioTheme.textMuted)
                }
            }

            if movements.isEmpty {
                sectionEmptyState(
                    icon: "figure.run",
                    message: "No movement logged"
                )
            } else {
                VStack(spacing: 8) {
                    ForEach(movements) { movement in
                        movementCard(movement)
                    }
                }
            }
        }
    }

    private func movementCard(_ movement: MovementEntry) -> some View {
        HStack(spacing: 12) {
            // Movement icon
            ZStack {
                Circle()
                    .fill(ClioTheme.moveColor.opacity(0.12))
                    .frame(width: 36, height: 36)

                Image(systemName: "figure.run")
                    .font(.system(size: 14))
                    .foregroundStyle(ClioTheme.moveColor)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(movement.type)
                    .font(ClioTheme.bodyFont(14))
                    .fontWeight(.medium)
                    .foregroundStyle(ClioTheme.text)

                HStack(spacing: 8) {
                    if let mins = movement.durationMinutes {
                        Text("\(mins) min")
                            .font(ClioTheme.captionFont(12))
                            .foregroundStyle(ClioTheme.textMuted)
                    }

                    if let intensity = movement.intensityLevel, intensity > 0 {
                        Text("· \(intensityLabel(for: intensity))")
                            .font(ClioTheme.captionFont(12))
                            .foregroundStyle(ClioTheme.textMuted)
                    }
                }
            }

            Spacer()

            if let cal = movement.estimatedCaloriesBurned, cal > 0 {
                Text("\(cal)")
                    .font(ClioTheme.bodyFont(14))
                    .fontWeight(.medium)
                    .foregroundStyle(ClioTheme.text)
                +
                Text(" cal")
                    .font(ClioTheme.captionFont(12))
                    .foregroundStyle(ClioTheme.textMuted)
            }
        }
        .padding(ClioTheme.spacing)
        .background(ClioTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: ClioTheme.cornerRadiusSmall))
        .contextMenu {
            Button(role: .destructive) {
                deleteMovement(movement)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    // MARK: - Section Empty State
    private func sectionEmptyState(icon: String, message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(ClioTheme.textLight)

            Text(message)
                .font(ClioTheme.captionFont(13))
                .foregroundStyle(ClioTheme.textLight)

            Spacer()
        }
        .padding(ClioTheme.spacing)
        .background(ClioTheme.surface.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: ClioTheme.cornerRadiusSmall))
    }

    // MARK: - Helpers
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }

    private func energyColor(for level: Int) -> Color {
        switch level {
        case 1...3: return ClioTheme.honey
        case 4...6: return ClioTheme.terracotta
        case 7...10: return ClioTheme.success
        default: return ClioTheme.textMuted
        }
    }

    private func energyLabel(for level: Int) -> String {
        switch level {
        case 1...3: return "Low"
        case 4...6: return "Moderate"
        case 7...10: return "High"
        default: return "—"
        }
    }

    private func intensityLabel(for level: Int) -> String {
        switch level {
        case 1...3: return "Light"
        case 4...6: return "Moderate"
        case 7...10: return "Intense"
        default: return ""
        }
    }

    private func mealIcon(for type: String) -> String {
        switch type.lowercased() {
        case "breakfast": return "sunrise"
        case "lunch": return "sun.max"
        case "dinner": return "moon"
        case "snack": return "leaf"
        default: return "fork.knife"
        }
    }

    // MARK: - Delete Actions
    private func deleteFeelCheck(_ check: FeelCheck) {
        modelContext.delete(check)
        try? modelContext.save()
    }

    private func deleteMeal(_ meal: MealEntry) {
        modelContext.delete(meal)
        try? modelContext.save()
    }

    private func deleteMovement(_ movement: MovementEntry) {
        modelContext.delete(movement)
        try? modelContext.save()
    }
}

// MARK: - Day Add Button (Unified style)
struct DayAddButton: View {
    let icon: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(ClioTheme.textMuted)

                Text(label)
                    .font(ClioTheme.captionFont(12))
                    .fontWeight(.medium)
                    .foregroundStyle(ClioTheme.text)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(ClioTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: ClioTheme.cornerRadiusSmall))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Phase Detail Sheet
struct PhaseDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    let phase: CyclePhase

    var body: some View {
        NavigationStack {
            ZStack {
                ClioTheme.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Header with phase color
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(ClioTheme.phaseColor(for: phase).opacity(0.2))
                                    .frame(width: 80, height: 80)

                                Image(systemName: phaseIcon)
                                    .font(.system(size: 32))
                                    .foregroundStyle(ClioTheme.phaseColor(for: phase))
                            }

                            Text(phase.description)
                                .font(ClioTheme.displayFont(28))
                                .foregroundStyle(ClioTheme.text)

                            Text(phaseTiming)
                                .font(ClioTheme.captionFont(14))
                                .foregroundStyle(ClioTheme.textMuted)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top)

                        // What Happens Section
                        VStack(alignment: .leading, spacing: 12) {
                            Label("What happens", systemImage: "info.circle.fill")
                                .font(ClioTheme.subheadingFont())
                                .foregroundStyle(ClioTheme.text)

                            Text(phaseDescription)
                                .font(ClioTheme.bodyFont())
                                .foregroundStyle(ClioTheme.textMuted)
                                .lineSpacing(4)
                        }
                        .padding()
                        .background(ClioTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                        // Common Symptoms Section
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Common experiences", systemImage: "heart.text.square.fill")
                                .font(ClioTheme.subheadingFont())
                                .foregroundStyle(ClioTheme.text)

                            FlowLayout(spacing: 8) {
                                ForEach(phaseSymptoms, id: \.self) { symptom in
                                    Text(symptom)
                                        .font(ClioTheme.captionFont(13))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(ClioTheme.phaseColor(for: phase).opacity(0.15))
                                        .foregroundStyle(ClioTheme.phaseColor(for: phase))
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        .padding()
                        .background(ClioTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                        // Tips Section
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Tips for this phase", systemImage: "lightbulb.fill")
                                .font(ClioTheme.subheadingFont())
                                .foregroundStyle(ClioTheme.text)

                            VStack(alignment: .leading, spacing: 10) {
                                ForEach(phaseTips, id: \.self) { tip in
                                    HStack(alignment: .top, spacing: 10) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.caption)
                                            .foregroundStyle(ClioTheme.success)
                                            .padding(.top, 2)

                                        Text(tip)
                                            .font(ClioTheme.bodyFont())
                                            .foregroundStyle(ClioTheme.textMuted)
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(ClioTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                        // Movement & Nutrition Section
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Movement & nourishment", systemImage: "figure.walk")
                                .font(ClioTheme.subheadingFont())
                                .foregroundStyle(ClioTheme.text)

                            VStack(alignment: .leading, spacing: 16) {
                                // Movement
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Movement")
                                        .font(ClioTheme.captionFont(12))
                                        .foregroundStyle(ClioTheme.moveColor)

                                    Text(phaseMovement)
                                        .font(ClioTheme.bodyFont())
                                        .foregroundStyle(ClioTheme.textMuted)
                                }

                                Divider()
                                    .background(ClioTheme.surfaceHighlight)

                                // Nutrition
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Nourishment")
                                        .font(ClioTheme.captionFont(12))
                                        .foregroundStyle(ClioTheme.eatColor)

                                    Text(phaseNutrition)
                                        .font(ClioTheme.bodyFont())
                                        .foregroundStyle(ClioTheme.textMuted)
                                }
                            }
                        }
                        .padding()
                        .background(ClioTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .padding()
                    .padding(.bottom, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    ClioCloseButton { dismiss() }
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Phase Data

    private var phaseIcon: String {
        switch phase {
        case .menstrual: return "drop.fill"
        case .follicular: return "sunrise.fill"
        case .ovulation: return "sun.max.fill"
        case .luteal: return "moon.fill"
        }
    }

    private var phaseTiming: String {
        switch phase {
        case .menstrual: return "Days 1-5 · The beginning of your cycle"
        case .follicular: return "Days 6-13 · Building up to ovulation"
        case .ovulation: return "Days 14-16 · Peak fertility window"
        case .luteal: return "Days 17-28 · Preparing for next cycle"
        }
    }

    private var phaseDescription: String {
        switch phase {
        case .menstrual:
            return "Your period marks the start of a new cycle. The uterine lining sheds, hormone levels are at their lowest, and your body is in a natural state of release. It's a time for rest and gentle care."
        case .follicular:
            return "Estrogen rises as follicles develop in your ovaries. You may notice increased energy, improved mood, and enhanced cognitive function. Your body is building up strength and vitality."
        case .ovulation:
            return "An egg is released from the ovary. Estrogen peaks and testosterone rises briefly. This is often when energy, confidence, and social drive are at their highest."
        case .luteal:
            return "After ovulation, progesterone rises to prepare for potential pregnancy. If the egg isn't fertilized, hormone levels gradually decline, which can bring premenstrual symptoms."
        }
    }

    private var phaseSymptoms: [String] {
        switch phase {
        case .menstrual:
            return ["Fatigue", "Cramps", "Lower back pain", "Tender breasts", "Mood changes", "Headaches", "Need for rest"]
        case .follicular:
            return ["Rising energy", "Improved mood", "Mental clarity", "Increased creativity", "Social energy", "Skin glow"]
        case .ovulation:
            return ["Peak energy", "Confidence boost", "Increased libido", "Glowing skin", "Sharp focus", "Social drive"]
        case .luteal:
            return ["Fatigue", "Bloating", "Mood swings", "Cravings", "Breast tenderness", "Anxiety", "Irritability"]
        }
    }

    private var phaseTips: [String] {
        switch phase {
        case .menstrual:
            return [
                "Prioritize rest and gentle movement",
                "Stay hydrated and warm",
                "Honor your need for solitude",
                "Use heat for cramp relief",
                "Journal or reflect on the past month"
            ]
        case .follicular:
            return [
                "Try new workouts or activities",
                "Start new projects or goals",
                "Schedule social events",
                "Lean into creativity",
                "Plan ahead while energy is high"
            ]
        case .ovulation:
            return [
                "Tackle challenging workouts",
                "Schedule important meetings",
                "Connect with others socially",
                "Express yourself creatively",
                "Take on leadership roles"
            ]
        case .luteal:
            return [
                "Maintain consistent sleep schedule",
                "Reduce caffeine and alcohol",
                "Practice stress management",
                "Be gentle with yourself",
                "Prepare healthy comfort foods"
            ]
        }
    }

    private var phaseMovement: String {
        switch phase {
        case .menstrual:
            return "Gentle yoga, walking, stretching, or complete rest. Listen to your body—if it needs rest, honor that."
        case .follicular:
            return "Great time for trying new workouts, cardio, strength training, dance, or anything that feels exciting."
        case .ovulation:
            return "Peak performance time! HIIT, running, heavy lifting, competitive sports—your body can handle intensity."
        case .luteal:
            return "Moderate exercise like pilates, swimming, cycling. Reduce intensity as you approach your period."
        }
    }

    private var phaseNutrition: String {
        switch phase {
        case .menstrual:
            return "Iron-rich foods (leafy greens, lentils), warming soups, dark chocolate, herbal teas. Avoid excessive salt."
        case .follicular:
            return "Light, fresh foods—salads, fermented foods, lean proteins. Great time for meal prepping."
        case .ovulation:
            return "Raw vegetables, fiber-rich foods, cruciferous veggies to support estrogen metabolism."
        case .luteal:
            return "Complex carbs, magnesium-rich foods (nuts, seeds, dark chocolate), B-vitamin foods to support mood."
        }
    }
}

#Preview {
    InsightsView()
        .modelContainer(for: [UserSettings.self, PersonalInsight.self, MealEntry.self, MovementEntry.self, FeelCheck.self], inMemory: true)
}
