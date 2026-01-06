import SwiftUI

enum ClioTheme {
    // MARK: - Design Constants
    static let cornerRadius: CGFloat = 24
    static let cornerRadiusSmall: CGFloat = 16
    static let cornerRadiusLarge: CGFloat = 32
    static let spacing: CGFloat = 20
    static let spacingSmall: CGFloat = 12
    static let spacingLarge: CGFloat = 32

    // MARK: - Core Colors (Muted, Painterly Palette)
    static let background = Color(hex: "F4EBE0")        // Warm parchment cream
    static let surface = Color(hex: "FAF7F2")           // Soft warm white
    static let surfaceHighlight = Color(hex: "EFE8DE")  // Warm sand highlight
    static let text = Color(hex: "3D4A45")              // Soft forest (not harsh black)
    static let textMuted = Color(hex: "8A9590")         // Warm gray-sage
    static let textLight = Color(hex: "B0B8B4")         // Whisper gray

    // MARK: - Primary (Muted Sage - Less Saturated)
    static let primary = Color(hex: "6B9B7A")           // Softer, dustier sage
    static let primaryMuted = Color(hex: "9BB5A5")      // Desaturated sage for buttons
    static let primaryDark = Color(hex: "5A8568")       // Pressed state

    // MARK: - Accent Palette (Pulled from Illustrations - Muted)
    static let sage = Color(hex: "6B9B7A")              // Muted sage (primary)
    static let cream = Color(hex: "F4EBE0")             // Warm cream
    static let terracotta = Color(hex: "D4A090")        // Muted coral (less saturated)
    static let blush = Color(hex: "E8C8BC")             // Dusty blush
    static let sand = Color(hex: "E0D4C4")              // Warm sand
    static let linen = Color(hex: "F8F4EE")             // Soft linen
    static let honey = Color(hex: "D8C080")             // Muted golden (less yellow)
    static let rose = Color(hex: "C89898")              // Dusty rose
    static let cerulean = Color(hex: "7A9EB0")          // Muted blue
    static let teal = Color(hex: "4A7070")              // Soft teal

    // MARK: - Semantic Colors
    static let accent = sage
    static let success = Color(hex: "7A9A80")           // Muted green
    static let neutral = textMuted
    static let warning = Color(hex: "C8A080")           // Muted amber

    // MARK: - Category Colors (Distinct for each section)
    static let eatColor = terracotta    // Warm coral-brown
    static let moveColor = teal         // Cool teal (distinct from primary sage)
    static let feelColor = blush        // Soft pink
    static let insightColor = cerulean  // Muted blue
    static let cycleColor = rose        // Dusty rose

    // MARK: - Cycle Phase Colors (Muted versions)
    static let menstrualPhase = Color(hex: "D4A090")    // Muted coral
    static let follicularPhase = Color(hex: "6B9B7A")   // Muted sage
    static let ovulationPhase = Color(hex: "D8C080")    // Muted gold
    static let lutealPhase = Color(hex: "4A7070")       // Muted teal

    // MARK: - Whole Food Score Colors
    static let wholeFood = Color(hex: "7A9A80")
    static let mixedFood = Color(hex: "D8C080")
    static let processedFood = Color(hex: "B8A890")

    // MARK: - Gradients
    static var ambientGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(hex: "F4EBE0"),
                Color(hex: "F8F2EA"),
                Color(hex: "FAF7F2")
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static var cardGlow: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(sage.opacity(0.06))
            .blur(radius: 20)
    }

    static func accentGlow(_ color: Color) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(color.opacity(0.08))
            .blur(radius: 20)
    }

    // MARK: - Typography (Crimson Pro serif for headings, system for body)
    // Crimson Pro for elegant editorial feel
    static func displayFont(_ size: CGFloat = 32) -> Font {
        .custom("CrimsonPro-SemiBold", size: size)
    }

    static func headingFont(_ size: CGFloat = 24) -> Font {
        .custom("CrimsonPro-Medium", size: size)
    }

    static func subheadingFont(_ size: CGFloat = 18) -> Font {
        .custom("CrimsonPro-Regular", size: size)
    }

    // System rounded for UI elements (softer than default)
    static func bodyFont(_ size: CGFloat = 16) -> Font {
        .system(size: size, weight: .regular, design: .rounded)
    }

    static func labelFont(_ size: CGFloat = 14) -> Font {
        .system(size: size, weight: .medium, design: .rounded)
    }

    static func captionFont(_ size: CGFloat = 12) -> Font {
        .system(size: size, weight: .regular, design: .rounded)
    }

    // Section headers - sentence case, relaxed tracking
    static func sectionHeaderFont() -> Font {
        .system(size: 13, weight: .medium, design: .rounded)
    }

    // MARK: - Cycle Phase Helpers
    static func phaseColor(for phase: CyclePhase) -> Color {
        switch phase {
        case .menstrual: return menstrualPhase
        case .follicular: return follicularPhase
        case .ovulation: return ovulationPhase
        case .luteal: return lutealPhase
        }
    }

    static func phaseName(for phase: CyclePhase) -> String {
        switch phase {
        case .menstrual: return "Menstrual"
        case .follicular: return "Follicular"
        case .ovulation: return "Ovulation"
        case .luteal: return "Luteal"
        }
    }
}

