import SwiftUI
import SwiftData

struct MovementLogView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var selectedType: MovementEntry.MovementType?
    @State private var energyLevel: Double = 50
    @State private var durationMinutes: Int = 30
    @State private var notes: String = ""

    var body: some View {
        NavigationStack {
            ZStack {
                ClioTheme.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Movement type section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("How did you move today?")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(ClioTheme.text)

                            // Grid of movement types
                            LazyVGrid(columns: [
                                GridItem(.flexible(), spacing: 12),
                                GridItem(.flexible(), spacing: 12)
                            ], spacing: 12) {
                                ForEach(MovementEntry.MovementType.allCases.prefix(4)) { type in
                                    MovementTypeCard(
                                        type: type,
                                        isSelected: selectedType == type,
                                        action: {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                selectedType = type
                                            }
                                        }
                                    )
                                }
                            }

                            // Rest day (full width)
                            MovementTypeCardWide(
                                type: .rest,
                                isSelected: selectedType == .rest,
                                action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        selectedType = .rest
                                    }
                                }
                            )
                        }

                        // Energy level slider
                        EnergySlider(value: $energyLevel, range: 0...100)

                        // Duration stepper
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Duration")
                                .font(.headline)
                                .foregroundStyle(ClioTheme.text)

                            HStack {
                                Button {
                                    if durationMinutes > 5 {
                                        durationMinutes -= 5
                                    }
                                } label: {
                                    Image(systemName: "minus")
                                        .font(.headline)
                                        .foregroundStyle(.white)
                                        .frame(width: 44, height: 44)
                                        .background(Color.white.opacity(0.1))
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                }

                                Spacer()

                                VStack(spacing: 2) {
                                    Text("\(durationMinutes)")
                                        .font(.system(size: 32, weight: .bold))
                                        .foregroundStyle(ClioTheme.text)

                                    Text("Minutes")
                                        .font(.caption)
                                        .textCase(.uppercase)
                                        .foregroundStyle(ClioTheme.textMuted)
                                }

                                Spacer()

                                Button {
                                    if durationMinutes < 180 {
                                        durationMinutes += 5
                                    }
                                } label: {
                                    Image(systemName: "plus")
                                        .font(.headline)
                                        .foregroundStyle(.white)
                                        .frame(width: 44, height: 44)
                                        .background(Color.white.opacity(0.1))
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                            }
                            .padding()
                            .background(ClioTheme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }

                        // Notes
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Notes & Sensations")
                                .font(.headline)
                                .foregroundStyle(ClioTheme.text)

                            ZStack(alignment: .topLeading) {
                                if notes.isEmpty {
                                    Text("How did your body feel? Any tension or release?")
                                        .foregroundStyle(ClioTheme.textMuted.opacity(0.6))
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 16)
                                }

                                TextEditor(text: $notes)
                                    .scrollContentBackground(.hidden)
                                    .foregroundStyle(ClioTheme.text)
                                    .frame(minHeight: 120)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 12)
                            }
                            .background(ClioTheme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }

                        // Inspirational quote
                        Text("\"Listening to your body's energy is a form of rest.\"")
                            .font(.subheadline)
                            .italic()
                            .foregroundStyle(ClioTheme.textMuted)
                            .padding(.top, 8)
                    }
                    .padding()
                    .padding(.bottom, 100)
                }
            }
            .safeAreaInset(edge: .bottom) {
                VStack {
                    Button {
                        saveMovement()
                    } label: {
                        HStack {
                            Text("Save Movement")
                            Image(systemName: "checkmark")
                        }
                    }
                    .buttonStyle(ClioPrimaryButtonStyle())
                    .disabled(selectedType == nil)
                    .opacity(selectedType == nil ? 0.5 : 1.0)
                }
                .padding()
                .background(
                    LinearGradient(
                        colors: [ClioTheme.background.opacity(0), ClioTheme.background],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
            .navigationTitle("Log Movement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(ClioTheme.textMuted)
                    }
                }
            }
            .toolbarBackground(ClioTheme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }

    private func saveMovement() {
        guard let type = selectedType else { return }

        let entry = MovementEntry(
            type: type.rawValue,
            energyLevel: Int(energyLevel),
            durationMinutes: durationMinutes,
            notes: notes.isEmpty ? nil : notes
        )

        modelContext.insert(entry)

        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Failed to save movement: \(error)")
        }
    }
}

#Preview {
    MovementLogView()
        .modelContainer(for: [MovementEntry.self], inMemory: true)
}
