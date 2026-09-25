import Foundation

/// Spanish — a content pack in the Extended Latin Pack (issue #52). Reuses
/// the standard A–Z/a–z Latin letterforms as-is and adds Spanish's own
/// characters — Ñ/ñ and the accented vowels Á É Í Ó Ú / á é í ó ú, plus
/// Ü/ü — appended after Z/z, mirroring `GermanAlphabet.swift`'s convention.
extension Alphabet {

    static let spanishId = "spanish"

    static let spanish: Alphabet = {
        let upper = makeLetters(from: "ABCDEFGHIJKLMNOPQRSTUVWXYZÑÁÉÍÓÚÜ", case: .upper)
        let lower = makeLetters(from: "abcdefghijklmnopqrstuvwxyzñáéíóúü", case: .lower)
        return Alphabet(
            id: spanishId,
            displayName: "Spanish",
            nativeName: "Español",
            scriptCode: "Latn",
            localeIdentifier: "es",
            isFree: false,
            letters: upper + lower,
            productId: extendedLatinProductId
        )
    }()

    /// ASCII-safe asset-name fragments for Spanish's own 6 special
    /// characters — raw diacritics in a filename are a footgun for
    /// git/Xcode asset-catalog tooling, same reasoning as
    /// `CyrillicAlphabet.swift`'s `asciiName`. Ü/ü isn't listed here: it
    /// reuses German's own `template_de_ue`/`template_de_lc_ue` images
    /// (see `SpanishStrokeDefinitions.swift`'s header comment) since it's
    /// the same visual glyph. The other 26 letters reuse Latin's
    /// `template_<char>`/`template_lc_<char>` images.
    private static let specialAssetNames: [Character: String] = [
        "Ñ": "enye", "Á": "aacute", "É": "eacute", "Í": "iacute", "Ó": "oacute", "Ú": "uacute",
        "ñ": "enye", "á": "aacute", "é": "eacute", "í": "iacute", "ó": "oacute", "ú": "uacute"
    ]

    private static func makeLetters(from characters: String, case letterCase: LetterCase) -> [Letter] {
        let lcPrefix = letterCase == .lower ? "lc_" : ""
        return characters.enumerated().map { index, char in
            let imageName: String
            if let fragment = specialAssetNames[char] {
                imageName = "template_es_\(lcPrefix)\(fragment)"
            } else if char == "Ü" || char == "ü" {
                imageName = "template_de_\(lcPrefix)ue"
            } else {
                imageName = "template_\(lcPrefix)\(char)"
            }
            return Letter(
                id: DeterministicID.uuid(name: "letter.\(spanishId).\(letterCase.rawValue).\(char)"),
                character: char,
                strokeTemplates: StrokeTemplate.templates(for: char),
                difficulty: index < 5 ? .easy : index < 15 ? .medium : .hard,
                templateImageName: imageName,
                letterCase: letterCase,
                alphabetId: spanishId
            )
        }
    }
}
