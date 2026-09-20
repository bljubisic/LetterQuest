import Foundation
import RxSwift

/// `AlphabetEntitlementProviding` backed by StoreKit's own entitlement data
/// — never a locally cached flag.
///
/// `AlphabetRepository.fetchInstalled()` needs `isEntitled(to:)` to be
/// synchronous, so this keeps an in-memory snapshot: populated from
/// `purchaseService.currentEntitlements()` via `refresh()` (called once at
/// app launch, before any alphabet-dependent screen is shown — see
/// `LetterQuestApp`), and kept live afterwards via
/// `purchaseService.entitlementUpdates`.
final class StoreKitAlphabetEntitlementProvider: AlphabetEntitlementProviding {

    private let purchaseService: PurchaseServiceProtocol
    private let disposeBag = DisposeBag()
    private var ownedProductIds: Set<String> = []

    init(purchaseService: PurchaseServiceProtocol) {
        self.purchaseService = purchaseService
        purchaseService.entitlementUpdates
            .subscribe(onNext: { [weak self] productId in
                self?.ownedProductIds.insert(productId)
            })
            .disposed(by: disposeBag)
    }

    /// Re-derives the entitlement snapshot from StoreKit. Call once during
    /// app startup, before any alphabet-dependent screen can appear.
    func refresh() -> Completable {
        purchaseService.currentEntitlements()
            .do(onSuccess: { [weak self] ids in self?.ownedProductIds = ids })
            .asCompletable()
    }

    func isEntitled(to productId: String) -> Bool {
        ownedProductIds.contains(productId)
    }
}
