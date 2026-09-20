import Foundation

/// Describes the recorded practice state for one word.
///
/// Conforming types are immutable value types; use `WordProgress`'s lens
/// to produce updated copies.
protocol WordProgressProtocol {
    /// The word this progress record belongs to.
    var wordId: UUID { get }

    /// `true` once the child has passed every letter in the word during one session.
    var isCompleted: Bool { get }
}
