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
        catalogue: [Alphabet] = [.latin],
        entitlementProvider: AlphabetEntitlementProviding = StubAlphabetEntitlementProvider()
    ) {
        self.catalogue = catalogue
        self.entitlementProvider = entitlementProvider
    }

    func fetchAvailable() -> Single<[Alphabet]> {
        .just(catalogue)
    }

    func fetchInstalled() -> Single<[Alphabet]> {
        .just(catalogue.filter { $0.isFree || entitlementProvider.isEntitled(to: $0.id) })
    }
}
