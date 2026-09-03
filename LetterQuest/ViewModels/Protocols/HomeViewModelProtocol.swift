import Foundation

/// The contract that `HomeView` depends on.
///
/// Keeping the view generic over `HomeViewModelProtocol` makes it trivial
/// to inject a mock during testing or SwiftUI previews:
/// ```swift
/// HomeView(viewModel: MockHomeViewModel())
/// ```
protocol HomeViewModelProtocol: ObservableObject {

    /// Letters filtered by the currently selected case.
    var letters: [Letter] { get }

    /// Maps each letter's `id` to its progress record.
    /// Letters that have never been attempted are absent from this dictionary.
    var progressMap: [UUID: ChildProgress] { get }

    /// `true` while the repositories are loading data.
    var isLoading: Bool { get }

    /// Whether the grid is showing uppercase or lowercase letters.
    var selectedCase: LetterCase { get }

    /// `true` once the child has completed all 26 uppercase and all 26 lowercase
    /// letters, unlocking word-practice mode.
    var isWordModeUnlocked: Bool { get }

    /// Triggers a (re-)load of letters and progress from the repositories.
    func load()

    /// Navigates to the practice screen for the given letter.
    ///
    /// - Parameter letter: The letter the child tapped on.
    func selectLetter(_ letter: Letter)

    /// Navigates to the progress and achievements screen.
    func navigateToProgress()

    /// Navigates to the word-practice list screen.
    func navigateToWords()

    /// Switches the grid between uppercase and lowercase letters.
    ///
    /// - Parameter letterCase: The case to display.
    func selectCase(_ letterCase: LetterCase)
}
