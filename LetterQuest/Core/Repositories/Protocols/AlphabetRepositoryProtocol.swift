import Foundation
import RxSwift

/// Provides access to the catalogue of alphabets (script/content packs) and
/// which ones are currently installed for this device/user.
protocol AlphabetRepositoryProtocol {
    /// Every alphabet the app knows about, free or purchasable.
    func fetchAvailable() -> Single<[Alphabet]>

    /// Alphabets currently installed: every free alphabet, plus any
    /// purchased alphabet the user is entitled to.
    func fetchInstalled() -> Single<[Alphabet]>
}
