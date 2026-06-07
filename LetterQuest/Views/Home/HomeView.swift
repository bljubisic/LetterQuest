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

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 10) {
                // Large character glyph
                Text(String(letter.character))
                    .font(.system(size: 64, weight: .bold, design: .rounded))
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
    }

    /// Only "A" starts unlocked; the rest require the previous letter to be completed.
    private var isUnlocked: Bool {
        progress?.isUnlocked ?? (letter.character == "A")
    }
}
