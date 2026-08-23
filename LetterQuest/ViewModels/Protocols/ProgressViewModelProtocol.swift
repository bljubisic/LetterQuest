import Foundation

/// The contract that `ProgressScreen` depends on.
///
/// Read-only — the progress screen has no navigation actions.
protocol ProgressViewModelProtocol: ObservableObject {

    /// All 26 letters in alphabetical order.
    var letters: [Letter] { get }

    /// Maps each letter's `id` to its progress record.
    /// Absent entries mean the letter has never been attempted.
    var progressMap: [UUID: ChildProgress] { get }

    /// How many letters the child has passed at least once.
    var completedCount: Int { get }

    /// Always 26 — the full alphabet size.
    var totalCount: Int { get }

    /// The three achievement badges, including unearned ones (`isEarned == false`).
    var badges: [AchievementBadge] { get }

    /// `true` while the repositories are fetching data.
    var isLoading: Bool { get }
}
