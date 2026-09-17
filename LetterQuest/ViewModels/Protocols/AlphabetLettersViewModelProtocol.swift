import Foundation

/// The contract that `AlphabetLettersView` depends on.
///
/// Keeping the view generic over `AlphabetLettersViewModelProtocol` makes it
/// trivial to inject a mock during testing or SwiftUI previews.
protocol AlphabetLettersViewModelProtocol: ObservableObject {

    /// The display name of the alphabet this screen is scoped to, shown as
    /// the navigation title.
    var alphabetDisplayName: String { get }

    /// Letters of this screen's alphabet, filtered by the currently selected case.
    var letters: [Letter] { get }

    /// Maps each letter's `id` to its progress record.
    /// Letters that have never been attempted are absent from this dictionary.
    var progressMap: [UUID: ChildProgress] { get }

    /// `true` while the repositories are loading data.
    var isLoading: Bool { get }

    /// Whether the grid is showing uppercase or lowercase letters.
    var selectedCase: LetterCase { get }

    /// `true` once every uppercase and lowercase letter of this screen's
    /// alphabet has been completed, unlocking that alphabet's word practice.
    var isWordModeUnlocked: Bool { get }

    /// Triggers a (re-)load of the alphabet and progress from the repositories.
    func load()

    /// Switches the grid between uppercase and lowercase letters.
    ///
    /// - Parameter letterCase: The case to display.
    func selectCase(_ letterCase: LetterCase)

    /// Navigates to the practice screen for the given letter.
    ///
    /// - Parameter letter: The letter the child tapped on.
    func selectLetter(_ letter: Letter)

    /// Navigates to this alphabet's word-practice list screen.
    func navigateToWords()

    /// Whether `letter` is unlocked and tappable.
    ///
    /// - Parameter letter: The letter to check.
    func isUnlocked(_ letter: Letter) -> Bool
}
