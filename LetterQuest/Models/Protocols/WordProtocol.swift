import Foundation

/// Describes a single practice word made up of letters the child has already learned.
///
/// Conforming types are immutable value types.
protocol WordProtocol {
    /// Stable identifier, used as the key in word-level progress tracking.
    var id: UUID { get }

    /// The lowercase word text (e.g. `"cat"`).
    var text: String { get }
}
