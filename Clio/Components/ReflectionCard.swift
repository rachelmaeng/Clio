import SwiftUI

struct ReflectionCard: View {
    let category: ReflectionCategory
    let text: String
    let detail: String

    enum ReflectionCategory: String {
        case movement = "Movement"
        case nourishment = "Nourishment"
        case rest = "Rest"
        case energy = "Energy"

        var icon: String {
            switch self {
            case .movement: return "figure.wave"
            case .nourishment: return "drop.fill"
            case .rest: return "moon.fill"
            case .energy: return "bolt.fill"
            }
        }

        var color: Color {
            switch self {
            case .movement: return ClioTheme.primary
            case .nourishment: return Color(hex: "2DD4BF")
            case .rest: return Color(hex: "818CF8")
            case .energy: return Color(hex: "FBBF24")
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Category header
            HStack(spacing: 8) {
                Image(systemName: category.icon)
                    .font(.caption)
                    .foregroundStyle(category.color)

                Text(category.rawValue.uppercased())
                    .font(.caption)
                    .fontWeight(.bold)
                    .tracking(1.2)
                    .foregroundStyle(ClioTheme.textMuted)
            }

            // Reflection text
            Text(text)
                .font(.body)
                .fontWeight(.medium)
                .foregroundStyle(ClioTheme.text)
                .lineSpacing(4)

            // Detail
            Text(detail)
                .font(.caption)
                .foregroundStyle(ClioTheme.textMuted.opacity(0.8))
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ClioTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [category.color.opacity(0.5), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 2)
                .clipShape(RoundedRectangle(cornerRadius: 1))
                .padding(.vertical, 16)
                .opacity(0)
        }
    }
}

#Preview {
    ZStack {
        ClioTheme.background
            .ignoresSafeArea()

        VStack(spacing: 16) {
            ReflectionCard(
                category: .movement,
                text: "Your energy for Pilates peaks in the morning hours this week.",
                detail: "Based on 5 sessions recorded before 9 AM."
            )

            ReflectionCard(
                category: .nourishment,
                text: "Hydration was consistent during your active days.",
                detail: "You met your goal 6 out of 7 days."
            )

            ReflectionCard(
                category: .rest,
                text: "Sleep onset was earlier on days you practiced breathwork.",
                detail: "Average onset: 10:15 PM vs 11:30 PM."
            )
        }
        .padding()
    }
}
