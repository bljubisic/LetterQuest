import Foundation
import RxSwift

final class LetterRepository: LetterRepositoryProtocol {

    func fetchAll() -> Single<[Letter]> {
        .just(Letter.alphabet)
    }

    func fetch(by id: UUID) -> Single<Letter?> {
        .just(Letter.alphabet.first { $0.id == id })
    }
}
