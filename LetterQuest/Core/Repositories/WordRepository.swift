import Foundation
import RxSwift

/// In-memory implementation of `WordRepositoryProtocol`.
///
/// The word catalogue is the static `Word.curated` array, seeded at compile time.
/// No network or disk I/O takes place; the `Single` completes synchronously.
final class WordRepository: WordRepositoryProtocol {

    private static let allWords: [Word] = Word.curated

    func fetchAll() -> Single<[Word]> {
        .just(Self.allWords)
    }

    func fetch(by id: UUID) -> Single<Word?> {
        .just(Self.allWords.first { $0.id == id })
    }
}
