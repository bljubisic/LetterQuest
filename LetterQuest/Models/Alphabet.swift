import Foundation

/// A single installable script/content pack. See `Alphabets/LatinAlphabet.swift`
/// for the built-in, always-installed entry.
struct Alphabet: AlphabetProtocol, Equatable, Identifiable {
    let id: String
    let displayName: String
    let nativeName: String
    let scriptCode: String
    let localeIdentifier: String
    let isFree: Bool
    let letters: [Letter]

    /// The StoreKit non-consumable product id that unlocks this alphabet.
    /// `nil` for free/built-in alphabets, which never need a purchase.
    let productId: String?
}
