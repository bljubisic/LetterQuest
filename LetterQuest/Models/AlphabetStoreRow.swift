import Foundation

/// A single, display-ready row for `AlphabetStoreView` — combines catalogue
/// data (`Alphabet`), localized StoreKit pricing (`PurchasableAlphabet`),
/// and entitlement state into the exact shape the view needs, so the view
/// itself never has to reach back into repository/service matching logic.
///
/// `alphabets` holds more than one entry when several alphabets share a
/// single StoreKit product id — a bundled pack purchased/restored as one
/// unit (e.g. the Extended Latin Pack, issue #52) — in which case
/// `displayName`/`nativeName` describe the pack rather than any one
/// alphabet.
struct AlphabetStoreRow: Identifiable, Equatable {
    let alphabets: [Alphabet]
    let displayName: String
    let nativeName: String?
    /// `nil` for free alphabets; the localized price otherwise.
    let priceText: String?
    let isOwned: Bool

    /// The single alphabet's own id, or a join of every member's id for a
    /// bundled pack — stable and unique regardless of grouping.
    var id: String {
        alphabets.count == 1 ? alphabets[0].id : alphabets.map(\.id).joined(separator: "+")
    }
}
