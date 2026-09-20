import SwiftUI

/// The root screen — a bottom-tabbed grid of the active alphabet's letters
/// (uppercase, lowercase, and — once unlocked — words) with per-item progress badges.
///
/// Generic over `VM: HomeViewModelProtocol` so that the same view works with the real
/// `HomeViewModel` in production and with a lightweight mock during Xcode previews or tests.
struct HomeView<VM: HomeViewModelProtocol>: View {

    /// The three bottom tabs Home can show. Case selection for the letter
    /// grid now flows through tab selection rather than a toolbar picker.
    private enum HomeTab: Hashable {
        case upper, lower, words
    }

    @ObservedObject var viewModel: VM

    @State private var selectedTab: HomeTab = .upper

    private let columns = [GridItem(.adaptive(minimum: 130), spacing: 16)]

    var body: some View {
        TabView(selection: $selectedTab) {
            letterGrid(for: .upper)
                .tabItem { Label("ABC", systemImage: "textformat.size.larger") }
                .tag(HomeTab.upper)
            letterGrid(for: .lower)
                .tabItem { Label("abc", systemImage: "textformat.size.smaller") }
                .tag(HomeTab.lower)
            if viewModel.isWordModeUnlocked {
                wordGrid
                    .tabItem { Label("Words", systemImage: "text.book.closed.fill") }
                    .tag(HomeTab.words)
            }
        }
        .onChange(of: selectedTab) { _, tab in
            if tab != .words { viewModel.selectCase(tab == .upper ? .upper : .lower) }
        }
        .navigationTitle("Letter Quest ✏️")
        .toolbar {
            if viewModel.isMultiAlphabet {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.navigateToSwitchAlphabet()
                    } label: {
                        Image(systemName: "globe")
                    }
                    .accessibilityLabel("Switch alphabet, currently \(viewModel.activeAlphabetDisplayName)")
                    .accessibilityHint("Opens the list of alphabets you own to switch which one is active.")
                    .accessibilityIdentifier("home.switchAlphabetButton")
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
        .onAppear {
            viewModel.load()
            if ScreenshotDemo.isEnabled && ScreenshotDemo.route == .words {
                selectedTab = .words
            }
        }
    }

    // MARK: - Tabs

    private func letterGrid(for letterCase: LetterCase) -> some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(viewModel.letters.filter { $0.letterCase == letterCase }) { letter in
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

    private var wordGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(viewModel.words) { word in
                    WordCard(
                        word:     word,
                        progress: viewModel.wordProgressMap[word.id],
                        onTap:    { viewModel.selectWord(word) }
                    )
                }
            }
            .padding()
        }
    }
}
