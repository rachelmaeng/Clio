import SwiftUI

// MARK: - Helper to load bundled images
private func loadBundleImage(_ name: String) -> Image {
    if let uiImage = UIImage(named: name) {
        return Image(uiImage: uiImage)
    } else if let path = Bundle.main.path(forResource: name, ofType: "png"),
              let uiImage = UIImage(contentsOfFile: path) {
        return Image(uiImage: uiImage)
    }
    return Image(systemName: "photo")
}

/// A hero component that displays phase-appropriate illustrations
/// Uses the pointillist-style images: yoga-follicular, contemplation-luteal,
/// eating-healthy, hiking-ovulation, eating-menstrual
struct PhaseHeroView: View {
    let phase: CyclePhase
    var height: CGFloat = 200
    var showPhaseLabel: Bool = true

    // Static image for Home - will add phase-specific images later
    private var imageName: String {
        return "eating-menstrual"
    }

    private var phaseMessage: String {
        switch phase {
        case .menstrual: return "Nourish yourself gently"
        case .follicular: return "Energy is building"
        case .ovulation: return "You're at your peak"
        case .luteal: return "Time for reflection"
        }
    }

    var body: some View {
        GeometryReader { geo in
            let safeAreaTop = geo.safeAreaInsets.top

            ZStack(alignment: .bottomLeading) {
                // Full illustration - aligned to BOTTOM to show person
                loadBundleImage(imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: height + safeAreaTop, alignment: .bottom)
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
                .frame(height: 60)
                .frame(maxHeight: .infinity, alignment: .bottom)
            }
            .frame(width: geo.size.width, height: height + safeAreaTop)
            .offset(y: -safeAreaTop) // Pull up into safe area
        }
        .frame(height: height)
        .frame(maxWidth: .infinity)
        .clipped()
    }
}


/// A compact phase indicator with illustration thumbnail
struct PhaseIndicatorCompact: View {
    let phase: CyclePhase
    let dayOfCycle: Int?

    private var imageName: String {
        switch phase {
        case .menstrual: return "eating-menstrual"
        case .follicular: return "yoga-follicular"
        case .ovulation: return "hiking-ovulation"
        case .luteal: return "contemplation-luteal"
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // Small illustration thumbnail
            loadBundleImage(imageName)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 48, height: 48)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(ClioTheme.phaseColor(for: phase), lineWidth: 2)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(phase.description)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(ClioTheme.text)

                if let day = dayOfCycle {
                    Text("Day \(day)")
                        .font(.caption)
                        .foregroundStyle(ClioTheme.textMuted)
                }
            }

            Spacer()

            // Phase color indicator
            Circle()
                .fill(ClioTheme.phaseColor(for: phase))
                .frame(width: 12, height: 12)
        }
        .padding()
        .background(ClioTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

/// Category-specific hero for Eat, Move sections
struct CategoryHeroView: View {
    enum Category {
        case eat
        case move

        var imageName: String {
            switch self {
            case .eat: return "eating-healthy"
            case .move: return "yoga-follicular"
            }
        }

        var color: Color {
            switch self {
            case .eat: return ClioTheme.eatColor
            case .move: return ClioTheme.moveColor
            }
        }
    }

    let category: Category
    let title: String
    let subtitle: String
    var height: CGFloat = 140

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Solid background to prevent any flash
            ClioTheme.background
                .frame(height: height)

            // Full illustration - edge to edge, rounded top corners
            loadBundleImage(category.imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: ClioTheme.cornerRadius,
                        bottomLeadingRadius: 0,
                        bottomTrailingRadius: 0,
                        topTrailingRadius: ClioTheme.cornerRadius
                    )
                )
                .overlay(
                    GrainTexture(opacity: 0.05)
                        .blendMode(.overlay)
                        .clipShape(
                            UnevenRoundedRectangle(
                                topLeadingRadius: ClioTheme.cornerRadius,
                                bottomLeadingRadius: 0,
                                bottomTrailingRadius: 0,
                                topTrailingRadius: ClioTheme.cornerRadius
                            )
                        )
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
            .frame(height: 100)
            .frame(maxHeight: .infinity, alignment: .bottom)

            // Text - more visible
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(ClioTheme.headingFont(18))
                    .foregroundStyle(ClioTheme.text)

                Text(subtitle)
                    .font(ClioTheme.captionFont(12))
                    .foregroundStyle(ClioTheme.textMuted)
            }
            .padding(.horizontal, ClioTheme.spacing)
            .padding(.bottom, ClioTheme.spacingSmall)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        PhaseHeroView(phase: .follicular)

        PhaseIndicatorCompact(phase: .ovulation, dayOfCycle: 14)

        CategoryHeroView(
            category: .eat,
            title: "Log a meal",
            subtitle: "Track your nourishment"
        )
    }
    .padding()
    .background(ClioTheme.background)
}
