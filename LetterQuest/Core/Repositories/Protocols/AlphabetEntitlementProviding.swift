import Foundation

/// Answers whether the current user owns a purchasable alphabet, keyed by
/// its StoreKit product id (`Alphabet.productId`) — never by `Alphabet.id`,
/// since the two aren't guaranteed to match.
///
/// The real implementation (`StoreKitAlphabetEntitlementProvider`) derives
/// this from StoreKit's own entitlement data via `PurchaseServiceProtocol`.
protocol AlphabetEntitlementProviding {
    func isEntitled(to productId: String) -> Bool
}

/// Always denies entitlement. Correct today, since every alphabet in the
/// catalogue is free — and a safe default once a purchasable one is added,
/// since it stays locked until real purchase verification replaces this.
struct StubAlphabetEntitlementProvider: AlphabetEntitlementProviding {
    func isEntitled(to productId: String) -> Bool { false }
}
