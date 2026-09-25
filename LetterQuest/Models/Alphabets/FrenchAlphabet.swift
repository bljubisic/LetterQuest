import Foundation

/// French — a content pack in the Extended Latin Pack (issue #52). Reuses
/// the standard A–Z/a–z Latin letterforms as-is and appends French's own
/// letters — the accented vowels, Ç and the ligatures Æ Œ — after Z/z,
/// mirroring `GermanAlphabet.swift`'s convention.
extension Alphabet {

    static let frenchId = "french"

    static let french: Alphabet = {
        let upper = makeLetters(from: "ABCDEFGHIJKLMNOPQRSTUVWXYZÀÂÆÇÉÈÊËÎÏÔŒÙÛÜŸ", case: .upper)
        let lower = makeLetters(from: "abcdefghijklmnopqrstuvwxyzàâæçéèêëîïôœùûüÿ", case: .lower)
        return Alphabet(
            id: frenchId,
            displayName: "French",
            nativeName: "Français",
            scriptCode: "Latn",
            localeIdentifier: "fr",
            isFree: false,
            letters: upper + lower,
            productId: extendedLatinProductId
        )
    }()

    /// ASCII-safe asset-name fragments for French's 14 own letters — same
    /// reasoning as `SpanishAlphabet.swift`'s `specialAssetNames`. Must stay
    /// in sync with `FRENCH_ASCII_NAMES` in `generate_templates.py`.
    private static let specialAssetNames: [Character: String] = [
        "À": "agrave", "Â": "acirc", "Æ": "aelig", "Ç": "ccedil", "È": "egrave", "Ê": "ecirc", "Ë": "euml",
        "Î": "icirc", "Ï": "iuml", "Ô": "ocirc", "Œ": "oelig", "Ù": "ugrave", "Û": "ucirc", "Ÿ": "yuml",
        "à": "agrave", "â": "acirc", "æ": "aelig", "ç": "ccedil", "è": "egrave", "ê": "ecirc", "ë": "euml",
        "î": "icirc", "ï": "iuml", "ô": "ocirc", "œ": "oelig", "ù": "ugrave", "û": "ucirc", "ÿ": "yuml"
    ]

    /// É/é and Ü/ü are the same glyphs as Spanish's and German's, so they
    /// reuse those packs' images instead of generating duplicates.
    private static let borrowedAssetNames: [Character: (pack: String, fragment: String)] = [
        "É": ("es", "eacute"), "é": ("es", "eacute"), "Ü": ("de", "ue"), "ü": ("de", "ue")
    ]

    private static func makeLetters(from characters: String, case letterCase: LetterCase) -> [Letter] {
        let lcPrefix = letterCase == .lower ? "lc_" : ""
        return characters.enumerated().map { index, char in
            let imageName: String
            if let fragment = specialAssetNames[char] {
                imageName = "template_fr_\(lcPrefix)\(fragment)"
            } else if let borrowed = borrowedAssetNames[char] {
                imageName = "template_\(borrowed.pack)_\(lcPrefix)\(borrowed.fragment)"
            } else {
                imageName = "template_\(lcPrefix)\(char)"
            }
            return Letter(
                id: DeterministicID.uuid(name: "letter.\(frenchId).\(letterCase.rawValue).\(char)"),
                character: char,
                strokeTemplates: StrokeTemplate.templates(for: char),
                difficulty: index < 5 ? .easy : index < 15 ? .medium : .hard,
                templateImageName: imageName,
                letterCase: letterCase,
                alphabetId: frenchId
            )
        }
    }
}
