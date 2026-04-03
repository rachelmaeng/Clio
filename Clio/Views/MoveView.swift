import SwiftUI
import SwiftData

// Wrapper for sheet presentation to capture preselected type correctly
struct AddMovementSheetItem: Identifiable {
    let id = UUID()
    let preselectedType: MovementEntry.MovementType?
    let preselectedCategory: MovementEntry.MovementCategory?
}

struct MoveView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \UserSettings.createdAt, order: .reverse) private var settings: [UserSettings]
    @Query(sort: \MovementEntry.dateTime, order: .reverse) private var movements: [MovementEntry]

    @State private var addMovementSheet: AddMovementSheetItem? = nil
    @State private var selectedCategory: MovementEntry.MovementCategory?

    private var userSettings: UserSettings? {
        settings.first
    }

    private var currentPhase: CyclePhase {
        userSettings?.currentPhase ?? .follicular
    }

    private var todayMovements: [MovementEntry] {
        let today = Calendar.current.startOfDay(for: Date())
        return movements.filter { Calendar.current.isDate($0.dateTime, inSameDayAs: today) }
    }

    private var todayMinutes: Int {
        todayMovements.compactMap { $0.durationMinutes }.reduce(0, +)
    }

    private var todayCaloriesBurned: Int {
        todayMovements.compactMap { $0.estimatedCaloriesBurned }.reduce(0, +)
    }

    /// Weekly stats
    private var weekMovements: [MovementEntry] {
        let cal = Calendar.current
        let now = Date()
        let weekday = cal.component(.weekday, from: now)
        let startOfWeek = cal.date(byAdding: .day, value: -(weekday - 1), to: cal.startOfDay(for: now))!
        return movements.filter { $0.dateTime >= startOfWeek }
    }

    private var weekSessions: Int { weekMovements.count }

    private var weekHours: Double {
        Double(weekMovements.compactMap { $0.durationMinutes }.reduce(0, +)) / 60.0
    }

