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
            if viewModel.isMultiAlphabet {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(viewModel.installedAlphabets) { alphabet in
                        AlphabetCard(
                            alphabet: alphabet,
                            onTap:    { viewModel.selectAlphabet(alphabet.id) }
                        )
                    }
                }
                .padding()
            } else {
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
        }
        .navigationTitle("Letter Quest ✏️")
        .toolbar {
            if !viewModel.isMultiAlphabet {
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
                    .accessibilityIdentifier("home.wordsButton")
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
                .accessibilityIdentifier("home.progressButton")
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel.navigateToStore()
                } label: {
                    Image(systemName: "cart.fill")
                }
                .accessibilityLabel("Alphabet Store")
                .accessibilityHint("Browse and purchase alphabet packs.")
                .accessibilityIdentifier("home.storeButton")
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel.navigateToSettings()
                } label: {
                    Image(systemName: "gearshape.fill")
                }
                .accessibilityLabel("Settings")
                .accessibilityHint("Opens sound, haptics, and difficulty settings.")
                .accessibilityIdentifier("home.settingsButton")
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

// MARK: - Alphabet Card

/// A single tappable tile representing an installed alphabet, shown when
/// more than one is installed. Tapping pushes that alphabet's letter grid.
private struct AlphabetCard: View {

    let alphabet: Alphabet
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 10) {
                Text(alphabet.displayName)
                    .font(.title2.bold())
                    .foregroundStyle(Color.accentColor)

                Text(alphabet.nativeName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.08), radius: 6, y: 3)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(alphabet.displayName)
        .accessibilityIdentifier("home.alphabetCard.\(alphabet.id)")
    }
}
