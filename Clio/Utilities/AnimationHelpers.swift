import SwiftUI

// Custom spring animations for Clio
extension Animation {
    static let clioSpring = Animation.spring(response: 0.4, dampingFraction: 0.75)
    static let clioQuick = Animation.spring(response: 0.25, dampingFraction: 0.8)
    static let clioGentle = Animation.spring(response: 0.6, dampingFraction: 0.85)
    static let clioBouncy = Animation.spring(response: 0.35, dampingFraction: 0.6)
    static let clioSmooth = Animation.easeInOut(duration: 0.3)
}

// MARK: - Interactive Card Style
struct InteractiveCardStyle: ButtonStyle {
    let cornerRadius: CGFloat

    init(cornerRadius: CGFloat = 20) {
        self.cornerRadius = cornerRadius
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .brightness(configuration.isPressed ? -0.02 : 0)
            .animation(.clioQuick, value: configuration.isPressed)
    }
}

// MARK: - Breathing Glow Effect
struct BreathingGlow: ViewModifier {
    let color: Color
    @State private var isGlowing = false

    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(isGlowing ? 0.4 : 0.15), radius: isGlowing ? 20 : 10, y: isGlowing ? 8 : 4)
            .onAppear {
                withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                    isGlowing = true
                }
            }
    }
}

extension View {
    func breathingGlow(color: Color = ClioTheme.primary) -> some View {
        modifier(BreathingGlow(color: color))
    }
}

// MARK: - Success Checkmark Animation
struct AnimatedCheckmark: View {
    @State private var trimEnd: CGFloat = 0
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0
    let color: Color
    let size: CGFloat

    init(color: Color = ClioTheme.primary, size: CGFloat = 60) {
        self.color = color
        self.size = size
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.2))
                .frame(width: size, height: size)

            Circle()
                .stroke(color, lineWidth: 3)
                .frame(width: size, height: size)

            Path { path in
                path.move(to: CGPoint(x: size * 0.25, y: size * 0.5))
                path.addLine(to: CGPoint(x: size * 0.42, y: size * 0.65))
                path.addLine(to: CGPoint(x: size * 0.75, y: size * 0.35))
            }
            .trim(from: 0, to: trimEnd)
            .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
            .frame(width: size, height: size)
        }
        .scaleEffect(scale)
        .opacity(opacity)
        .onAppear {
            withAnimation(.clioBouncy.delay(0.1)) {
                scale = 1.0
                opacity = 1.0
            }
            withAnimation(.easeOut(duration: 0.4).delay(0.3)) {
                trimEnd = 1.0
            }
        }
    }
}

// MARK: - Floating Particles (Celebration)
struct FloatingParticle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    let size: CGFloat
    let color: Color
    let delay: Double
}

struct CelebrationParticles: View {
    @State private var particles: [FloatingParticle] = []
    @State private var animate = false
    let colors: [Color]

    init(colors: [Color] = [ClioTheme.primary, ClioTheme.terracotta, ClioTheme.success]) {
        self.colors = colors
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(particle.color)
                        .frame(width: particle.size, height: particle.size)
                        .position(
                            x: particle.x,
                            y: animate ? -50 : particle.y
                        )
                        .opacity(animate ? 0 : 1)
                        .animation(
                            .easeOut(duration: 1.5).delay(particle.delay),
                            value: animate
                        )
                }
            }
            .onAppear {
                // Generate particles
                for i in 0..<12 {
                    particles.append(FloatingParticle(
                        x: CGFloat.random(in: 20...(geo.size.width - 20)),
                        y: geo.size.height + 20,
                        size: CGFloat.random(in: 6...12),
                        color: colors.randomElement() ?? ClioTheme.primary,
                        delay: Double(i) * 0.05
                    ))
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    animate = true
                }
            }
        }
    }
}

// MARK: - Animated Counter
struct AnimatedCounter: View {
    let value: Int
    let font: Font
    let color: Color

    @State private var displayedValue: Int = 0

    var body: some View {
        Text("\(displayedValue)")
            .font(font)
            .foregroundStyle(color)
            .contentTransition(.numericText())
            .onChange(of: value) { oldValue, newValue in
                withAnimation(.clioSpring) {
                    displayedValue = newValue
                }
            }
            .onAppear {
                withAnimation(.clioSpring.delay(0.2)) {
                    displayedValue = value
                }
            }
    }
}

// MARK: - Slide In Effect
struct SlideIn: ViewModifier {
    @State private var isVisible = false
    let edge: Edge
    let delay: Double

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(
                x: isVisible ? 0 : (edge == .leading ? -30 : (edge == .trailing ? 30 : 0)),
                y: isVisible ? 0 : (edge == .top ? -30 : (edge == .bottom ? 30 : 0))
            )
            .onAppear {
                withAnimation(.clioSpring.delay(delay)) {
                    isVisible = true
                }
            }
    }
}

extension View {
    func slideIn(from edge: Edge, delay: Double = 0) -> some View {
        modifier(SlideIn(edge: edge, delay: delay))
    }
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