private var weekDateRange: String {
        let cal = Calendar.current
        let now = Date()
        let weekday = cal.component(.weekday, from: now)
        let start = cal.date(byAdding: .day, value: -(weekday - 1), to: cal.startOfDay(for: now))!
        let end = cal.date(byAdding: .day, value: 6, to: start)!
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return "\(f.string(from: start))-\(Calendar.current.component(.day, from: end))"
    }

    /// Most recent movement with mood tag
    private var recentMovement: MovementEntry? {
        movements.first
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ClioTheme.background
                    .withGrain(opacity: 0.025)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: ClioTheme.spacingLarge) {
                        // Hero illustration
                        moveHero
                            .padding(.horizontal, -ClioTheme.spacing)

                        // Weekly stats bar
                        weeklyStatsBar
                            .fadeInFromBottom(delay: 0.05)

                        // Log Movement section label + colored tiles
                        movementTilesSection
                            .fadeInFromBottom(delay: 0.1)

                        // Recent section
                        recentSection
                            .fadeInFromBottom(delay: 0.15)
                    }
                    .padding(.horizontal, ClioTheme.spacing)
                    .padding(.bottom, 100)
                }
                .scrollContentBackground(.hidden)
                .ignoresSafeArea(edges: .top)
            }
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $addMovementSheet) { item in
                AddMovementView(preselectedType: item.preselectedType, preselectedCategory: item.preselectedCategory)
            }
            .sheet(item: $selectedCategory) { category in
                CategorySubtypesSheet(category: category) { type in
                    selectedCategory = nil
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        addMovementSheet = AddMovementSheetItem(preselectedType: type, preselectedCategory: nil)
                    }
                }
            }
        }
    }

    // MARK: - Move Hero Illustration
    private var moveHero: some View {
        ZStack(alignment: .bottomLeading) {
            // Solid background to prevent any flash
            ClioTheme.background
                .frame(height: 360)

            // Full illustration - aligned to BOTTOM to show person
            loadBundleImage("hiking-ovulation")
                .resizable()
                .scaledToFill()
                .frame(height: 360, alignment: .bottom)
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
                Text("Movement")
                    .font(ClioTheme.headingFont(22))
                    .foregroundStyle(ClioTheme.text)

                Text("Move in ways that feel good")
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

    private func deleteMovement(_ movement: MovementEntry) {
        modelContext.delete(movement)
        try? modelContext.save()
    }

    // MARK: - Weekly Stats Bar
    private var weeklyStatsBar: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("THIS WEEK")
                    .font(ClioTheme.captionFont(11))
                    .fontWeight(.medium)
                    .foregroundStyle(ClioTheme.textMuted)
                    .tracking(0.5)

                Spacer()

                Text(weekDateRange)
                    .font(ClioTheme.captionFont(12))
                    .foregroundStyle(ClioTheme.textMuted)
            }

            HStack(spacing: 0) {
                // Sessions
                VStack(spacing: 4) {
                    Text("\(weekSessions)")
                        .font(ClioTheme.headingFont(28))
                        .foregroundStyle(ClioTheme.text)
                    Text("sessions")
                        .font(ClioTheme.captionFont(11))
                        .foregroundStyle(ClioTheme.textMuted)
                }
                .frame(maxWidth: .infinity)

                // Divider
                Rectangle()
                    .fill(ClioTheme.textMuted.opacity(0.15))
                    .frame(width: 1, height: 40)

                // Hours
                VStack(spacing: 4) {
                    Text(String(format: "%.1f", weekHours))
                        .font(ClioTheme.headingFont(28))
                        .foregroundStyle(ClioTheme.text)
                    Text("hours")
                        .font(ClioTheme.captionFont(11))
                        .foregroundStyle(ClioTheme.textMuted)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 16)
            .background(ClioTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    // MARK: - Movement Tiles (colored earth tone grid)
    private struct MoveTileOption: Identifiable {
        let label: String
        let subtitle: String
        let icon: String
        let color: Color
        let category: MovementEntry.MovementCategory
        var id: String { label }
    }

    private var moveTileOptions: [MoveTileOption] {
        [
            MoveTileOption(label: "Yoga", subtitle: "Stretch and breathe", icon: "figure.yoga", color: ClioTheme.sage, category: .flexibility),
            MoveTileOption(label: "Strength", subtitle: "Weights or bodyweight", icon: "dumbbell.fill", color: ClioTheme.terracotta, category: .strength),
            MoveTileOption(label: "Walk", subtitle: "Outdoor or treadmill", icon: "figure.walk", color: Color(hex: "B8A99A"), category: .cardio),
            MoveTileOption(label: "Other", subtitle: "Dance, swim, cycle", icon: "figure.run", color: Color(hex: "B07878"), category: .custom),
        ]
    }

    private var movementTilesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("LOG MOVEMENT")
                .font(ClioTheme.captionFont(11))
                .fontWeight(.medium)
                .foregroundStyle(ClioTheme.textMuted)
                .tracking(0.5)

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                ForEach(moveTileOptions) { option in
                    Button {
                        handleMoveTileTap(option)
                    } label: {
                        VStack(alignment: .leading, spacing: 10) {
                            Image(systemName: option.icon)
                                .font(.system(size: 22, weight: .medium))
                                .foregroundStyle(.white)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(option.label)
                                    .font(ClioTheme.labelFont(15))
                                    .foregroundStyle(.white)

                                Text(option.subtitle)
                                    .font(ClioTheme.captionFont(11))
                                    .foregroundStyle(.white.opacity(0.75))
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .frame(height: 110)
                        .background(option.color)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
        }
    }

    private func handleMoveTileTap(_ option: MoveTileOption) {
        let category = option.category
        let types = category.movementTypes
        if types.count == 1, let type = types.first {
            addMovementSheet = AddMovementSheetItem(preselectedType: type, preselectedCategory: category)
        } else {
            selectedCategory = category
        }
    }

    // MARK: - Recent Section
    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("RECENT")
                    .font(ClioTheme.captionFont(11))
                    .fontWeight(.medium)
                    .foregroundStyle(ClioTheme.textMuted)
                    .tracking(0.5)

                Spacer()

                Text("View all")
                    .font(ClioTheme.captionFont(12))
                    .foregroundStyle(ClioTheme.moveColor)
            }

            if let recent = recentMovement {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(ClioTheme.moveColor.opacity(0.12))
                            .frame(width: 40, height: 40)

                        Image(systemName: recent.movementType?.icon ?? "figure.run")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(ClioTheme.moveColor)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(recent.type)
                            .font(ClioTheme.labelFont(15))
                            .foregroundStyle(ClioTheme.text)

                        HStack(spacing: 6) {
                            if Calendar.current.isDateInToday(recent.dateTime) {
                                Text("Today")
                                    .font(ClioTheme.captionFont(12))
                                    .foregroundStyle(ClioTheme.textMuted)
                            } else {
                                Text("Yesterday")
                                    .font(ClioTheme.captionFont(12))
                                    .foregroundStyle(ClioTheme.textMuted)
                            }

                            if let mins = recent.durationMinutes {
                                Text("· \(mins) min")
                                    .font(ClioTheme.captionFont(12))
                                    .foregroundStyle(ClioTheme.textMuted)
                            }
                        }
                    }

                    Spacer()

                    // Mood tag
                    if recent.hasFeelData {
                        let positive = recent.feelAfter.compactMap { MovementEntry.FeelAfter(rawValue: $0) }.filter { $0.isPositive }.count
                        let total = recent.feelAfter.count
                        let isGood = positive > total / 2
                        Text(isGood ? "Great" : "Tough")
                            .font(ClioTheme.captionFont(11))
                            .foregroundStyle(isGood ? ClioTheme.sage : ClioTheme.terracotta)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background((isGood ? ClioTheme.sage : ClioTheme.terracotta).opacity(0.12))
                            .clipShape(Capsule())

                        Text("energy")
                            .font(ClioTheme.captionFont(10))
                            .foregroundStyle(ClioTheme.textMuted)
                    }
                }
                .padding(14)
                .background(ClioTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            } else {
                HStack {
                    Text("No recent activity")
                        .font(ClioTheme.captionFont(13))
                        .foregroundStyle(ClioTheme.textMuted)
                    Spacer()
                }
                .padding(14)
                .background(ClioTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
    }

}

// MARK: - Category Tile
struct CategoryTile: View {
    let category: MovementEntry.MovementCategory
    let action: () -> Void

    private var tileColor: Color {
        switch category {
        case .cardio: return Color(hex: "4A7070")      // Deep teal
        case .strength: return Color(hex: "A08070")   // Earthy brown
        case .flexibility: return Color(hex: "6B9B7A") // Warm sage
        case .lowImpact: return Color(hex: "C89898")  // Dusty rose
        case .rest: return Color(hex: "9B8FB0")       // Soft lavender
        case .custom: return ClioTheme.primary        // Primary accent
        }
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(tileColor.opacity(0.15))
                        .frame(width: 52, height: 52)

                    Image(systemName: category.icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(tileColor)
                }

                VStack(spacing: 3) {
                    Text(category.rawValue)
                        .font(ClioTheme.subheadingFont())
                        .foregroundStyle(ClioTheme.text)

                    Text(category.subtitle)
                        .font(ClioTheme.captionFont(11))
                        .foregroundStyle(ClioTheme.textMuted)
                        .lineLimit(1)
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

// MARK: - Category Subtypes Sheet
struct CategorySubtypesSheet: View {
    @Environment(\.dismiss) private var dismiss
    let category: MovementEntry.MovementCategory
    let onSelect: (MovementEntry.MovementType) -> Void

    private var tileColor: Color {
        switch category {
        case .cardio: return Color(hex: "4A7070")
        case .strength: return Color(hex: "A08070")
        case .flexibility: return Color(hex: "6B9B7A")
        case .lowImpact: return Color(hex: "C89898")
        case .rest: return Color(hex: "9B8FB0")
        case .custom: return ClioTheme.primary
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ClioTheme.background
                    .ignoresSafeArea()

                VStack(alignment: .leading, spacing: 24) {
                    // Header — padded top to clear the navigation bar close button
                    VStack(alignment: .leading, spacing: 2) {
                        Text(category.rawValue)
                            .font(ClioTheme.headingFont(22))
                            .foregroundStyle(ClioTheme.text)

                        Text(category.subtitle)
                            .font(ClioTheme.captionFont(13))
                            .foregroundStyle(ClioTheme.textMuted)
                    }
                    .padding(.top, 8)

                    // Movement type options
                    VStack(spacing: 0) {
                        ForEach(category.movementTypes) { type in
                            Button {
                                dismiss()
                                onSelect(type)
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: type.icon)
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundStyle(tileColor)
                                        .frame(width: 24)

                                    Text(type.rawValue)
                                        .font(ClioTheme.bodyFont())
                                        .foregroundStyle(ClioTheme.text)

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundStyle(ClioTheme.textLight)
                                }
                                .padding(.vertical, 14)
                            }
                            .buttonStyle(.plain)

                            if type != category.movementTypes.last {
                                Divider()
                                    .background(ClioTheme.textMuted.opacity(0.2))
                            }
                        }
                    }
                    .padding(.horizontal, ClioTheme.spacing)
                    .background(ClioTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    Spacer()
                }
                .padding(ClioTheme.spacing)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    ClioCloseButton { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Movement Type Chip
struct MovementTypeChip: View {
    let type: MovementEntry.MovementType
    var colorIndex: Int = 0
    let action: () -> Void

    // Movement type colors
    private static let cardioTeal = Color(hex: "4A7070")
    private static let yogaSage = Color(hex: "6B9B7A")
    private static let waterBlue = Color(hex: "7A9EB0")
    private static let strengthBrown = Color(hex: "A08070")
    private static let restRose = Color(hex: "C89898")

    private var accentColor: Color {
        let name = type.rawValue.lowercased()

        if name.contains("yoga") || name.contains("stretch") || name.contains("pilates") {
            return Self.yogaSage
        }
        if name.contains("run") || name.contains("hiit") || name.contains("cycling") ||
           name.contains("cardio") || name.contains("dance") {
            return Self.cardioTeal
        }
        if name.contains("swim") {
            return Self.waterBlue
        }
        if name.contains("strength") || name.contains("weight") || name.contains("crossfit") {
            return Self.strengthBrown
        }
        if name.contains("walk") || name.contains("hike") || name.contains("other") {
            return Self.restRose
        }
        return ClioTheme.moveColor
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: type.icon)
                    .font(.system(size: 12, weight: .medium))
                    .frame(width: 14, height: 14)
                    .foregroundStyle(accentColor)

                Text(type.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(ClioTheme.text)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(ClioTheme.surface)
            .clipShape(Capsule())
        }
        .buttonStyle(TipChipButtonStyle())
    }
}

// MARK: - Suggested Tip Chip (smaller, secondary style)
struct SuggestedTipChip: View {
    let tip: PhaseTip
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: tip.icon)
                    .font(.system(size: 11, weight: .medium))
                    .frame(width: 12, height: 12)
                    .foregroundStyle(ClioTheme.textMuted)

                Text(tip.name)
                    .font(ClioTheme.captionFont(11))
                    .foregroundStyle(ClioTheme.textMuted)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(ClioTheme.surfaceHighlight.opacity(0.6))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Movement Log Row
struct MovementLogRow: View {
    let movement: MovementEntry
    let showCalories: Bool
    var onDelete: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 12) {
            // Movement type icon
            ZStack {
                Circle()
                    .fill(ClioTheme.moveColor.opacity(0.15))
                    .frame(width: 36, height: 36)

                Image(systemName: movement.movementType?.icon ?? "figure.run")
                    .font(.system(size: 14))
                    .foregroundStyle(ClioTheme.moveColor)
            }

            // Movement info
            VStack(alignment: .leading, spacing: 2) {
                Text(movement.type)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(ClioTheme.text)

                HStack(spacing: 8) {
                    if let duration = movement.durationMinutes {
                        Text("\(duration) min")
                            .font(.caption)
                            .foregroundStyle(ClioTheme.textMuted)
                    }

                    if showCalories, let calories = movement.estimatedCaloriesBurned {
                        if movement.durationMinutes != nil {
                            Text("·")
                                .foregroundStyle(ClioTheme.textMuted)
                        }
                        Text("~\(calories) cal")
                            .font(.caption)
                            .foregroundStyle(ClioTheme.textMuted)
                    }
                }
            }

            Spacer()

            // Feel after indicator
            if movement.hasFeelData {
                let positive = movement.feelAfter.compactMap { MovementEntry.FeelAfter(rawValue: $0) }.filter { $0.isPositive }.count
                let total = movement.feelAfter.count

                Circle()
                    .fill(positive > total / 2 ? ClioTheme.success : ClioTheme.neutral)
                    .frame(width: 8, height: 8)
            }

            // Delete button
            if let onDelete = onDelete {
                Button {
                    onDelete()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(ClioTheme.textMuted.opacity(0.5))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Movement Tip Detail Sheet
struct MovementTipDetailSheet: View {
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
                                    .fill(ClioTheme.moveColor.opacity(0.15))
                                    .frame(width: 80, height: 80)

                                Image(systemName: tip.icon)
                                    .font(.system(size: 32, weight: .medium))
                                    .frame(width: 40, height: 40)
                                    .foregroundStyle(ClioTheme.moveColor)
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
                            Text("Why it works")
                                .font(.headline)
                                .foregroundStyle(ClioTheme.text)

                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(tip.whyBenefits, id: \.self) { benefit in
                                    HStack(alignment: .top, spacing: 8) {
                                        Circle()
                                            .fill(ClioTheme.moveColor)
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
                            Text("How to do it")
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
                    Text("Log this workout")
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
    MoveView()
        .modelContainer(for: [UserSettings.self, MovementEntry.self], inMemory: true)
}
