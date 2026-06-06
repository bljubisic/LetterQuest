import Foundation
import RxSwift

protocol LetterRepositoryProtocol {
    func fetchAll() -> Single<[Letter]>
    func fetch(by id: UUID) -> Single<Letter?>
}
