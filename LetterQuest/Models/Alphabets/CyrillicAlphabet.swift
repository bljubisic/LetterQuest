import Foundation

/// The first purchasable `Alphabet` pack: Serbian Cyrillic (uppercase +
/// lowercase). Letters A–Д/а–д are easy, Ђ–М/ђ–м medium, Н–Ш/н–ш hard —
/// the same positional-banding thresholds `LatinAlphabet` uses, applied to
/// Serbian alphabetical order.
extension Alphabet {

    static let cyrillicSrId = "cyrillic-sr"
    static let cyrillicSrProductId = "com.persukibo.letterquest.alphabet.cyrillic_sr"

    static let cyrillicSr: Alphabet = {
        let upper = makeLetters(from: uppercaseLetters, case: .upper, imagePrefix: "template_cyr_")
        let lower = makeLetters(from: lowercaseLetters, case: .lower, imagePrefix: "template_cyr_lc_")
        return Alphabet(
            id: cyrillicSrId,
            displayName: "Serbian Cyrillic",
            nativeName: "Српски",
            scriptCode: "Cyrl",
            localeIdentifier: "sr",
            isFree: false,
            letters: upper + lower,
            productId: cyrillicSrProductId
        )
    }()

    /// (character, ASCII-safe asset-name fragment) pairs, in Serbian
    /// alphabetical order. `asciiName` stands in for the character in image
    /// asset names — raw Cyrillic in a filename is a real footgun for
    /// git/Xcode asset-catalog tooling — while `Letter.character` keeps the
    /// real Cyrillic glyph everywhere else. Names loosely follow Gaj's Latin
    /// (Serbian's own official parallel script) with ASCII-only digraphs for
    /// the letters that use diacritics there (đ→dj, ž→zh, ć→tj, č→ch, š→sh).
    private static let uppercaseLetters: [(Character, String)] = [
        ("А", "a"), ("Б", "b"), ("В", "v"), ("Г", "g"), ("Д", "d"), ("Ђ", "dj"),
        ("Е", "e"), ("Ж", "zh"), ("З", "z"), ("И", "i"), ("Ј", "j"), ("К", "k"),
        ("Л", "l"), ("Љ", "lj"), ("М", "m"), ("Н", "n"), ("Њ", "nj"), ("О", "o"),
        ("П", "p"), ("Р", "r"), ("С", "s"), ("Т", "t"), ("Ћ", "tj"), ("У", "u"),
        ("Ф", "f"), ("Х", "h"), ("Ц", "c"), ("Ч", "ch"), ("Џ", "dzh"), ("Ш", "sh")
    ]

    private static let lowercaseLetters: [(Character, String)] = uppercaseLetters.map { char, asciiName in
        (Character(String(char).lowercased()), asciiName)
    }

    private static func makeLetters(from pairs: [(Character, String)], case letterCase: LetterCase, imagePrefix: String) -> [Letter] {
        pairs.enumerated().map { index, pair in
            let (character, asciiName) = pair
            return Letter(
                id: DeterministicID.uuid(name: "letter.\(cyrillicSrId).\(letterCase.rawValue).\(character)"),
                character: character,
                strokeTemplates: StrokeTemplate.templates(for: character),
                difficulty: index < 5 ? .easy : index < 15 ? .medium : .hard,
                templateImageName: "\(imagePrefix)\(asciiName)",
                letterCase: letterCase,
                alphabetId: cyrillicSrId
            )
        }
    }
}
