import Foundation
import RxSwift

final class ProgressRepository: ProgressRepositoryProtocol {

    private let userDefaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let storageKey = "letter_quest_progress"

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func loadAll() -> Single<[ChildProgress]> {
        Single.create { [weak self] observer in
            guard let self else { return Disposables.create() }
            do {
                guard let data = self.userDefaults.data(forKey: self.storageKey) else {
                    observer(.success([]))
                    return Disposables.create()
                }
                let progress = try self.decoder.decode([ChildProgress].self, from: data)
                observer(.success(progress))
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
                var all = self.loadAllSync()
                all.removeAll { $0.letterId == progress.letterId }
                all.append(progress)
                let data = try self.encoder.encode(all)
                self.userDefaults.set(data, forKey: self.storageKey)
                observer(.completed)
            } catch {
                observer(.error(error))
            }
            return Disposables.create()
        }
    }

    private func loadAllSync() -> [ChildProgress] {
        guard let data = userDefaults.data(forKey: storageKey),
              let progress = try? decoder.decode([ChildProgress].self, from: data) else { return [] }
        return progress
    }
}
