import SwiftUI

// Custom spring animations for Clio
extension Animation {
    static let clioSpring = Animation.spring(response: 0.4, dampingFraction: 0.75)
    static let clioQuick = Animation.spring(response: 0.25, dampingFraction: 0.8)
    static let clioGentle = Animation.spring(response: 0.6, dampingFraction: 0.85)
}

// Staggered animation modifier
struct StaggeredAppearance: ViewModifier {
    let index: Int
    let delay: Double
    @State private var isVisible = false

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 20)
            .onAppear {
                withAnimation(.clioSpring.delay(Double(index) * delay)) {
                    isVisible = true
                }
            }
    }
}

extension View {
    func staggeredAppearance(index: Int, delay: Double = 0.05) -> some View {
        modifier(StaggeredAppearance(index: index, delay: delay))
    }
}

// Pulse animation for selected states
struct PulseAnimation: ViewModifier {
    @State private var isPulsing = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? 1.02 : 1.0)
            .onAppear {
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
            }
    }
}

extension View {
    func pulseAnimation() -> some View {
        modifier(PulseAnimation())
    }
}

// Shimmer effect for loading states
struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [
                        .clear,
                        Color.white.opacity(0.1),
                        .clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: phase)
                .onAppear {
                    withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                        phase = 300
                    }
                }
            )
            .mask(content)
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

// Fade in from bottom modifier
struct FadeInFromBottom: ViewModifier {
    @State private var isVisible = false
    let delay: Double

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 30)
            .onAppear {
                withAnimation(.clioGentle.delay(delay)) {
                    isVisible = true
                }
            }
    }
}

extension View {
    func fadeInFromBottom(delay: Double = 0) -> some View {
        modifier(FadeInFromBottom(delay: delay))
    }
}

// Scale on press modifier
struct ScaleOnPress: ViewModifier {
    func body(content: Content) -> some View {
        content
            .buttonStyle(ScaleButtonStyle())
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.clioQuick, value: configuration.isPressed)
    }
}

extension View {
    func scaleOnPress() -> some View {
        modifier(ScaleOnPress())
    }
}
