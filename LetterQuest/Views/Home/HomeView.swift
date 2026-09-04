import SwiftUI

/// The root screen — a scrollable grid of all letters with per-letter progress badges.
///
/// Generic over `VM: HomeViewModelProtocol` so that the same view works with the real
/// `HomeViewModel` in production and with a lightweight mock during Xcode previews or tests.
struct HomeView<VM: HomeViewModelProtocol>: View {

    @ObservedObject var viewModel: VM

    private let columns = [GridItem(.adaptive(minimum: 130), spacing: 16)]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(viewModel.letters) { letter in
                    LetterCard(
                        letter:   letter,
                        progress: viewModel.progressMap[letter.id],
                        onTap:    { viewModel.selectLetter(letter) }
                    )
                }
            }
            .padding()
        }
        .navigationTitle("Letter Quest ✏️")
        .toolbar {
            ToolbarItem(placement: .principal) {
                Picker(
                    "Letters",
                    selection: Binding(
                        get: { viewModel.selectedCase },
                        set: { viewModel.selectCase($0) }
                    )
                ) {
                    Text("ABC").tag(LetterCase.upper)
                    Text("abc").tag(LetterCase.lower)
                }
                .pickerStyle(.segmented)
                .frame(width: 160)
                .accessibilityHint("Switches between uppercase and lowercase letters.")
            }
            if viewModel.isWordModeUnlocked {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.navigateToWords()
                    } label: {
                        Image(systemName: "text.book.closed.fill")
                    }
                    .accessibilityLabel("Word practice")
                    .accessibilityHint("Opens the list of practice words.")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel.navigateToProgress()
                } label: {
                    Image(systemName: "chart.bar.fill")
                }
                .accessibilityLabel("Progress")
                .accessibilityHint("Shows your achievements and letter progress.")
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel.navigateToSettings()
                } label: {
                    Image(systemName: "gearshape.fill")
                }
                .accessibilityLabel("Settings")
                .accessibilityHint("Opens sound, haptics, and difficulty settings.")
            }
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView().scaleEffect(1.5)
            }
        }
        .onAppear { viewModel.load() }
    }
}

// MARK: - Letter Card

/// A single tappable tile showing the letter character and its practice progress.
private struct LetterCard: View {

    let letter: Letter
    let progress: ChildProgress?
    let onTap: () -> Void

    @ScaledMetric(relativeTo: .largeTitle) private var glyphSize: CGFloat = 64

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 10) {
                // Large character glyph
                Text(String(letter.character))
                    .font(.system(size: glyphSize, weight: .bold, design: .rounded))
                    .foregroundStyle(isUnlocked ? Color.accentColor : .gray)

                // Progress indicator or status label
                if let progress {
                    VStack(spacing: 4) {
                        ProgressView(value: Double(progress.bestScore), total: 100)
                            .tint(progress.isCompleted ? .green : .accentColor)
                            .padding(.horizontal, 8)

                        Text(progress.isCompleted ? "⭐ Done!" : "\(progress.bestScore)%")
                            .font(.caption.bold())
                            .foregroundStyle(progress.isCompleted ? .green : .secondary)
                    }
                } else {
                    Text(isUnlocked ? "Tap to start" : "🔒 Locked")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isUnlocked ? Color.white : Color.gray.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(isUnlocked ? 0.08 : 0), radius: 6, y: 3)
        }
        .disabled(!isUnlocked)
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Letter \(String(letter.character))")
        .accessibilityValue(accessibilityStatus)
    }

    /// Only uppercase "A" starts unlocked; lowercase letters require all uppercase to be completed.
    private var isUnlocked: Bool {
        progress?.isUnlocked ?? (letter.character == "A")
    }

    private var accessibilityStatus: String {
        guard let progress else {
            return isUnlocked ? "Not started" : "Locked"
        }
        return progress.isCompleted
            ? "Completed, best score \(progress.bestScore) percent"
            : "In progress, best score \(progress.bestScore) percent"
    }
}
