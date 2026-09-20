import Foundation

/// German — the first content pack in the Extended Latin Pack (issue #52).
/// Reuses the standard A–Z/a–z Latin letterforms as-is (German prints them
/// identically to English) and adds the 4 script-specific characters:
/// Ä Ö Ü / ä ö ü ß, appended after Z/z rather than interleaved, mirroring
/// how Swedish's Å Ä Ö will also be appended at the end of its own alphabet.
extension Alphabet {

    static let germanId = "german"

    static let german: Alphabet = {
        let upper = makeLetters(from: "ABCDEFGHIJKLMNOPQRSTUVWXYZÄÖÜ", case: .upper)
        let lower = makeLetters(from: "abcdefghijklmnopqrstuvwxyzäöüß", case: .lower)
        return Alphabet(
            id: germanId,
            displayName: "German",
            nativeName: "Deutsch",
            scriptCode: "Latn",
            localeIdentifier: "de",
            isFree: false,
            letters: upper + lower,
            productId: extendedLatinProductId
        )
    }()

    /// ASCII-safe asset-name fragments for the 4 non-ASCII characters —
    /// raw diacritics in a filename are a footgun for git/Xcode asset-
    /// catalog tooling, same reasoning as `CyrillicAlphabet.swift`'s
    /// `asciiName`. The other 26 letters reuse Latin's own
    /// `template_<char>`/`template_lc_<char>` images — German draws them
    /// identically, so no new assets are needed for those.
    private static let specialAssetNames: [Character: String] = [
        "Ä": "ae", "Ö": "oe", "Ü": "ue",
        "ä": "ae", "ö": "oe", "ü": "ue", "ß": "ss"
    ]

    private static func makeLetters(from characters: String, case letterCase: LetterCase) -> [Letter] {
        characters.enumerated().map { index, char in
            let imageName = specialAssetNames[char].map { "template_de_\(letterCase == .lower ? "lc_" : "")\($0)" }
                ?? "template_\(letterCase == .lower ? "lc_" : "")\(char)"
            return Letter(
                id: DeterministicID.uuid(name: "letter.\(germanId).\(letterCase.rawValue).\(char)"),
                character: char,
                strokeTemplates: StrokeTemplate.templates(for: char),
                difficulty: index < 5 ? .easy : index < 15 ? .medium : .hard,
                templateImageName: imageName,
                letterCase: letterCase,
                alphabetId: germanId
            )
        }
    }
}
