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

    /// Letters of the single installed alphabet, filtered by the currently
    /// selected case. Only meaningful when `isMultiAlphabet` is `false` —
    /// once more than one alphabet is installed, Home shows the alphabet
    /// picker instead of a letter grid.
    var letters: [Letter] { get }

    /// Maps each letter's `id` to its progress record.
    /// Letters that have never been attempted are absent from this dictionary.
    var progressMap: [UUID: ChildProgress] { get }

    /// `true` while the repositories are loading data.
    var isLoading: Bool { get }

    /// Whether the grid is showing uppercase or lowercase letters.
    var selectedCase: LetterCase { get }

    /// `true` once more than one alphabet is installed — shows the alphabet
    /// picker grid instead of a direct letter grid.
    var isMultiAlphabet: Bool { get }

    /// `true` once the child has completed all of the Latin alphabet's
    /// uppercase and lowercase letters, unlocking word-practice mode.
    var isWordModeUnlocked: Bool { get }

    /// Triggers a (re-)load of installed alphabets and progress from the repositories.
    func load()

    /// Navigates to the practice screen for the given letter.
    ///
    /// - Parameter letter: The letter the child tapped on.
    func selectLetter(_ letter: Letter)

    /// Navigates to the progress and achievements screen.
    func navigateToProgress()

    /// Navigates to the word-practice list screen.
    func navigateToWords()

    /// Navigates to the Settings screen.
    func navigateToSettings()

    /// Navigates to the alphabet store screen.
    func navigateToStore()

    /// Switches the grid between uppercase and lowercase letters.
    ///
    /// - Parameter letterCase: The case to display.
    func selectCase(_ letterCase: LetterCase)

    /// Navigates to the letter grid for the given installed alphabet.
    ///
    /// - Parameter alphabetId: The `Alphabet.id` to display.
    func selectAlphabet(_ alphabetId: String)

    /// Whether `letter` is unlocked and tappable.
    ///
    /// - Parameter letter: The letter to check.
    func isUnlocked(_ letter: Letter) -> Bool
}
