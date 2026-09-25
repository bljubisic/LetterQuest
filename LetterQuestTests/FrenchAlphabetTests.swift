import Testing
import Foundation
@testable import LetterQuest

struct FrenchAlphabetTests {

    @Test("Alphabet.french has 84 letters (42 upper + 42 lower)")
    func frenchHas84Letters() {
        #expect(Alphabet.french.letters.count == 84)
    }

    @Test("Alphabet.french is a paid pack, correctly identified")
    func frenchMetadataIsCorrect() {
        let alphabet = Alphabet.french
        #expect(alphabet.id == "french")
        #expect(alphabet.isFree == false)
        #expect(alphabet.scriptCode == "Latn")
        #expect(alphabet.localeIdentifier == "fr")
    }

    @Test("Alphabet.french is wired to the Extended Latin Pack's shared product id")
    func frenchHasExtendedLatinProductId() {
        #expect(Alphabet.french.productId == Alphabet.extendedLatinProductId)
    }

    @Test("every letter in Alphabet.french is stamped with alphabetId \"french\"")
    func everyLetterHasFrenchAlphabetId() {
        for letter in Alphabet.french.letters {
            #expect(letter.alphabetId == "french")
        }
    }

    @Test("every letter's id is unique")
    func everyLetterHasUniqueId() {
        let ids = Alphabet.french.letters.map(\.id)
        #expect(Set(ids).count == ids.count)
    }

    @Test("A–Z come first, then French's own letters")
    func lettersFollowExpectedOrder() {
        let upper = String(Alphabet.french.letters.filter { $0.letterCase == .upper }.map(\.character))
        let lower = String(Alphabet.french.letters.filter { $0.letterCase == .lower }.map(\.character))
        #expect(upper == "ABCDEFGHIJKLMNOPQRSTUVWXYZÀÂÆÇÉÈÊËÎÏÔŒÙÛÜŸ")
        #expect(lower == "abcdefghijklmnopqrstuvwxyzàâæçéèêëîïôœùûüÿ")
    }

    @Test("difficulty follows alphabet position: 5 easy, 10 medium, the rest hard")
    func difficultyFollowsPosition() {
        for letterCase in [LetterCase.upper, .lower] {
            let letters = Alphabet.french.letters.filter { $0.letterCase == letterCase }
            #expect(letters.prefix(5).allSatisfy { $0.difficulty == .easy })
            #expect(letters.dropFirst(5).prefix(10).allSatisfy { $0.difficulty == .medium })
            #expect(letters.dropFirst(15).allSatisfy { $0.difficulty == .hard })
        }
    }

    @Test("the base letters reuse Latin's own template images")
    func standardLettersReuseLatinTemplateImages() {
        let letters = Alphabet.french.letters
        #expect(letters.first { $0.character == "A" }?.templateImageName == "template_A")
        #expect(letters.first { $0.character == "z" }?.templateImageName == "template_lc_z")
    }

    @Test("French's own 14 letters get their own French template images",
          arguments: Array(zip("ÀÂÆÇÈÊËÎÏÔŒÙÛŸ", ["agrave", "acirc", "aelig", "ccedil", "egrave", "ecirc", "euml",
                                                "icirc", "iuml", "ocirc", "oelig", "ugrave", "ucirc", "yuml"])))
    func newLettersGetFrenchTemplateImages(character: Character, fragment: String) {
        let letters = Alphabet.french.letters
        let lower = Character(character.lowercased())
        #expect(letters.first { $0.character == character }?.templateImageName == "template_fr_\(fragment)")
        #expect(letters.first { $0.character == lower }?.templateImageName == "template_fr_lc_\(fragment)")
    }

    @Test("É/é reuse Spanish's images and Ü/ü reuse German's, rather than generating duplicates")
    func sharedGlyphsReuseOtherPacksTemplateImages() {
        let letters = Alphabet.french.letters
        #expect(letters.first { $0.character == "É" }?.templateImageName == "template_es_eacute")
        #expect(letters.first { $0.character == "é" }?.templateImageName == "template_es_lc_eacute")
        #expect(letters.first { $0.character == "Ü" }?.templateImageName == "template_de_ue")
        #expect(letters.first { $0.character == "ü" }?.templateImageName == "template_de_lc_ue")
    }
}

// MARK: - Stroke-order oracle for French's own glyphs

private typealias Spec = (strokes: Int, directions: [StrokeDirection])

