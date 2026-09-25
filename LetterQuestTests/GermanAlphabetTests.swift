import Testing
import Foundation
@testable import LetterQuest

struct GermanAlphabetTests {

    @Test("Alphabet.german has 59 letters (29 upper + 30 lower)")
    func germanHas59Letters() {
        #expect(Alphabet.german.letters.count == 59)
    }

    @Test("Alphabet.german is a paid pack, correctly identified")
    func germanMetadataIsCorrect() {
        let alphabet = Alphabet.german
        #expect(alphabet.id == "german")
        #expect(alphabet.isFree == false)
        #expect(alphabet.scriptCode == "Latn")
        #expect(alphabet.localeIdentifier == "de")
    }

    @Test("Alphabet.german is wired to the Extended Latin Pack's shared product id")
    func germanHasExtendedLatinProductId() {
        #expect(Alphabet.german.productId == Alphabet.extendedLatinProductId)
    }

    @Test("every letter in Alphabet.german is stamped with alphabetId \"german\"")
    func everyLetterHasGermanAlphabetId() {
        for letter in Alphabet.german.letters {
            #expect(letter.alphabetId == "german")
        }
    }

    @Test("every letter's id is unique")
    func everyLetterHasUniqueId() {
        let ids = Alphabet.german.letters.map(\.id)
        #expect(Set(ids).count == ids.count)
    }

    @Test("the 26 standard letters reuse Latin's own template images")
    func standardLettersReuseLatinTemplateImages() {
        let a = Alphabet.german.letters.first { $0.character == "A" }
        let z = Alphabet.german.letters.first { $0.character == "z" }
        #expect(a?.templateImageName == "template_A")
        #expect(z?.templateImageName == "template_lc_z")
    }

    @Test("the 4 special characters get their own German template images")
    func specialCharactersGetGermanTemplateImages() {
        let letters = Alphabet.german.letters
        #expect(letters.first { $0.character == "Ä" }?.templateImageName == "template_de_ae")
        #expect(letters.first { $0.character == "Ö" }?.templateImageName == "template_de_oe")
        #expect(letters.first { $0.character == "Ü" }?.templateImageName == "template_de_ue")
        #expect(letters.first { $0.character == "ä" }?.templateImageName == "template_de_lc_ae")
        #expect(letters.first { $0.character == "ö" }?.templateImageName == "template_de_lc_oe")
        #expect(letters.first { $0.character == "ü" }?.templateImageName == "template_de_lc_ue")
        #expect(letters.first { $0.character == "ß" }?.templateImageName == "template_de_lc_ss")
    }
}

// MARK: - Stroke-order oracle for the 7 German-specific glyphs

private typealias Spec = (strokes: Int, directions: [StrokeDirection])

private let germanLetterSpec: [Character: Spec] = [
    "Ä": (5, [.diagonal(angle: 45), .diagonal(angle: -45), .leftToRight, .leftToRight, .leftToRight]),
    "Ö": (3, [.curved, .leftToRight, .leftToRight]),
    "Ü": (3, [.curved, .leftToRight, .leftToRight]),
    "ä": (4, [.curved, .topToBottom, .leftToRight, .leftToRight]),
    "ö": (3, [.curved, .leftToRight, .leftToRight]),
    "ü": (3, [.curved, .leftToRight, .leftToRight]),
    "ß": (3, [.topToBottom, .curved, .curved]),
]

struct GermanStrokeTemplateTests {

    @Test("each German-specific glyph matches its expected stroke count and direction sequence",
          arguments: Array(germanLetterSpec.keys))
    func glyphMatchesSpec(character: Character) {
        let spec = germanLetterSpec[character]!
        let templates = StrokeTemplate.templates(for: character)
        #expect(templates.count == spec.strokes)
        #expect(templates.map(\.direction) == spec.directions)
    }
}
