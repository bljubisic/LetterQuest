import Foundation

/// A single, display-ready row for `AlphabetStoreView` — combines catalogue
/// data (`Alphabet`), localized StoreKit pricing (`PurchasableAlphabet`),
/// and entitlement state into the exact shape the view needs, so the view
/// itself never has to reach back into repository/service matching logic.
struct AlphabetStoreRow: Identifiable, Equatable {
    let alphabet: Alphabet
    /// `nil` for free alphabets; the localized price otherwise.
    let priceText: String?
    let isOwned: Bool

    var id: String { alphabet.id }
}
