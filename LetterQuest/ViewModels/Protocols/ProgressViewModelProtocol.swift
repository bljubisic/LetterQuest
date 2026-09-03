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

    /// Number of items in the selected case (26 for letters).
    var totalCount: Int { get }

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
