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

// MARK: - Shared pack product ids

extension Alphabet {

    /// The Extended Latin Pack (issue #52): a single purchase unlocking
    /// several Latin-script alphabets at once. Every member alphabet sets
    /// its own `productId` to this same value — `AlphabetRepository`'s
    /// entitlement check and `AlphabetStoreViewModel`'s row-grouping key
    /// off `productId` alone, so sharing this id is the entire mechanism.
    static let extendedLatinProductId = "com.persukibo.letterquest.alphabet.extended_latin"
}
