import SwiftUI
import SwiftData

struct MoveView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \UserSettings.createdAt, order: .reverse) private var settings: [UserSettings]
    @Query(sort: \MovementEntry.dateTime, order: .reverse) private var movements: [MovementEntry]

    @State private var showAddMovement = false
    @State private var selectedTip: PhaseTip?
    @State private var selectedMovementType: MovementEntry.MovementType?
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

    var body: some View {
        NavigationStack {
            ZStack {
                ClioTheme.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Hero illustration - full width
                        moveHero
                            .padding(.horizontal, -ClioTheme.spacing)
                            .fadeInFromBottom(delay: 0)

                        // Header with phase context
                        phaseHeader
                            .fadeInFromBottom(delay: 0.05)

                        // Today's Log Section
                        if !todayMovements.isEmpty {
                            todayLogSection
                                .fadeInFromBottom(delay: 0.1)
                        }

                        // Category Tiles (2x3 grid)
                        categoryGrid
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
                        showAddMovement = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(ClioTheme.moveColor)
                    }
                }
            }
            .sheet(isPresented: $showAddMovement) {
                AddMovementView()
            }
            .sheet(item: $selectedTip) { tip in
                MovementTipDetailSheet(tip: tip, onLog: {
                    logFromTip(tip)
                })
            }
            .sheet(item: $selectedMovementType) { type in
                AddMovementView(preselectedType: type)
            }
            .sheet(item: $selectedCategory) { category in
                CategorySubtypesSheet(category: category) { type in
                    selectedCategory = nil
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        selectedMovementType = type
                    }
                }
            }
        }
    }

    // MARK: - Move Hero Illustration
    private var moveHero: some View {
        ZStack(alignment: .bottomLeading) {
            // Full illustration - extends to top edge
            loadBundleImage("hiking-ovulation")
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

    // MARK: - Phase Header
    private var phaseHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Move")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(ClioTheme.text)

                Spacer()

                // Today's summary
                if todayMinutes > 0 {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(todayMinutes) min")
                            .font(.headline)
                            .foregroundStyle(ClioTheme.text)

                        if userSettings?.showCalorieBurnEstimate == true && todayCaloriesBurned > 0 {
                            Text("~\(todayCaloriesBurned) cal burned")
                                .font(.caption)
                                .foregroundStyle(ClioTheme.textMuted)
                        }
                    }
                }
            }

            // Phase context - subtle
            HStack(spacing: 6) {
                Circle()
                    .fill(ClioTheme.phaseColor(for: currentPhase))
                    .frame(width: 8, height: 8)

                Text(currentPhase.description)
                    .font(.subheadline)
                    .foregroundStyle(ClioTheme.textMuted)

                Text("·")
                    .foregroundStyle(ClioTheme.textMuted)

                Text(phaseMovementContext)
                    .font(.caption)
                    .foregroundStyle(ClioTheme.textMuted)
            }
        }
    }

    private var phaseMovementContext: String {
        switch currentPhase {
        case .menstrual:
            return "Gentle movement"
        case .follicular:
            return "Try new challenges"
        case .ovulation:
            return "Peak energy"
        case .luteal:
            return "Moderate intensity"
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

                Text("\(todayMovements.count) workout\(todayMovements.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(ClioTheme.textMuted)
            }

            VStack(spacing: 0) {
                ForEach(todayMovements.prefix(5), id: \.id) { movement in
                    MovementLogRow(
                        movement: movement,
                        showCalories: userSettings?.showCalorieBurnEstimate ?? true,
                        onDelete: { deleteMovement(movement) }
                    )
                    .padding(.vertical, 8)

                    if movement.id != todayMovements.prefix(5).last?.id {
                        Divider()
                            .background(ClioTheme.textMuted.opacity(0.2))
                    }
                }
            }
            .padding()
            .background(ClioTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    private func deleteMovement(_ movement: MovementEntry) {
        modelContext.delete(movement)
        try? modelContext.save()
    }

    // MARK: - Category Grid
    private var categoryGrid: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Log a workout")
                .font(ClioTheme.subheadingFont())
                .foregroundStyle(ClioTheme.text)

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                ForEach(MovementEntry.MovementCategory.allCases) { category in
                    CategoryTile(category: category) {
                        handleCategoryTap(category)
                    }
                }
            }
        }
    }

    private func handleCategoryTap(_ category: MovementEntry.MovementCategory) {
        let types = category.movementTypes
        if types.count == 1 {
            // Go directly to AddMovementView
            selectedMovementType = types.first
        } else {
            // Show subtypes sheet
            selectedCategory = category
        }
    }

    // MARK: - Log from Tip
    private func logFromTip(_ tip: PhaseTip) {
        showAddMovement = true
        selectedTip = nil
    }

    private func quickLogMovement(_ type: MovementEntry.MovementType) {
        let movement = MovementEntry(type: type.rawValue)

        if let phase = userSettings?.currentPhase,
           let day = userSettings?.dayOfCycle {
            movement.setCycleContext(phase: phase, day: day)
        }

        modelContext.insert(movement)
        try? modelContext.save()
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
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 10) {
                            ZStack {
                                Circle()
                                    .fill(tileColor.opacity(0.15))
                                    .frame(width: 44, height: 44)

                                Image(systemName: category.icon)
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundStyle(tileColor)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(category.rawValue)
                                    .font(ClioTheme.headingFont(22))
                                    .foregroundStyle(ClioTheme.text)

                                Text(category.subtitle)
                                    .font(ClioTheme.captionFont(13))
                                    .foregroundStyle(ClioTheme.textMuted)
                            }
                        }
                    }

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
                ToolbarItem(placement: .topBarLeading) {
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
