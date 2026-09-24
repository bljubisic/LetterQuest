import Foundation

/// Croatian / Serbian (Latin) / Slovenian — a content pack in the Extended
/// Latin Pack (issue #52), built on Gaj's Latin alphabet. Unlike German and
/// Spanish, the extra letters sit in native abeceda order (C Č Ć D Dž Đ …),
/// the order children learn them in, and Q W X Y are left out. Slovenian
/// uses a subset (no Ć, Đ, Dž, Lj, Nj).
///
/// The digraphs Dž, Lj and Nj are stored as the single Unicode code points
/// Ǆ Ǉ Ǌ / ǆ ǉ ǌ so each is one `Character` — see
/// `CroatianStrokeDefinitions.swift`.
extension Alphabet {

    static let croatianId = "croatian"

    static let croatian: Alphabet = {
        let upper = makeLetters(from: "ABCČĆDǄĐEFGHIJKLǇMNǊOPRSŠTUVZŽ", case: .upper)
        let lower = makeLetters(from: "abcčćdǆđefghijklǉmnǌoprsštuvzž", case: .lower)
        return Alphabet(
            id: croatianId,
            displayName: "Croatian / Serbian / Slovenian",
            nativeName: "Hrvatski / Srpski / Slovenščina",
            scriptCode: "Latn",
            localeIdentifier: "hr",
            isFree: false,
            letters: upper + lower,
            productId: extendedLatinProductId
        )
    }()

    /// ASCII-safe asset-name fragments for the 8 letters with no Latin
    /// template image — same reasoning as `SpanishAlphabet.swift`'s
    /// `specialAssetNames`. Must stay in sync with `CROATIAN_ASCII_NAMES`
    /// in `generate_templates.py`.
    private static let specialAssetNames: [Character: String] = [
        "Č": "ccaron", "Ć": "cacute", "Đ": "dstroke", "Š": "scaron", "Ž": "zcaron",
        "Ǆ": "dzcaron", "Ǉ": "lj", "Ǌ": "nj",
        "č": "ccaron", "ć": "cacute", "đ": "dstroke", "š": "scaron", "ž": "zcaron",
        "ǆ": "dzcaron", "ǉ": "lj", "ǌ": "nj"
    ]

    private static func makeLetters(from characters: String, case letterCase: LetterCase) -> [Letter] {
        let lcPrefix = letterCase == .lower ? "lc_" : ""
        return characters.enumerated().map { index, char in
            let imageName = specialAssetNames[char].map { "template_hr_\(lcPrefix)\($0)" }
                ?? "template_\(lcPrefix)\(char)"
            return Letter(
                id: DeterministicID.uuid(name: "letter.\(croatianId).\(letterCase.rawValue).\(char)"),
                character: char,
                strokeTemplates: StrokeTemplate.templates(for: char),
                difficulty: index < 5 ? .easy : index < 15 ? .medium : .hard,
                templateImageName: imageName,
                letterCase: letterCase,
                alphabetId: croatianId
            )
        }
    }
}
