import Testing
import Foundation
@testable import LetterQuest

struct SwedishAlphabetTests {

    @Test("Alphabet.swedish has 58 letters (29 upper + 29 lower)")
    func swedishHas58Letters() {
        #expect(Alphabet.swedish.letters.count == 58)
    }

    @Test("Alphabet.swedish is a paid pack, correctly identified")
    func swedishMetadataIsCorrect() {
        let alphabet = Alphabet.swedish
        #expect(alphabet.id == "swedish")
        #expect(alphabet.isFree == false)
        #expect(alphabet.scriptCode == "Latn")
        #expect(alphabet.localeIdentifier == "sv")
    }

    @Test("Alphabet.swedish is wired to the Extended Latin Pack's shared product id")
    func swedishHasExtendedLatinProductId() {
        #expect(Alphabet.swedish.productId == Alphabet.extendedLatinProductId)
    }

    @Test("every letter in Alphabet.swedish is stamped with alphabetId \"swedish\"")
    func everyLetterHasSwedishAlphabetId() {
        for letter in Alphabet.swedish.letters {
            #expect(letter.alphabetId == "swedish")
        }
    }

    @Test("every letter's id is unique")
    func everyLetterHasUniqueId() {
        let ids = Alphabet.swedish.letters.map(\.id)
        #expect(Set(ids).count == ids.count)
    }

    @Test("Å, Ä, Ö follow Z (and å, ä, ö follow z) in Swedish alphabetical order")
    func specialLettersFollowZ() {
        let characters = Alphabet.swedish.letters.map(\.character)
        let upper = characters.filter { $0.isUppercase }
        let lower = characters.filter { $0.isLowercase }
        #expect(Array(upper.suffix(4)) == ["Z", "Å", "Ä", "Ö"])
        #expect(Array(lower.suffix(4)) == ["z", "å", "ä", "ö"])
    }

    @Test("the 26 standard letters reuse Latin's own template images")
    func standardLettersReuseLatinTemplateImages() {
        let a = Alphabet.swedish.letters.first { $0.character == "A" }
        let z = Alphabet.swedish.letters.first { $0.character == "z" }
        #expect(a?.templateImageName == "template_A")
        #expect(z?.templateImageName == "template_lc_z")
    }

    @Test("Å/å get their own Swedish template images")
    func aRingGetsSwedishTemplateImages() {
        let letters = Alphabet.swedish.letters
        #expect(letters.first { $0.character == "Å" }?.templateImageName == "template_sv_aring")
        #expect(letters.first { $0.character == "å" }?.templateImageName == "template_sv_lc_aring")
    }

    @Test("Ä/Ö/ä/ö reuse German's template images rather than generating duplicates")
    func umlautLettersReuseGermanTemplateImages() {
        let letters = Alphabet.swedish.letters
        #expect(letters.first { $0.character == "Ä" }?.templateImageName == "template_de_ae")
        #expect(letters.first { $0.character == "Ö" }?.templateImageName == "template_de_oe")
        #expect(letters.first { $0.character == "ä" }?.templateImageName == "template_de_lc_ae")
        #expect(letters.first { $0.character == "ö" }?.templateImageName == "template_de_lc_oe")
    }
}

// MARK: - Stroke-order oracle for Swedish's own glyphs

private typealias Spec = (strokes: Int, directions: [StrokeDirection])

private let swedishLetterSpec: [Character: Spec] = [
    // Ring comes last, like every other mark above a letter.
    "Å": (4, [.diagonal(angle: 45), .diagonal(angle: -45), .leftToRight, .curved]),
    "å": (3, [.curved, .topToBottom, .curved]),
]

struct SwedishStrokeTemplateTests {

    @Test("each Swedish-specific glyph matches its expected stroke count and direction sequence",
          arguments: Array(swedishLetterSpec.keys))
    func glyphMatchesSpec(character: Character) {
        let spec = swedishLetterSpec[character]!
        let templates = StrokeTemplate.templates(for: character)
        #expect(templates.count == spec.strokes)
        #expect(templates.map(\.direction) == spec.directions)
    }

    @Test("Ä/Ö/ä/ö in Swedish resolve to German's stroke templates",
          arguments: Array("ÄÖäö"))
    func umlautsMatchGerman(character: Character) {
        let swedish = Alphabet.swedish.letters.first { $0.character == character }?.strokeTemplates ?? []
        let german = Alphabet.german.letters.first { $0.character == character }?.strokeTemplates ?? []
        #expect(!swedish.isEmpty)
        #expect(swedish.count == german.count)
        #expect(swedish.map(\.direction) == german.map(\.direction))
        #expect(swedish.map(\.points) == german.map(\.points))
    }

    @Test("the ring on Å/å sits above the letter body without touching it")
    func ringClearsLetterBody() {
        for character: Character in ["Å", "å"] {
            let templates = StrokeTemplate.templates(for: character)
            let ringBottom = templates.last?.points.map(\.y).max() ?? 1
            let bodyTop = templates.dropLast().flatMap(\.points).map(\.y).min() ?? 0
            #expect(bodyTop - ringBottom >= 0.1)
        }
    }
}
