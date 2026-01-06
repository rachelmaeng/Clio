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
                Slider(value: $value, in: range)
                    .tint(ClioTheme.primary)

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