// MARK: - Cycle Phase Enum
enum CyclePhase: String, CaseIterable, Codable, Identifiable {
    case menstrual
    case follicular
    case ovulation
    case luteal

    var id: String { rawValue }

    var description: String {
        switch self {
        case .menstrual: return "Menstrual Phase"
        case .follicular: return "Follicular Phase"
        case .ovulation: return "Ovulation Phase"
        case .luteal: return "Luteal Phase"
        }
    }

    var shortDescription: String {
        switch self {
        case .menstrual: return "Days 1-5"
        case .follicular: return "Days 6-13"
        case .ovulation: return "Days 14-16"
        case .luteal: return "Days 17-28"
        }
    }

    var bodyContext: String {
        switch self {
        case .menstrual:
            return "Energy tends to be lower. Your body is shedding its uterine lining."
        case .follicular:
            return "Energy builds as estrogen rises. Good time for new challenges."
        case .ovulation:
            return "Peak energy window. Estrogen and testosterone are highest."
        case .luteal:
            return "Progesterone rises, energy may dip. Cravings are normal."
        }
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Grain Texture Overlay (Painterly effect)
struct GrainTexture: View {
    var opacity: Double = 0.08  // 8-10% for visible painterly grain

    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                // Denser grain pattern for painterly texture
                for _ in 0..<Int(size.width * size.height * 0.025) {
                    let x = CGFloat.random(in: 0...size.width)
                    let y = CGFloat.random(in: 0...size.height)
                    let dotSize = CGFloat.random(in: 0.8...2.0)
                    let dotOpacity = Double.random(in: 0.4...1.0)

                    context.fill(
                        Path(ellipseIn: CGRect(x: x, y: y, width: dotSize, height: dotSize)),
                        with: .color(Color.black.opacity(dotOpacity))
                    )
                }
            }
        }
        .opacity(opacity)
        .allowsHitTesting(false)
    }
}

struct GrainOverlay: ViewModifier {
    var opacity: Double = 0.08

    func body(content: Content) -> some View {
        content.overlay(
            GrainTexture(opacity: opacity)
                .blendMode(.multiply)
        )
    }
}

extension View {
    func withGrain(opacity: Double = 0.08) -> some View {
        modifier(GrainOverlay(opacity: opacity))
    }
}

// MARK: - View Modifiers

/// Card with subtle grain texture and soft shadow
struct ClioCardStyle: ViewModifier {
    var withGrain: Bool = true

    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    ClioTheme.surface
                    if withGrain {
                        GrainTexture(opacity: 0.02)
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: ClioTheme.cornerRadius, style: .continuous))
            .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
            .shadow(color: Color.black.opacity(0.02), radius: 20, x: 0, y: 8)
    }
}

/// Primary button - muted, organic feel
struct ClioPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(ClioTheme.labelFont(16))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                ZStack {
                    ClioTheme.primaryMuted  // More muted sage for less saturation
                    GrainTexture(opacity: 0.03)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: ClioTheme.cornerRadius, style: .continuous))
            .shadow(color: ClioTheme.primaryMuted.opacity(0.15), radius: 8, x: 0, y: 4)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

/// Secondary button - subtle, surface-level
struct ClioSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(ClioTheme.labelFont(15))
            .foregroundStyle(ClioTheme.text)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(ClioTheme.surfaceHighlight)
            .clipShape(RoundedRectangle(cornerRadius: ClioTheme.cornerRadiusSmall, style: .continuous))
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

