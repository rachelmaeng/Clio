import SwiftUI
import SwiftData

struct ReflectionsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var reflections: [Reflection] = []
    @State private var selectedTimeRange: TimeRange = .twoWeeks

    enum TimeRange: String, CaseIterable {
        case week = "7 days"
        case twoWeeks = "14 days"
        case month = "30 days"

        var days: Int {
            switch self {
            case .week: return 7
            case .twoWeeks: return 14
            case .month: return 30
            }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ClioTheme.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Header
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Reflections")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundStyle(ClioTheme.text)

                            Text("Patterns from your recent logs")
                                .font(.subheadline)
                                .foregroundStyle(ClioTheme.textMuted)
                        }
                        .padding(.top, 8)

                        // Time range picker
                        HStack(spacing: 0) {
                            ForEach(TimeRange.allCases, id: \.self) { range in
                                Button {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        selectedTimeRange = range
                                        loadReflections()
                                    }
                                } label: {
                                    Text(range.rawValue)
                                        .font(.subheadline)
                                        .fontWeight(selectedTimeRange == range ? .semibold : .medium)
                                        .foregroundStyle(selectedTimeRange == range ? ClioTheme.text : ClioTheme.textMuted)
                                        .padding(.vertical, 10)
                                        .padding(.horizontal, 16)
                                        .background(
                                            selectedTimeRange == range ? ClioTheme.background : Color.clear
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(4)
                        .background(ClioTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 14))

                        // Reflections list
                        if reflections.isEmpty {
                            EmptyReflectionsView()
                        } else {
                            VStack(spacing: 16) {
                                ForEach(reflections) { reflection in
                                    ReflectionCard(
                                        category: reflection.category,
                                        text: reflection.text,
                                        detail: reflection.detail
                                    )
                                }
                            }
                        }

                        // Gentle footer
                        VStack(spacing: 8) {
                            Text("Reflections are observations, not judgments.")
                                .font(.caption)
                                .foregroundStyle(ClioTheme.textMuted)
                                .multilineTextAlignment(.center)

                            Text("They update as you log more.")
                                .font(.caption)
                                .foregroundStyle(ClioTheme.textMuted.opacity(0.7))
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 24)
                    }
                    .padding()
                    .padding(.bottom, 100)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                loadReflections()
            }
        }
    }

    private func loadReflections() {
        let generator = ReflectionGenerator(modelContext: modelContext)
        reflections = generator.generateReflections()
    }
}

struct EmptyReflectionsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "sparkles")
                .font(.system(size: 48))
                .foregroundStyle(ClioTheme.primary.opacity(0.5))

            VStack(spacing: 8) {
                Text("Your patterns will emerge")
                    .font(.headline)
                    .foregroundStyle(ClioTheme.text)

                Text("Keep logging what feels true. Clio will notice the threads that connect your days.")
                    .font(.subheadline)
                    .foregroundStyle(ClioTheme.textMuted)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity)
        .background(ClioTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

#Preview {
    ReflectionsView()
        .modelContainer(for: [UserSettings.self, DailyCheckIn.self, MovementEntry.self, MealEntry.self], inMemory: true)
}
