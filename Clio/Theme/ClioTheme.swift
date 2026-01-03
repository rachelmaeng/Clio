import SwiftUI

enum ClioTheme {
    // MARK: - Colors
    static let background = Color(hex: "121022")
    static let surface = Color(hex: "1c1a2e")
    static let surfaceHighlight = Color(hex: "252540")
    static let text = Color.white
    static let textMuted = Color(hex: "9f9db9")
    static let primary = Color(hex: "2111d4")
    static let primaryGlow = Color(hex: "2111d4").opacity(0.3)

    // MARK: - Semantic Colors (no shame, no red)
    static let accent = primary
    static let success = Color(hex: "6366f1") // Soft indigo, not harsh green
    static let neutral = textMuted

    // MARK: - Gradients
    static var ambientGradient: LinearGradient {
        LinearGradient(
            colors: [
                background,
                Color(hex: "18162e"),
                Color(hex: "211d38")
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static var primaryButtonGradient: LinearGradient {
        LinearGradient(
            colors: [primary, primary.opacity(0.8)],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    static var cardGlow: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(primary.opacity(0.1))
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
