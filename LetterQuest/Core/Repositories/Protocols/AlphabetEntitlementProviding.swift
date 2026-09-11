import Foundation

/// Answers whether the current user owns a purchasable alphabet.
///
/// The real StoreKit-backed implementation is a separate, later issue — this
/// seam exists so `AlphabetRepository` can already filter installed
/// alphabets correctly once one exists.
protocol AlphabetEntitlementProviding {
    func isEntitled(to alphabetId: String) -> Bool
}

/// Always denies entitlement. Correct today, since every alphabet in the
/// catalogue is free — and a safe default once a purchasable one is added,
/// since it stays locked until real purchase verification replaces this.
struct StubAlphabetEntitlementProvider: AlphabetEntitlementProviding {
    func isEntitled(to alphabetId: String) -> Bool { false }
}
