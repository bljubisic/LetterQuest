import Foundation
import RxSwift
@testable import LetterQuest

/// In-memory `PurchaseServiceProtocol` double — no real StoreKit call is
/// ever made. Shared across purchase-related test files.
final class MockPurchaseService: PurchaseServiceProtocol {

    var products: [PurchasableAlphabet] = []
    var purchaseOutcome: PurchaseOutcome = .purchased
    var entitlements: Set<String> = []

    private let updatesSubject = PublishSubject<String>()
    var entitlementUpdates: Observable<String> { updatesSubject.asObservable() }

    func fetchProducts(ids: [String]) -> Single<[PurchasableAlphabet]> {
        .just(products.filter { ids.contains($0.id) })
    }

    func purchase(productId: String) -> Single<PurchaseOutcome> {
        .just(purchaseOutcome)
    }

    func restorePurchases() -> Completable {
        .empty()
    }

    func currentEntitlements() -> Single<Set<String>> {
        .just(entitlements)
    }

    /// Test hook: simulates a live transaction update, e.g. a delayed
    /// Ask-to-Buy approval or a purchase restored on another device.
    func simulateEntitlementUpdate(productId: String) {
        updatesSubject.onNext(productId)
    }
}
