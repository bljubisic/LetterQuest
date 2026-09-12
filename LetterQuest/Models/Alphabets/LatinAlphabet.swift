import Foundation

/// The built-in Latin alphabet (English uppercase + lowercase) — always
/// installed, free, and the first `Alphabet` entry. Letters A–E/a–e are
/// easy, F–O/f–o medium, P–Z/p–z hard.
extension Alphabet {

    static let latinId = "latin"

    static let latin: Alphabet = {
        let upper = makeLetters(from: "ABCDEFGHIJKLMNOPQRSTUVWXYZ", case: .upper, imagePrefix: "template_")
        // "lc_" prefix avoids a case-collision with uppercase assets on macOS HFS+/APFS.
        let lower = makeLetters(from: "abcdefghijklmnopqrstuvwxyz", case: .lower, imagePrefix: "template_lc_")
        return Alphabet(
            id: latinId,
            displayName: "English",
            nativeName: "English",
            scriptCode: "Latn",
            localeIdentifier: "en",
            isFree: true,
            letters: upper + lower,
            productId: nil
        )
    }()

    private static func makeLetters(from characters: String, case letterCase: LetterCase, imagePrefix: String) -> [Letter] {
        characters.enumerated().map { index, char in
            Letter(
                id: DeterministicID.uuid(name: "letter.\(latinId).\(letterCase.rawValue).\(char)"),
                character: char,
                strokeTemplates: StrokeTemplate.templates(for: char),
                difficulty: index < 5 ? .easy : index < 15 ? .medium : .hard,
                templateImageName: "\(imagePrefix)\(char)",
                letterCase: letterCase,
                alphabetId: latinId
            )
        }
    }
}