/// Soft chip/tag style - organic pill shape
struct ClioChipStyle: ButtonStyle {
    var isSelected: Bool = false
    var accentColor: Color = ClioTheme.sage

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(ClioTheme.captionFont(13))
            .foregroundStyle(isSelected ? accentColor : ClioTheme.textMuted)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                isSelected
                    ? accentColor.opacity(0.12)
                    : ClioTheme.surfaceHighlight
            )
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isSelected ? accentColor.opacity(0.2) : Color.clear, lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

/// Soft close button (X) - subtle and unobtrusive
struct ClioCloseButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(ClioTheme.textLight.opacity(0.5))
                .frame(width: 32, height: 32)
        }
        .buttonStyle(.plain)
    }
}

/// Section header with softer styling
struct ClioSectionHeader: View {
    let title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(ClioTheme.captionFont(12))
                .foregroundStyle(ClioTheme.textMuted)
                .textCase(nil) // No forced uppercase

            if let subtitle = subtitle {
                Text(subtitle)
                    .font(ClioTheme.headingFont(20))
                    .foregroundStyle(ClioTheme.text)
            }
        }
    }
}

extension View {
    func clioCard(withGrain: Bool = true) -> some View {
        modifier(ClioCardStyle(withGrain: withGrain))
    }
}

// MARK: - Fade to Background Effect
/// Makes images fade into the background with soft edges (no hard corners)
struct FadeToBackgroundModifier: ViewModifier {
    var fadeAmount: CGFloat = 0.3  // How much of edges to fade (0-0.5)
    var grainOpacity: Double = 0.1

    func body(content: Content) -> some View {
        content
            .mask(
                // Radial gradient mask for soft edges
                RadialGradient(
                    gradient: Gradient(stops: [
                        .init(color: .white, location: 0),
                        .init(color: .white, location: 1 - fadeAmount),
                        .init(color: .clear, location: 1)
                    ]),
                    center: .center,
                    startRadius: 0,
                    endRadius: UIScreen.main.bounds.width * 0.7
                )
            )
            .overlay(
                GrainTexture(opacity: grainOpacity)
                    .blendMode(.overlay)
            )
    }
}

/// Vertical fade for hero images (fades top and bottom edges)
struct VerticalFadeModifier: ViewModifier {
    var fadeTop: CGFloat = 0.1
    var fadeBottom: CGFloat = 0.25
    var grainOpacity: Double = 0.1

    func body(content: Content) -> some View {
        content
            .mask(
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0),
                        .init(color: .white, location: fadeTop),
                        .init(color: .white, location: 1 - fadeBottom),
                        .init(color: .clear, location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay(
                GrainTexture(opacity: grainOpacity)
                    .blendMode(.overlay)
            )
    }
}

/// All-edges fade for hero images
struct EdgeFadeModifier: ViewModifier {
    var edgeFade: CGFloat = 0.15
    var grainOpacity: Double = 0.1

    func body(content: Content) -> some View {
        let horizontalGradient = LinearGradient(
            stops: [
                .init(color: .clear, location: 0),
                .init(color: .white, location: edgeFade),
                .init(color: .white, location: 1 - edgeFade),
                .init(color: .clear, location: 1)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )

        let verticalGradient = LinearGradient(
            stops: [
                .init(color: .clear, location: 0),
                .init(color: .white, location: edgeFade),
                .init(color: .white, location: 1 - edgeFade * 1.5),
                .init(color: .clear, location: 1)
            ],
            startPoint: .top,
            endPoint: .bottom
        )

        content
            .mask(horizontalGradient)
            .mask(verticalGradient)
            .overlay(
                GrainTexture(opacity: grainOpacity)
                    .blendMode(.overlay)
            )
    }
}

extension View {
    /// Fades all edges into background with soft vignette
    func fadeToBackground(amount: CGFloat = 0.3, grainOpacity: Double = 0.1) -> some View {
        modifier(FadeToBackgroundModifier(fadeAmount: amount, grainOpacity: grainOpacity))
    }

    /// Fades top and bottom edges for hero images
    func fadeVertically(top: CGFloat = 0.1, bottom: CGFloat = 0.25, grainOpacity: Double = 0.1) -> some View {
        modifier(VerticalFadeModifier(fadeTop: top, fadeBottom: bottom, grainOpacity: grainOpacity))
    }

    /// Fades all four edges softly
    func fadeEdges(amount: CGFloat = 0.15, grainOpacity: Double = 0.1) -> some View {
        modifier(EdgeFadeModifier(edgeFade: amount, grainOpacity: grainOpacity))
    }
}
