import SwiftUI

struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @State private var currentPage = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "sparkles",
            title: "Welcome to Clio",
            subtitle: "A mindful space for noticing your body, movement, and nourishment.",
            color: ClioTheme.primary
        ),
        OnboardingPage(
            icon: "heart.fill",
            title: "Awareness, not perfection",
            subtitle: "There are no streaks to maintain, no goals to hit. Just gentle noticing.",
            color: Color(hex: "E91E63")
        ),
        OnboardingPage(
            icon: "leaf.fill",
            title: "Your pace, your way",
            subtitle: "Log what feels right. Skip what doesn't. Clio adapts to you.",
            color: Color(hex: "2DD4BF")
        ),
        OnboardingPage(
            icon: "eye.fill",
            title: "Patterns emerge naturally",
            subtitle: "Over time, you'll see reflections based on what you notice. No judgment, just insight.",
            color: Color(hex: "818CF8")
        )
    ]

    var body: some View {
        ZStack {
            ClioTheme.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Page content
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        OnboardingPageView(page: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)

                Spacer()

                // Page indicators
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Capsule()
                            .fill(index == currentPage ? ClioTheme.primary : ClioTheme.textMuted.opacity(0.3))
                            .frame(width: index == currentPage ? 24 : 8, height: 8)
                            .animation(.spring(response: 0.3), value: currentPage)
                    }
                }
                .padding(.bottom, 32)

                // Continue button
                Button {
                    HapticFeedback.medium.trigger()
                    if currentPage < pages.count - 1 {
                        withAnimation {
                            currentPage += 1
                        }
                    } else {
                        withAnimation(.spring(response: 0.4)) {
                            hasCompletedOnboarding = true
                        }
                    }
                } label: {
                    HStack {
                        Text(currentPage < pages.count - 1 ? "Continue" : "Begin")
                        Image(systemName: currentPage < pages.count - 1 ? "arrow.right" : "sparkles")
                    }
                }
                .buttonStyle(ClioPrimaryButtonStyle())
                .padding(.horizontal)
                .padding(.bottom, 20)

                // Skip option
                if currentPage < pages.count - 1 {
                    Button {
                        HapticFeedback.light.trigger()
                        withAnimation(.spring(response: 0.4)) {
                            hasCompletedOnboarding = true
                        }
                    } label: {
                        Text("Skip")
                            .font(.subheadline)
                            .foregroundStyle(ClioTheme.textMuted)
                    }
                    .padding(.bottom, 32)
                } else {
                    Spacer()
                        .frame(height: 52)
                }
            }
        }
    }
}

struct OnboardingPage {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
}

struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 32) {
            // Icon with gradient background
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [page.color.opacity(0.3), page.color.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)

                Image(systemName: page.icon)
                    .font(.system(size: 48))
                    .foregroundStyle(page.color)
            }

            VStack(spacing: 16) {
                Text(page.title)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(ClioTheme.text)
                    .multilineTextAlignment(.center)

                Text(page.subtitle)
                    .font(.body)
                    .foregroundStyle(ClioTheme.textMuted)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 32)
            }
        }
        .padding()
    }
}

#Preview {
    OnboardingView(hasCompletedOnboarding: .constant(false))
}
