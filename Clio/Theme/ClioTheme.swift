import SwiftUI

enum ClioTheme {
    // MARK: - Core Colors
    static let background = Color(hex: "121022")
    static let surface = Color(hex: "1c1a2e")
    static let surfaceHighlight = Color(hex: "252540")
    static let text = Color.white
    static let textMuted = Color(hex: "9f9db9")

    // MARK: - Primary (Soft Lavender)
    static let primary = Color(hex: "A78BFA")
    static let primaryGlow = Color(hex: "A78BFA").opacity(0.3)
    static let primaryDark = Color(hex: "8B5CF6")

    // MARK: - Accent Palette (Soft Pastels)
    static let coral = Color(hex: "E8B4B8")       // Dusty rose - meals/nourishment
    static let teal = Color(hex: "B8D4E3")        // Soft blue-gray - movements
    static let rose = Color(hex: "D4B8E0")        // Soft lilac - check-ins/feelings
    static let amber = Color(hex: "E0D4B8")       // Warm beige - energy
    static let sage = Color(hex: "C5D5C5")        // Muted sage - success/positive
    static let sky = Color(hex: "C5CDE0")         // Soft periwinkle - calm states
    static let peach = Color(hex: "E8D4C4")       // Soft peach - warmth

    // MARK: - Semantic Colors (no shame, no red)
    static let accent = primary
    static let success = sage
    static let neutral = textMuted

    // MARK: - Category Colors
    static let mealColor = coral
    static let movementColor = teal
    static let checkInColor = rose
    static let energyColor = amber
    static let restColor = sky

    // MARK: - Gradients
    static var ambientGradient: LinearGradient {
        LinearGradient(
            colors: [
                background,
                Color(hex: "1a1730"),
                Color(hex: "241f3d")
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static var primaryButtonGradient: LinearGradient {
        LinearGradient(
            colors: [primary, primaryDark],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    static var mealGradient: LinearGradient {
        LinearGradient(
            colors: [coral, Color(hex: "D9A5A9")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var movementGradient: LinearGradient {
        LinearGradient(
            colors: [teal, Color(hex: "A9C5D4")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var checkInGradient: LinearGradient {
        LinearGradient(
            colors: [rose, Color(hex: "C5A9D1")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var cardGlow: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(primary.opacity(0.1))
            .blur(radius: 20)
    }

    static func accentGlow(_ color: Color) -> some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(color.opacity(0.15))
            .blur(radius: 20)
    }

    // MARK: - Shadows
    static func primaryShadow() -> some View {
        Color.clear
            .shadow(color: primary.opacity(0.3), radius: 12, x: 0, y: 4)
    }

    // MARK: - Typography
    static func headingFont(_ size: CGFloat = 28) -> Font {
        .system(size: size, weight: .bold, design: .default)
    }

    static func bodyFont(_ size: CGFloat = 16) -> Font {
        .system(size: size, weight: .regular, design: .default)
    }

    static func captionFont(_ size: CGFloat = 12) -> Font {
        .system(size: size, weight: .medium, design: .default)
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

// MARK: - View Modifiers
struct ClioCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(ClioTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.05), lineWidth: 1)
            )
    }
}

struct ClioPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(ClioTheme.primary)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: ClioTheme.primary.opacity(0.4), radius: 12, x: 0, y: 4)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

extension View {
    func clioCard() -> some View {
        modifier(ClioCardStyle())
    }
}
