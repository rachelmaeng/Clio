import SwiftUI

struct MovementTypeCard: View {
    let type: MovementEntry.MovementType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(isSelected ? ClioTheme.primary.opacity(0.2) : Color.white.opacity(0.05))
                        .frame(width: 40, height: 40)

                    Image(systemName: type.icon)
                        .font(.system(size: 18))
                        .foregroundStyle(isSelected ? .white : ClioTheme.textMuted)
                }

                Text(type.rawValue)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .medium)
                    .foregroundStyle(isSelected ? .white : ClioTheme.textMuted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(isSelected ? ClioTheme.primary : ClioTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isSelected ? ClioTheme.primary : Color.white.opacity(0.05),
                        lineWidth: 1
                    )
            )
            .shadow(
                color: isSelected ? ClioTheme.primary.opacity(0.3) : .clear,
                radius: 12, x: 0, y: 4
            )
            .overlay(alignment: .topTrailing) {
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.white)
                        .padding(12)
                }
            }
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

struct MovementTypeCardWide: View {
    let type: MovementEntry.MovementType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(isSelected ? ClioTheme.primary.opacity(0.2) : Color.white.opacity(0.05))
                        .frame(width: 40, height: 40)

                    Image(systemName: type.icon)
                        .font(.system(size: 18))
                        .foregroundStyle(isSelected ? .white : ClioTheme.textMuted)
                }

                Text(type.rawValue)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .medium)
                    .foregroundStyle(isSelected ? .white : ClioTheme.textMuted)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.white)
                }
            }
            .padding()
            .background(isSelected ? ClioTheme.primary : ClioTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isSelected ? ClioTheme.primary : Color.white.opacity(0.05),
                        lineWidth: 1
                    )
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

        VStack(spacing: 12) {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(MovementEntry.MovementType.allCases.prefix(4)) { type in
                    MovementTypeCard(
                        type: type,
                        isSelected: type == .pilates,
                        action: {}
                    )
                }
            }

            MovementTypeCardWide(
                type: .restDay,
                isSelected: false,
                action: {}
            )
        }
        .padding()
    }
}
