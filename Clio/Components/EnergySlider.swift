import SwiftUI

struct EnergySlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>

    var energyLabel: String {
        switch value {
        case 0..<33: return "Depleted"
        case 33..<66: return "Neutral"
        default: return "Vibrant"
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Energy Level")
                    .font(.headline)
                    .foregroundStyle(ClioTheme.text)

                Spacer()

                Text(energyLabel)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(ClioTheme.primary)
            }

            VStack(spacing: 12) {
                // Custom slider track
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background track
                        Capsule()
                            .fill(ClioTheme.surfaceHighlight)
                            .frame(height: 6)

                        // Filled track with gradient
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [ClioTheme.surfaceHighlight, ClioTheme.primary],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * (value / 100), height: 6)

                        // Thumb
                        Circle()
                            .fill(.white)
                            .frame(width: 24, height: 24)
                            .shadow(color: ClioTheme.primary.opacity(0.5), radius: 8, x: 0, y: 2)
                            .offset(x: (geometry.size.width - 24) * (value / 100))
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { gesture in
                                        let newValue = gesture.location.x / geometry.size.width * 100
                                        value = min(max(newValue, 0), 100)
                                    }
                            )
                    }
                }
                .frame(height: 24)

                // Labels
                HStack {
                    Text("Depleted")
                        .font(.caption)
                        .foregroundStyle(ClioTheme.textMuted)

                    Spacer()

                    Text("Neutral")
                        .font(.caption)
                        .foregroundStyle(ClioTheme.textMuted)

                    Spacer()

                    Text("Vibrant")
                        .font(.caption)
                        .foregroundStyle(ClioTheme.textMuted)
                }
            }
            .padding()
            .background(ClioTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}

#Preview {
    ZStack {
        ClioTheme.background
            .ignoresSafeArea()

        EnergySlider(value: .constant(75), range: 0...100)
            .padding()
    }
}
