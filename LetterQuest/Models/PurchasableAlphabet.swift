import Foundation

/// Localized StoreKit product info for one purchasable alphabet pack.
///
/// Kept separate from `Alphabet` (which describes content) and from raw
/// StoreKit `Product` values (which would leak StoreKit into ViewModels and
/// tests) — this is purely what a purchase screen needs to display.
struct PurchasableAlphabet: Identifiable, Equatable {
    /// The StoreKit product id — matches `Alphabet.productId`.
    let id: String
    let displayName: String
    let priceText: String
}
