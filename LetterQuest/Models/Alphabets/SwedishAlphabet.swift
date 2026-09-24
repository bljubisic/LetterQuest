import Foundation

/// Swedish — a content pack in the Extended Latin Pack (issue #52). Reuses
/// the standard A–Z/a–z Latin letterforms as-is and appends Swedish's own
/// Å Ä Ö / å ä ö after Z/z, in Swedish alphabetical order — mirroring
/// `GermanAlphabet.swift`'s convention.
extension Alphabet {

    static let swedishId = "swedish"

    static let swedish: Alphabet = {
        let upper = makeLetters(from: "ABCDEFGHIJKLMNOPQRSTUVWXYZÅÄÖ", case: .upper)
        let lower = makeLetters(from: "abcdefghijklmnopqrstuvwxyzåäö", case: .lower)
        return Alphabet(
            id: swedishId,
            displayName: "Swedish",
            nativeName: "Svenska",
            scriptCode: "Latn",
            localeIdentifier: "sv",
            isFree: false,
            letters: upper + lower,
            productId: extendedLatinProductId
        )
    }()

    /// ASCII-safe asset-name fragments for Swedish's own special character
    /// Å/å — same reasoning as `SpanishAlphabet.swift`'s `specialAssetNames`.
    /// Must stay in sync with `SWEDISH_ASCII_NAMES` in `generate_templates.py`.
    private static let specialAssetNames: [Character: String] = [
        "Å": "aring", "å": "aring"
    ]

    /// Ä/Ö/ä/ö are the same glyphs as German's, so they reuse German's
    /// `template_de_*` images instead of generating duplicates.
    private static let germanAssetNames: [Character: String] = [
        "Ä": "ae", "Ö": "oe", "ä": "ae", "ö": "oe"
    ]

    private static func makeLetters(from characters: String, case letterCase: LetterCase) -> [Letter] {
        let lcPrefix = letterCase == .lower ? "lc_" : ""
        return characters.enumerated().map { index, char in
            let imageName: String
            if let fragment = specialAssetNames[char] {
                imageName = "template_sv_\(lcPrefix)\(fragment)"
            } else if let fragment = germanAssetNames[char] {
                imageName = "template_de_\(lcPrefix)\(fragment)"
            } else {
                imageName = "template_\(lcPrefix)\(char)"
            }
            return Letter(
                id: DeterministicID.uuid(name: "letter.\(swedishId).\(letterCase.rawValue).\(char)"),
                character: char,
                strokeTemplates: StrokeTemplate.templates(for: char),
                difficulty: index < 5 ? .easy : index < 15 ? .medium : .hard,
                templateImageName: imageName,
                letterCase: letterCase,
                alphabetId: swedishId
            )
        }
    }
}
