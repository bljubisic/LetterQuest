import Foundation

/// Describes a single installable script/content pack (e.g. the built-in
/// Latin alphabet, or a future purchasable Serbian Cyrillic pack).
///
/// Conforming types are immutable value types.
protocol AlphabetProtocol {
    /// Stable slug identifying this alphabet, e.g. `"latin"`. Used to scope
    /// `Letter.id` generation and to key `ChildProgress.alphabetId`.
    var id: String { get }

    /// English display name shown in the UI, e.g. `"English"`.
    var displayName: String { get }

    /// The alphabet's name in its own script/language, e.g. `"Српски"`.
    var nativeName: String { get }

    /// ISO 15924 script code, e.g. `"Latn"`, `"Cyrl"`.
    var scriptCode: String { get }

    /// BCP 47 / ISO locale identifier, e.g. `"en"`, `"sr"`.
    var localeIdentifier: String { get }

    /// `true` for alphabets bundled with the app at no cost; `false` for
    /// purchasable packs.
    var isFree: Bool { get }

    /// Every letter (all cases) belonging to this alphabet.
    var letters: [Letter] { get }

    /// The StoreKit non-consumable product id that unlocks this alphabet.
    /// `nil` for free/built-in alphabets, which never need a purchase.
    var productId: String? { get }
}
