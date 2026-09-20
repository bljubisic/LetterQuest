import Foundation
import RxSwift

/// Sources letters from every currently *installed* `Alphabet` (the built-in
/// Latin alphabet is always installed; purchased ones are added once their
/// entitlement is verified — see `AlphabetRepositoryProtocol`).
///
/// No network or disk I/O takes place; the `Single`s complete synchronously.
///
/// `fetchNext(after:)` advances only within the same `LetterCase` *and* the same
/// `alphabetId` — passing 'Z' returns `nil` rather than crossing into another
/// installed alphabet, and passing 'z' also returns `nil`. Lowercase letters
/// are unlocked as a group, per alphabet, by `PracticeViewModel` after all of
/// that alphabet's uppercase letters are completed.
final class LetterRepository: LetterRepositoryProtocol {

    private let alphabetRepository: AlphabetRepositoryProtocol

    init(alphabetRepository: AlphabetRepositoryProtocol = AlphabetRepository()) {
        self.alphabetRepository = alphabetRepository
    }

    func fetchAll() -> Single<[Letter]> {
        alphabetRepository.fetchInstalled().map { $0.flatMap(\.letters) }
    }

    func fetch(by id: UUID) -> Single<Letter?> {
        fetchAll().map { $0.first { $0.id == id } }
    }

    func fetchNext(after id: UUID) -> Single<Letter?> {
        fetchAll().map { allLetters in
            guard let current = allLetters.first(where: { $0.id == id }) else { return nil }
            let sameGroup = allLetters.filter {
                $0.letterCase == current.letterCase && $0.alphabetId == current.alphabetId
            }
            guard let index = sameGroup.firstIndex(where: { $0.id == id }),
                  index + 1 < sameGroup.count else { return nil }
            return sameGroup[index + 1]
        }
    }
}
