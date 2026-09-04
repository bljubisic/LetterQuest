import Foundation
import RxSwift

/// Persists and retrieves completion state for all words.
///
/// The production implementation (`WordProgressRepository`) writes to `UserDefaults`.
/// Swap it for an in-memory implementation in unit tests.
protocol WordProgressRepositoryProtocol {

    /// Loads all stored `WordProgress` records.
    ///
    /// - Returns: A `Single` emitting the full array (may be empty on first launch).
    func loadAll() -> Single<[WordProgress]>

    /// Persists a single progress record, replacing any existing record for the same word.
    ///
    /// - Parameter progress: The updated `WordProgress` to save.
    /// - Returns: A `Completable` that signals success or an error.
    func save(_ progress: WordProgress) -> Completable

    /// Erases every stored `WordProgress` record. Used by the Settings
    /// screen's "Reset All Progress" action.
    ///
    /// - Returns: A `Completable` that signals success or an error.
    func resetAll() -> Completable
}
