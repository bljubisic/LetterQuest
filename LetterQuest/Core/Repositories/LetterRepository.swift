import Foundation
import RxSwift

/// In-memory implementation of `LetterRepositoryProtocol`.
///
/// The letter catalogue is the static `Letter.alphabet + Letter.lowercaseAlphabet` arrays,
/// seeded at compile time. No network or disk I/O takes place; the `Single` completes
/// synchronously.
///
/// `fetchNext(after:)` advances only within the same `LetterCase` — passing 'Z' returns
/// `nil`, and passing 'z' also returns `nil`. Lowercase letters are unlocked as a group
/// by `PracticeViewModel` after all uppercase letters are completed.
final class LetterRepository: LetterRepositoryProtocol {

    private static let allLetters: [Letter] = Letter.alphabet + Letter.lowercaseAlphabet + Letter.digits

    func fetchAll() -> Single<[Letter]> {
        .just(Self.allLetters)
    }

    func fetch(by id: UUID) -> Single<Letter?> {
        .just(Self.allLetters.first { $0.id == id })
    }

    func fetchNext(after id: UUID) -> Single<Letter?> {
        guard let current = Self.allLetters.first(where: { $0.id == id }) else {
            return .just(nil)
        }
        let sameCase = Self.allLetters.filter { $0.letterCase == current.letterCase }
        guard let index = sameCase.firstIndex(where: { $0.id == id }),
              index + 1 < sameCase.count else {
            return .just(nil)
        }
        return .just(sameCase[index + 1])
    }
}
