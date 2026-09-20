import Foundation
import RxSwift

/// `UserDefaults`-backed implementation of `SettingsRepositoryProtocol`.
///
/// `AppSettings` is `Codable` and stored as a single JSON blob under
/// `storageKey`, mirroring `ProgressRepository`'s persistence strategy.
final class SettingsRepository: SettingsRepositoryProtocol {

    private let userDefaults: UserDefaults
    private let encoder    = JSONEncoder()
    private let decoder    = JSONDecoder()
    private let storageKey = "letter_quest_settings_v1"

    /// - Parameter userDefaults: The `UserDefaults` suite to use.
    ///   Defaults to `.standard`; pass a custom suite for app groups or tests.
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    // MARK: - SettingsRepositoryProtocol

    func load() -> Single<AppSettings> {
        Single.create { [weak self] observer in
            guard let self else { return Disposables.create() }
            do {
                guard let data = self.userDefaults.data(forKey: self.storageKey) else {
                    observer(.success(.default))
                    return Disposables.create()
                }
                observer(.success(try self.decoder.decode(AppSettings.self, from: data)))
            } catch {
                observer(.failure(error))
            }
            return Disposables.create()
        }
    }

    func save(_ settings: AppSettings) -> Completable {
        Completable.create { [weak self] observer in
            guard let self else { return Disposables.create() }
            do {
                self.userDefaults.set(try self.encoder.encode(settings), forKey: self.storageKey)
                observer(.completed)
            } catch {
                observer(.error(error))
            }
            return Disposables.create()
        }
    }
}
