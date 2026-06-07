import Foundation
import RxSwift

/// Persists and retrieves practice history for all letters.
///
/// The production implementation (`ProgressRepository`) writes to `UserDefaults`.
/// Swap it for an in-memory implementation in unit tests.
protocol ProgressRepositoryProtocol {

    /// Loads all stored `ChildProgress` records.
    ///
    /// - Returns: A `Single` emitting the full array (may be empty on first launch).
    func loadAll() -> Single<[ChildProgress]>

    /// Persists a single progress record, replacing any existing record for the same letter.
    ///
    /// All updates go through `ChildProgress`'s lenses before reaching this method,
    /// so the value received is always a fully constructed, read-only struct.
    ///
    /// - Parameter progress: The updated `ChildProgress` to save.
    /// - Returns: A `Completable` that signals success or an error.
    func save(_ progress: ChildProgress) -> Completable
}
