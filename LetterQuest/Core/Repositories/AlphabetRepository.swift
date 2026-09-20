import Foundation
import RxSwift

/// In-memory implementation of `AlphabetRepositoryProtocol`.
///
/// The catalogue is a static list seeded at compile time, matching the
/// pattern used by `LetterRepository`/`WordRepository`. No network or disk
/// I/O takes place; the `Single`s complete synchronously.
final class AlphabetRepository: AlphabetRepositoryProtocol {

    private let catalogue: [Alphabet]
    private let entitlementProvider: AlphabetEntitlementProviding

    /// - Parameters:
    ///   - catalogue: Every alphabet the app knows about. Defaults to the
    ///     real, production catalogue; tests can inject a fake paid alphabet
    ///     to exercise entitlement filtering.
    ///   - entitlementProvider: Answers ownership checks for non-free entries.
    init(
        catalogue: [Alphabet] = [.latin, .cyrillicSr, .german],
        entitlementProvider: AlphabetEntitlementProviding = StubAlphabetEntitlementProvider()
    ) {
        self.catalogue = catalogue
        self.entitlementProvider = entitlementProvider
    }

    func fetchAvailable() -> Single<[Alphabet]> {
        .just(catalogue)
    }

    func fetchInstalled() -> Single<[Alphabet]> {
        .just(catalogue.filter { alphabet in
            guard !alphabet.isFree else { return true }
            guard let productId = alphabet.productId else { return false }
            return entitlementProvider.isEntitled(to: productId)
        })
    }
}