/// Marks above a letter come last; the cedilla is drawn after its C. The
/// circumflex is labelled by its overall left-to-right travel (see
/// `FrenchStrokeDefinitions.circumflex`).
private let frenchLetterSpec: [Character: Spec] = [
    "À": (4, [.diagonal(angle: 45), .diagonal(angle: -45), .leftToRight, .diagonal(angle: 45)]),
    "Â": (4, [.diagonal(angle: 45), .diagonal(angle: -45), .leftToRight, .leftToRight]),
    "Æ": (6, [.diagonal(angle: -45), .topToBottom, .leftToRight, .leftToRight, .leftToRight, .leftToRight]),
    "Ç": (2, [.curved, .curved]),
    "È": (5, [.topToBottom, .leftToRight, .leftToRight, .leftToRight, .diagonal(angle: 45)]),
    "Ê": (5, [.topToBottom, .leftToRight, .leftToRight, .leftToRight, .leftToRight]),
    "Ë": (6, [.topToBottom, .leftToRight, .leftToRight, .leftToRight, .leftToRight, .leftToRight]),
    "Î": (2, [.topToBottom, .leftToRight]),
    "Ï": (3, [.topToBottom, .leftToRight, .leftToRight]),
    "Ô": (2, [.curved, .leftToRight]),
    "Œ": (5, [.curved, .topToBottom, .leftToRight, .leftToRight, .leftToRight]),
    "Ù": (2, [.curved, .diagonal(angle: 45)]),
    "Û": (2, [.curved, .leftToRight]),
    "Ÿ": (5, [.diagonal(angle: 45), .diagonal(angle: -45), .topToBottom, .leftToRight, .leftToRight]),
    "à": (3, [.curved, .topToBottom, .diagonal(angle: 45)]),
    "â": (3, [.curved, .topToBottom, .leftToRight]),
    "æ": (4, [.curved, .topToBottom, .leftToRight, .curved]),
    "ç": (2, [.curved, .curved]),
    "è": (3, [.leftToRight, .curved, .diagonal(angle: 45)]),
    "ê": (3, [.leftToRight, .curved, .leftToRight]),
    "ë": (4, [.leftToRight, .curved, .leftToRight, .leftToRight]),
    "î": (2, [.topToBottom, .leftToRight]),
    "ï": (3, [.topToBottom, .leftToRight, .leftToRight]),
    "ô": (2, [.curved, .leftToRight]),
    "œ": (3, [.curved, .leftToRight, .curved]),
    "ù": (2, [.curved, .diagonal(angle: 45)]),
    "û": (2, [.curved, .leftToRight]),
    "ÿ": (4, [.diagonal(angle: 45), .topToBottom, .leftToRight, .leftToRight]),
    // É/é resolve via SpanishStrokeDefinitions and Ü/ü via
    // GermanStrokeDefinitions — verified here too, confirming the
    // cross-language reuse works end to end.
    "É": (5, [.topToBottom, .leftToRight, .leftToRight, .leftToRight, .diagonal(angle: -45)]),
    "é": (3, [.leftToRight, .curved, .diagonal(angle: -45)]),
    "Ü": (3, [.curved, .leftToRight, .leftToRight]),
    "ü": (3, [.curved, .leftToRight, .leftToRight]),
]

struct FrenchStrokeTemplateTests {

    @Test("each French-specific glyph matches its expected stroke count and direction sequence",
          arguments: Array(frenchLetterSpec.keys))
    func glyphMatchesSpec(character: Character) {
        let spec = frenchLetterSpec[character]!
        let templates = StrokeTemplate.templates(for: character)
        #expect(templates.count == spec.strokes)
        #expect(templates.map(\.direction) == spec.directions)
    }

    @Test("marks above the letter clear its body without touching it",
          arguments: Array("ÀÂÈÊÎÔÙÛàâèêîôùû").map { ($0, 1) } + Array("ËÏŸëïÿ").map { ($0, 2) })
    func markClearsLetterBody(character: Character, markStrokeCount: Int) {
        let templates = StrokeTemplate.templates(for: character)
        let markBottom = templates.suffix(markStrokeCount).flatMap(\.points).map(\.y).max() ?? 1
        let bodyTop = templates.dropLast(markStrokeCount).flatMap(\.points).map(\.y).min() ?? 0
        #expect(bodyTop - markBottom >= 0.099)
    }

    @Test("the cedilla hangs below the C without touching it", arguments: Array("Çç"))
    func cedillaClearsLetterBody(character: Character) {
        let templates = StrokeTemplate.templates(for: character)
        let bodyBottom = templates[0].points.map(\.y).max() ?? 1
        let cedillaTop = templates[1].points.map(\.y).min() ?? 0
        #expect(cedillaTop - bodyBottom >= 0.03)
        #expect(templates[1].points.allSatisfy { $0.y <= 1 })
    }
}
