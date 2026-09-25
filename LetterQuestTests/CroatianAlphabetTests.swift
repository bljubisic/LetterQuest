import Testing
import Foundation
@testable import LetterQuest

struct CroatianAlphabetTests {

    @Test("Alphabet.croatian has 60 letters (30 upper + 30 lower)")
    func croatianHas60Letters() {
        #expect(Alphabet.croatian.letters.count == 60)
    }

    @Test("Alphabet.croatian is a paid pack, correctly identified")
    func croatianMetadataIsCorrect() {
        let alphabet = Alphabet.croatian
        #expect(alphabet.id == "croatian")
        #expect(alphabet.isFree == false)
        #expect(alphabet.scriptCode == "Latn")
        #expect(alphabet.localeIdentifier == "hr")
    }

    @Test("Alphabet.croatian is wired to the Extended Latin Pack's shared product id")
    func croatianHasExtendedLatinProductId() {
        #expect(Alphabet.croatian.productId == Alphabet.extendedLatinProductId)
    }

    @Test("every letter in Alphabet.croatian is stamped with alphabetId \"croatian\"")
    func everyLetterHasCroatianAlphabetId() {
        for letter in Alphabet.croatian.letters {
            #expect(letter.alphabetId == "croatian")
        }
    }

    @Test("every letter's id is unique")
    func everyLetterHasUniqueId() {
        let ids = Alphabet.croatian.letters.map(\.id)
        #expect(Set(ids).count == ids.count)
    }

    @Test("letters follow native abeceda order, with the digraphs as single letters")
    func lettersFollowAbecedaOrder() {
        let upper = String(Alphabet.croatian.letters.filter { $0.letterCase == .upper }.map(\.character))
        let lower = String(Alphabet.croatian.letters.filter { $0.letterCase == .lower }.map(\.character))
        #expect(upper == "ABCČĆDǄĐEFGHIJKLǇMNǊOPRSŠTUVZŽ")
        #expect(lower == "abcčćdǆđefghijklǉmnǌoprsštuvzž")
    }

    @Test("Q, W, X and Y are not part of the alphabet")
    func excludesQWXY() {
        let characters = Set(Alphabet.croatian.letters.map(\.character))
        for excluded: Character in ["Q", "W", "X", "Y", "q", "w", "x", "y"] {
            #expect(!characters.contains(excluded))
        }
    }

    @Test("digraph letters are classified by case like any other letter")
    func digraphsHaveCorrectCase() {
        for character: Character in ["Ǆ", "Ǉ", "Ǌ"] { #expect(character.isUppercase) }
        for character: Character in ["ǆ", "ǉ", "ǌ"] { #expect(character.isLowercase) }
    }

    @Test("the base letters reuse Latin's own template images")
    func standardLettersReuseLatinTemplateImages() {
        let letters = Alphabet.croatian.letters
        #expect(letters.first { $0.character == "A" }?.templateImageName == "template_A")
        #expect(letters.first { $0.character == "z" }?.templateImageName == "template_lc_z")
    }

    @Test("the new letters get their own Croatian template images",
          arguments: [
            ("Č", "template_hr_ccaron"), ("Ć", "template_hr_cacute"), ("Đ", "template_hr_dstroke"),
            ("Š", "template_hr_scaron"), ("Ž", "template_hr_zcaron"), ("Ǆ", "template_hr_dzcaron"),
            ("Ǉ", "template_hr_lj"), ("Ǌ", "template_hr_nj"),
            ("č", "template_hr_lc_ccaron"), ("ć", "template_hr_lc_cacute"), ("đ", "template_hr_lc_dstroke"),
            ("š", "template_hr_lc_scaron"), ("ž", "template_hr_lc_zcaron"), ("ǆ", "template_hr_lc_dzcaron"),
            ("ǉ", "template_hr_lc_lj"), ("ǌ", "template_hr_lc_nj"),
          ] as [(Character, String)])
    func newLettersGetCroatianTemplateImages(character: Character, imageName: String) {
        let letter = Alphabet.croatian.letters.first { $0.character == character }
        #expect(letter?.templateImageName == imageName)
    }
}

// MARK: - Stroke-order oracle for Croatian's own glyphs

private typealias Spec = (strokes: Int, directions: [StrokeDirection])

/// Marks above a letter (caron, acute) and the bar through Đ/đ come last.
private let croatianLetterSpec: [Character: Spec] = [
    "Č": (2, [.curved, .curved]),
    "Ć": (2, [.curved, .diagonal(angle: -45)]),
    "Đ": (3, [.topToBottom, .curved, .leftToRight]),
    "Š": (2, [.curved, .curved]),
    "Ž": (4, [.leftToRight, .diagonal(angle: -45), .leftToRight, .curved]),
    "Ǆ": (6, [.topToBottom, .curved, .leftToRight, .diagonal(angle: -45), .leftToRight, .curved]),
    "Ǉ": (4, [.topToBottom, .leftToRight, .topToBottom, .curved]),
    "Ǌ": (5, [.topToBottom, .diagonal(angle: 45), .topToBottom, .topToBottom, .curved]),
    "č": (2, [.curved, .curved]),
    "ć": (2, [.curved, .diagonal(angle: -45)]),
    "đ": (3, [.curved, .topToBottom, .leftToRight]),
    "š": (2, [.curved, .curved]),
    "ž": (4, [.leftToRight, .diagonal(angle: -45), .leftToRight, .curved]),
    "ǆ": (6, [.curved, .topToBottom, .leftToRight, .diagonal(angle: -45), .leftToRight, .curved]),
    "ǉ": (3, [.topToBottom, .topToBottom, .leftToRight]),
    "ǌ": (4, [.topToBottom, .topToBottom, .topToBottom, .leftToRight]),
]

struct CroatianStrokeTemplateTests {

    @Test("each Croatian-specific glyph matches its expected stroke count and direction sequence",
          arguments: Array(croatianLetterSpec.keys))
    func glyphMatchesSpec(character: Character) {
        let spec = croatianLetterSpec[character]!
        let templates = StrokeTemplate.templates(for: character)
        #expect(templates.count == spec.strokes)
        #expect(templates.map(\.direction) == spec.directions)
    }

    @Test("the caron/acute sits above the letter body without touching it",
          arguments: Array("ČĆŠŽčćšž"))
    func markClearsLetterBody(character: Character) {
        let templates = StrokeTemplate.templates(for: character)
        let markBottom = templates.last?.points.map(\.y).max() ?? 1
        let bodyTop = templates.dropLast().flatMap(\.points).map(\.y).min() ?? 0
        #expect(bodyTop - markBottom >= 0.1)
    }
}
