import Foundation
import RxSwift

/// Persists and retrieves app-wide preferences (currently just `difficulty`).
///
/// The production implementation (`SettingsRepository`) writes to `UserDefaults`.
/// Swap it for an in-memory implementation in unit tests.
protocol SettingsRepositoryProtocol {

    /// Loads the current settings, or `AppSettings.default` when nothing has
    /// been saved yet (e.g. first launch).
    ///
    /// - Returns: A `Single` emitting the current `AppSettings`.
    func load() -> Single<AppSettings>

    /// Persists a new settings value, replacing whatever was stored before.
    ///
    /// - Parameter settings: The updated `AppSettings` to save.
    /// - Returns: A `Completable` that signals success or an error.
    func save(_ settings: AppSettings) -> Completable
}
