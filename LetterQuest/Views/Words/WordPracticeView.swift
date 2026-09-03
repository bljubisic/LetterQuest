import SwiftUI

/// The word-practice screen: traces a word's letters in sequence, reusing
/// `PracticeView` for each individual letter.
///
/// Generic over `VM: WordPracticeViewModelProtocol` so that the real
/// `WordPracticeViewModel` and a preview/test mock are interchangeable.
struct WordPracticeView<VM: WordPracticeViewModelProtocol>: View {

    @ObservedObject var viewModel: VM
    @State private var letterViewModel: PracticeViewModel?

    var body: some View {
        ZStack {
            if let word = viewModel.word {
                VStack(spacing: 12) {
                    wordHeader(for: word)

                    if let letterViewModel {
                        PracticeView(viewModel: letterViewModel)
                            // Keyed off the view model's own identity, not `currentIndex`:
                            // `currentIndex` changes one render before `letterViewModel` is
                            // reassigned (via `.onChange`), so keying on it left the *old*
                            // `PracticeView` mounted under the *new* id for one frame — its
                            // `GeometryReader.onAppear` (which sets the real canvas size)
                            // never re-fired for the new view model, so every letter after
                            // the first was scored against the stale 600×400 default.
                            .id(ObjectIdentifier(letterViewModel))
                    }
                }
            } else {
                ProgressView().scaleEffect(1.5)
            }

            if viewModel.isWordCompleted {
                WordCelebrationView(
                    word:        viewModel.word?.text ?? "",
                    onContinue:  viewModel.finish
                )
                .transition(.opacity)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { syncLetterViewModel() }
        .onChange(of: viewModel.word) { _, _ in syncLetterViewModel() }
        .onChange(of: viewModel.currentIndex) { _, _ in syncLetterViewModel() }
    }

    // MARK: - Subviews

    /// Shows the target word with a checkmark over each letter already passed.
    private func wordHeader(for word: Word) -> some View {
        HStack(spacing: 12) {
            ForEach(Array(word.characters.enumerated()), id: \.offset) { index, character in
                VStack(spacing: 2) {
                    Text(String(character))
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(index <= viewModel.currentIndex ? Color.accentColor : .gray)
                    Image(systemName: index < viewModel.currentIndex ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(index < viewModel.currentIndex ? .green : .gray.opacity(0.4))
                }
            }
        }
        .padding(.top)
    }

    // MARK: - Private helpers

    /// Rebuilds the embedded letter view model whenever the word loads or the
    /// sequence advances to a new letter.
    private func syncLetterViewModel() {
        guard viewModel.word != nil else { return }
        letterViewModel = viewModel.makeLetterViewModel()
    }
}
