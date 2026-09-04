import SwiftUI

/// A scrollable grid of curated practice words with per-word completion badges.
///
/// Generic over `VM: WordsListViewModelProtocol` so that the same view works with
/// the real `WordsListViewModel` in production and with a lightweight mock during
/// Xcode previews or tests.
struct WordsListView<VM: WordsListViewModelProtocol>: View {

    @ObservedObject var viewModel: VM

    private let columns = [GridItem(.adaptive(minimum: 130), spacing: 16)]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(viewModel.words) { word in
                    WordCard(
                        word:     word,
                        progress: viewModel.progressMap[word.id],
                        onTap:    { viewModel.selectWord(word) }
                    )
                }
            }
            .padding()
        }
        .navigationTitle("Word Practice 📝")
        .overlay {
            if viewModel.isLoading {
                ProgressView().scaleEffect(1.5)
            }
        }
        .onAppear { viewModel.load() }
    }
}

// MARK: - Word Card

/// A single tappable tile showing the word text and its completion status.
private struct WordCard: View {

    let word: Word
    let progress: WordProgress?
    let onTap: () -> Void

    @ScaledMetric(relativeTo: .largeTitle) private var glyphSize: CGFloat = 40

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 10) {
                Text(word.text)
                    .font(.system(size: glyphSize, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.accentColor)

                Text(isCompleted ? "⭐ Done!" : "Tap to start")
                    .font(.caption.bold())
                    .foregroundStyle(isCompleted ? .green : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.08), radius: 6, y: 3)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(word.text)
        .accessibilityValue(isCompleted ? "Completed" : "Not started")
    }

    private var isCompleted: Bool { progress?.isCompleted ?? false }
}
