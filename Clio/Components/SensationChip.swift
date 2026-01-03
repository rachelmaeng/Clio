import SwiftUI

struct SensationChip: View {
    let sensation: MealEntry.Sensation
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(sensation.rawValue)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .medium)
                .foregroundStyle(isSelected ? .white : ClioTheme.textMuted)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    isSelected ? ClioTheme.primary : ClioTheme.surface
                )
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(
                            isSelected ? ClioTheme.primary : Color.white.opacity(0.05),
                            lineWidth: 1
                        )
                )
                .shadow(
                    color: isSelected ? ClioTheme.primary.opacity(0.4) : .clear,
                    radius: 8, x: 0, y: 2
                )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

struct SensationChipGroup: View {
    @Binding var selectedSensations: Set<MealEntry.Sensation>

    var body: some View {
        FlowLayout(spacing: 8) {
            ForEach(MealEntry.Sensation.allCases) { sensation in
                SensationChip(
                    sensation: sensation,
                    isSelected: selectedSensations.contains(sensation)
                ) {
                    if selectedSensations.contains(sensation) {
                        selectedSensations.remove(sensation)
                    } else {
                        selectedSensations.insert(sensation)
                    }
                }
            }

            // Add custom button
            Button {
                // Future: add custom sensation
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "plus")
                        .font(.caption)
                    Text("Add")
                        .font(.subheadline)
                }
                .foregroundStyle(ClioTheme.textMuted)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(ClioTheme.surface)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
    }
}

// Simple flow layout for chips
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        return layout(sizes: sizes, containerWidth: proposal.width ?? .infinity).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        let positions = layout(sizes: sizes, containerWidth: bounds.width).positions

        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + positions[index].x, y: bounds.minY + positions[index].y), proposal: .unspecified)
        }
    }

    private func layout(sizes: [CGSize], containerWidth: CGFloat) -> (size: CGSize, positions: [CGPoint]) {
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var maxWidth: CGFloat = 0

        for size in sizes {
            if currentX + size.width > containerWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }

            positions.append(CGPoint(x: currentX, y: currentY))
            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
            maxWidth = max(maxWidth, currentX)
        }

        return (CGSize(width: maxWidth, height: currentY + lineHeight), positions)
    }
}

#Preview {
    ZStack {
        ClioTheme.background
            .ignoresSafeArea()

        SensationChipGroup(selectedSensations: .constant([.grounded, .mindful]))
            .padding()
    }
}
