import Foundation
import RxSwift

protocol ProgressRepositoryProtocol {
    func loadAll() -> Single<[ChildProgress]>
    func save(_ progress: ChildProgress) -> Completable
}
