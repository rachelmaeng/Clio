import SwiftUI

struct BodyStateCard: View {
    let state: DailyCheckIn.BodyState
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                // Gradient circle
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: state.gradientColors.map { Color(hex: $0) },
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 64, height: 64)
                        .opacity(isSelected ? 1.0 : 0.8)
                        .scaleEffect(isSelected ? 1.05 : 1.0)
                }

                VStack(spacing: 4) {
                    Text(state.rawValue)
                        .font(.subheadline)
                        .fontWeight(isSelected ? .bold : .medium)
                        .foregroundStyle(isSelected ? ClioTheme.primary : ClioTheme.text)

                    Text(state.description)
                        .font(.caption2)
                        .foregroundStyle(isSelected ? ClioTheme.primary.opacity(0.7) : ClioTheme.textMuted)
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity)
            .background(
                isSelected ? ClioTheme.primary.opacity(0.1) : ClioTheme.surface
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isSelected ? ClioTheme.primary : Color.white.opacity(0.05),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .shadow(
                color: isSelected ? ClioTheme.primary.opacity(0.3) : .clear,
                radius: 12, x: 0, y: 4
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

#Preview {
    ZStack {
        ClioTheme.background
            .ignoresSafeArea()

        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            ForEach(DailyCheckIn.BodyState.allCases) { state in
                BodyStateCard(
                    state: state,
                    isSelected: state == .calm,
                    action: {}
                )
            }
        }
        .padding()
    }
}
