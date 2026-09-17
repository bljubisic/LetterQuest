import SwiftUI

/// The letter-grid screen for a single alphabet, pushed from Home's
/// alphabet-picker step when more than one alphabet is installed.
///
/// Generic over `VM: AlphabetLettersViewModelProtocol` so that the same view
/// works with the real `AlphabetLettersViewModel` in production and with a
/// lightweight mock during Xcode previews or tests.
struct AlphabetLettersView<VM: AlphabetLettersViewModelProtocol>: View {

    @ObservedObject var viewModel: VM

    private let columns = [GridItem(.adaptive(minimum: 130), spacing: 16)]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(viewModel.letters) { letter in
                    LetterCard(
                        letter:     letter,
                        progress:   viewModel.progressMap[letter.id],
                        isUnlocked: viewModel.isUnlocked(letter),
                        onTap:      { viewModel.selectLetter(letter) }
                    )
                }
            }
            .padding()
        }
        .navigationTitle(viewModel.alphabetDisplayName)
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
                    .accessibilityIdentifier("alphabetLetters.wordsButton")
                }
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
