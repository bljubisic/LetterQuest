import Foundation
import RxSwift

/// `UserDefaults`-backed implementation of `ProgressRepositoryProtocol`.
///
/// All `ChildProgress` values are `Codable` and stored as a single JSON blob
/// under `storageKey`. Concurrent reads are safe because `UserDefaults` is
/// thread-safe; concurrent writes could race, but the app only writes from the
/// main thread via the Rx pipeline.
final class ProgressRepository: ProgressRepositoryProtocol {

    private let userDefaults: UserDefaults
    private let encoder    = JSONEncoder()
    private let decoder    = JSONDecoder()
    private let storageKey = "letter_quest_progress_v1"

    /// - Parameter userDefaults: The `UserDefaults` suite to use.
    ///   Defaults to `.standard`; pass a custom suite for app groups or tests.
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    // MARK: - ProgressRepositoryProtocol

    func loadAll() -> Single<[ChildProgress]> {
        Single.create { [weak self] observer in
            guard let self else { return Disposables.create() }
            do {
                guard let data = self.userDefaults.data(forKey: self.storageKey) else {
                    observer(.success([]))
                    return Disposables.create()
                }
                observer(.success(try self.decoder.decode([ChildProgress].self, from: data)))
            } catch {
                observer(.failure(error))
            }
            return Disposables.create()
        }
    }

    func save(_ progress: ChildProgress) -> Completable {
        Completable.create { [weak self] observer in
            guard let self else { return Disposables.create() }
            do {
                // Replace any existing record for the same letter, then re-encode.
                var all = self.loadAllSync()
                all.removeAll { $0.letterId == progress.letterId }
                all.append(progress)
                self.userDefaults.set(try self.encoder.encode(all), forKey: self.storageKey)
                observer(.completed)
            } catch {
                observer(.error(error))
            }
            return Disposables.create()
        }
    }

    // MARK: - Private

    /// Synchronous read used inside `save(_:)` to avoid nested async calls.
    private func loadAllSync() -> [ChildProgress] {
        guard let data = userDefaults.data(forKey: storageKey),
              let all  = try? decoder.decode([ChildProgress].self, from: data) else { return [] }
        return all
    }
}
