import Foundation
import RxSwift

/// `UserDefaults`-backed implementation of `WordProgressRepositoryProtocol`.
///
/// All `WordProgress` values are `Codable` and stored as a single JSON blob
/// under `storageKey`, mirroring `ProgressRepository`'s persistence strategy.
final class WordProgressRepository: WordProgressRepositoryProtocol {

    private let userDefaults: UserDefaults
    private let encoder    = JSONEncoder()
    private let decoder    = JSONDecoder()
    private let storageKey = "letter_quest_word_progress_v1"

    /// - Parameter userDefaults: The `UserDefaults` suite to use.
    ///   Defaults to `.standard`; pass a custom suite for app groups or tests.
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    // MARK: - WordProgressRepositoryProtocol

    func loadAll() -> Single<[WordProgress]> {
        Single.create { [weak self] observer in
            guard let self else { return Disposables.create() }
            do {
                guard let data = self.userDefaults.data(forKey: self.storageKey) else {
                    observer(.success([]))
                    return Disposables.create()
                }
                observer(.success(try self.decoder.decode([WordProgress].self, from: data)))
            } catch {
                observer(.failure(error))
            }
            return Disposables.create()
        }
    }

    func save(_ progress: WordProgress) -> Completable {
        Completable.create { [weak self] observer in
            guard let self else { return Disposables.create() }
            do {
                var all = self.loadAllSync()
                all.removeAll { $0.wordId == progress.wordId }
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
    private func loadAllSync() -> [WordProgress] {
        guard let data = userDefaults.data(forKey: storageKey),
              let all  = try? decoder.decode([WordProgress].self, from: data) else { return [] }
        return all
    }
}
