import SwiftUI
import SwiftData

struct DailyCheckInView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var selectedState: DailyCheckIn.BodyState?
    @State private var isAnimating = false
    @State private var showSuccess = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Ambient gradient background
                ClioTheme.ambientGradient
                    .ignoresSafeArea()

                if showSuccess {
                    // Success state
                    successView
                } else {
                    // Main content
                    mainContent
                }
            }
            .safeAreaInset(edge: .bottom) {
                if !showSuccess {
                    // Bottom action area
                    VStack(spacing: 16) {
                        // Page indicators
                        HStack(spacing: 8) {
                            Capsule()
                                .fill(ClioTheme.primary)
                                .frame(width: 24, height: 6)

                            ForEach(0..<3, id: \.self) { _ in
                                Circle()
                                    .fill(ClioTheme.textMuted.opacity(0.3))
                                    .frame(width: 6, height: 6)
                            }
                        }

                        // Continue button
                        Button {
                            saveCheckIn()
                        } label: {
                            HStack {
                                Text("Continue")
                                Image(systemName: "arrow.forward")
                            }
                        }
                        .buttonStyle(ClioPrimaryButtonStyle())
                        .disabled(selectedState == nil)
                        .opacity(selectedState == nil ? 0.5 : 1.0)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 20)
                    .background(
                        LinearGradient(
                            colors: [
                                ClioTheme.background.opacity(0),
                                ClioTheme.background
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundStyle(ClioTheme.text)
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Skip") {
                        dismiss()
                    }
                    .foregroundStyle(ClioTheme.textMuted)
                }
            }
            .toolbarBackground(ClioTheme.background.opacity(0.95), for: .navigationBar)
        }
    }

    // MARK: - Main Content
    private var mainContent: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                Text("How does your body")
                    .font(.system(size: 28, weight: .light))
                    .foregroundStyle(ClioTheme.text)

                Text("feel today?")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(ClioTheme.primary)

                Text("Tune into your physical presence.")
                    .font(.subheadline)
                    .foregroundStyle(ClioTheme.textMuted)
                    .padding(.top, 4)
            }
            .padding(.top, 20)
            .padding(.bottom, 32)
            .fadeInFromBottom(delay: 0)

            // State selection grid
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ], spacing: 12) {
                    ForEach(Array(DailyCheckIn.BodyState.allCases.enumerated()), id: \.element) { index, state in
                        BodyStateCard(
                            state: state,
                            isSelected: selectedState == state,
                            action: {
                                HapticFeedback.light.trigger()
                                withAnimation(.clioBouncy) {
                                    selectedState = state
                                }
                            }
                        )
                        .staggeredAppearance(index: index, delay: 0.05)
                    }
                }
                .padding(.horizontal)

                // Add custom option
                Button {
                    // Future: custom sensation
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                            .font(.caption)
                        Text("Add custom sensation")
                            .font(.subheadline)
                    }
                    .foregroundStyle(ClioTheme.textMuted.opacity(0.6))
                }
                .padding(.top, 16)
                .padding(.bottom, 120)
                .fadeInFromBottom(delay: 0.4)
            }
        }
    }

    // MARK: - Success View
    private var successView: some View {
        VStack(spacing: 24) {
            Spacer()

            AnimatedCheckmark(color: ClioTheme.sage, size: 80)

            VStack(spacing: 8) {
                Text("Checked in")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(ClioTheme.text)

                if let state = selectedState {
                    Text("Feeling \(state.rawValue.lowercased())")
                        .font(.subheadline)
                        .foregroundStyle(ClioTheme.textMuted)
                }
            }
            .fadeInFromBottom(delay: 0.3)

            Spacer()

            Text("Every moment of awareness matters")
                .font(.subheadline)
                .foregroundStyle(ClioTheme.textMuted)
                .fadeInFromBottom(delay: 0.5)
                .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity)
        .overlay {
            CelebrationParticles(colors: [ClioTheme.primary, ClioTheme.rose, ClioTheme.sage])
        }
    }

    private func saveCheckIn() {
        guard let state = selectedState else { return }

        let today = Calendar.current.startOfDay(for: Date())

        // Check if there's already a check-in for today
        let descriptor = FetchDescriptor<DailyCheckIn>(
            predicate: #Predicate { $0.date == today }
        )

        do {
            let existing = try modelContext.fetch(descriptor)
            if let existingCheckIn = existing.first {
                existingCheckIn.state = state.rawValue
                existingCheckIn.updatedAt = Date()
            } else {
                let checkIn = DailyCheckIn(date: today, state: state.rawValue)
                modelContext.insert(checkIn)
            }
            try modelContext.save()

            // Show success animation
            HapticFeedback.success.trigger()
            withAnimation(.clioSpring) {
                showSuccess = true
            }

            // Dismiss after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                dismiss()
            }
        } catch {
            print("Failed to save check-in: \(error)")
            HapticFeedback.error.trigger()
        }
    }
}

#Preview {
    DailyCheckInView()
        .modelContainer(for: [DailyCheckIn.self], inMemory: true)
}
