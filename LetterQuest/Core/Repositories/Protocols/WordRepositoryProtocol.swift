import Foundation
import RxSwift

/// Provides access to the curated word catalogue.
///
/// The production implementation (`WordRepository`) returns the static in-memory
/// word list. A test double can return any subset of words.
protocol WordRepositoryProtocol {

    /// Returns all words in the curated list.
    ///
    /// - Returns: A `Single` that emits the full `[Word]` array then completes.
    func fetchAll() -> Single<[Word]>

    /// Returns the word with the given `id`, or `nil` when not found.
    ///
    /// - Parameter id: The stable `UUID` of the target word.
    /// - Returns: A `Single` emitting an optional `Word`.
    func fetch(by id: UUID) -> Single<Word?>
}
