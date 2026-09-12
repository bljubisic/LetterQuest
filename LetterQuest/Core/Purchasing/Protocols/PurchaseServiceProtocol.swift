import Foundation
import RxSwift

/// Buys and verifies alphabet-pack in-app purchases via StoreKit 2.
///
/// The production implementation (`StoreKitPurchaseService`) talks to the
/// real App Store, or the local `.storekit` configuration during
/// development/testing. Tests use `MockPurchaseService` instead — no real
/// StoreKit call is ever made from the test target.
protocol PurchaseServiceProtocol {
    /// Fetches localized product info for the given StoreKit product ids.
    func fetchProducts(ids: [String]) -> Single<[PurchasableAlphabet]>

    /// Initiates a purchase and resolves once the transaction finishes.
    /// Never throws for user-facing outcomes (cancellation, pending
    /// approval, already owned) — those are all `PurchaseOutcome` cases.
    func purchase(productId: String) -> Single<PurchaseOutcome>

    /// Re-derives entitlements from the App Store — backs "Restore Purchases".
    func restorePurchases() -> Completable

    /// The full set of currently owned non-consumable product ids, derived
    /// from StoreKit's own current entitlements — never a locally cached flag.
    func currentEntitlements() -> Single<Set<String>>

    /// Emits a product id every time a new verified transaction arrives —
    /// e.g. a purchase completing on another device via family sharing, or
    /// a delayed Ask-to-Buy approval.
    var entitlementUpdates: Observable<String> { get }
}
