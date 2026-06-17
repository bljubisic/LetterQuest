import Foundation
import RxSwift

/// In-memory implementation of `LetterRepositoryProtocol`.
///
/// The letter catalogue is the static `Letter.alphabet` array, seeded at compile
/// time. No network or disk I/O takes place; the `Single` completes synchronously.
///
/// To add a new letter or modify an existing one, update `Letter.alphabet` and
/// `StrokeTemplate.templates(for:)` in `Models/`.
final class LetterRepository: LetterRepositoryProtocol {

    func fetchAll() -> Single<[Letter]> {
        .just(Letter.alphabet)
    }

    func fetch(by id: UUID) -> Single<Letter?> {
        .just(Letter.alphabet.first { $0.id == id })
    }

    func fetchNext(after id: UUID) -> Single<Letter?> {
        guard let index = Letter.alphabet.firstIndex(where: { $0.id == id }),
              index + 1 < Letter.alphabet.count else {
            return .just(nil)
        }
        return .just(Letter.alphabet[index + 1])
    }
}
