import Foundation

/// The contract that `ProgressScreen` depends on.
///
/// Read-only apart from case selection — the progress screen shows per-letter
/// data and allows switching between uppercase and lowercase views.
protocol ProgressViewModelProtocol: ObservableObject {

    /// Letters for the currently selected case, in alphabetical order.
    var letters: [Letter] { get }

    /// Maps each letter's `id` to its progress record.
    /// Absent entries mean the letter has never been attempted.
    var progressMap: [UUID: ChildProgress] { get }

    /// How many letters in the selected case the child has passed at least once.
    var completedCount: Int { get }

    /// Number of letters in the selected case for the active alphabet.
    var totalCount: Int { get }

    /// The active alphabet's curated words.
    var words: [Word] { get }

    /// Maps each word's `id` to its progress record.
    /// Words that have never been completed are absent from this dictionary.
    var wordProgressMap: [UUID: WordProgress] { get }

    /// How many of the active alphabet's curated words the child has completed.
    var completedWordsCount: Int { get }

    /// `true` once the active alphabet's word mode is unlocked — mirrors
    /// `HomeViewModel.isWordModeUnlocked`, so the words section only appears
    /// once it's actually reachable from Home.
    var isWordSectionVisible: Bool { get }

    /// Achievement badges for the currently selected case.
    /// Includes unearned badges (`isEarned == false`).
    var badges: [AchievementBadge] { get }

    /// `true` while the repositories are fetching data.
    var isLoading: Bool { get }

    /// Whether the screen is showing uppercase or lowercase progress.
    var selectedCase: LetterCase { get }

    /// Switches the progress list between uppercase and lowercase letters.
    func selectCase(_ letterCase: LetterCase)
}
