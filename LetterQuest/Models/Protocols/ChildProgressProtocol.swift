import Foundation

/// Describes the recorded practice history for one letter.
///
/// Conforming types are immutable value types; use `ChildProgress`'s lenses
/// or `recording(_:)` to produce updated copies.
protocol ChildProgressProtocol {
    /// The letter this progress record belongs to.
    var letterId: UUID { get }

    /// All assessment attempts in chronological order.
    var attempts: [ChildProgress.Attempt] { get }

    /// The highest `overallScore` ever achieved for this letter.
    var bestScore: Int { get }

    /// Whether the child can currently practice this letter.
    /// Only the first letter starts unlocked; the rest unlock after the previous is completed.
    var isUnlocked: Bool { get }

    /// `true` once the child has scored ≥ 75 at least once.
    var isCompleted: Bool { get }
}
