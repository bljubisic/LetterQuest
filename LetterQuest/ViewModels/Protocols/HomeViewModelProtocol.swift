import Foundation

/// The contract that `HomeView` depends on.
///
/// Keeping the view generic over `HomeViewModelProtocol` makes it trivial
/// to inject a mock during testing or SwiftUI previews:
/// ```swift
/// HomeView(viewModel: MockHomeViewModel())
/// ```
protocol HomeViewModelProtocol: ObservableObject {

    /// Every installed alphabet (free and purchased).
    var installedAlphabets: [Alphabet] { get }

    /// The display name of the alphabet Home currently shows (e.g. "English"),
    /// for the "Switch Alphabet" toolbar button's label.
    var activeAlphabetDisplayName: String { get }

    /// Letters of the active alphabet, filtered by the currently selected case.
    var letters: [Letter] { get }

    /// Maps each letter's `id` to its progress record.
    /// Letters that have never been attempted are absent from this dictionary.
    var progressMap: [UUID: ChildProgress] { get }

    /// The active alphabet's curated words, once word mode is unlocked.
    var words: [Word] { get }

    /// Maps each word's `id` to its progress record.
    /// Words that have never been completed are absent from this dictionary.
    var wordProgressMap: [UUID: WordProgress] { get }

    /// `true` while the repositories are loading data.
    var isLoading: Bool { get }

    /// Whether the grid is showing uppercase or lowercase letters.
    var selectedCase: LetterCase { get }

    /// `true` once more than one alphabet is installed — shows the "Switch
    /// Alphabet" toolbar button.
    var isMultiAlphabet: Bool { get }

    /// `true` once the child has completed the active alphabet's uppercase
    /// and lowercase letters, unlocking that alphabet's word-practice mode.
    var isWordModeUnlocked: Bool { get }

    /// Triggers a (re-)load of installed alphabets, the active-alphabet
    /// selection, and progress from the repositories.
    func load()

    /// Navigates to the practice screen for the given letter.
    ///
    /// - Parameter letter: The letter the child tapped on.
    func selectLetter(_ letter: Letter)

    /// Navigates to the progress and achievements screen.
    func navigateToProgress()

    /// Navigates to the Settings screen.
    func navigateToSettings()

    /// Navigates to the alphabet store screen.
    func navigateToStore()

    /// Navigates to the "Switch Alphabet" screen.
    func navigateToSwitchAlphabet()

    /// Switches the grid between uppercase and lowercase letters.
    ///
    /// - Parameter letterCase: The case to display.
    func selectCase(_ letterCase: LetterCase)

    /// Whether `letter` is unlocked and tappable.
    ///
    /// - Parameter letter: The letter to check.
    func isUnlocked(_ letter: Letter) -> Bool

    /// Navigates to the practice screen for the given word.
    ///
    /// - Parameter word: The word the child tapped on.
    func selectWord(_ word: Word)
}
