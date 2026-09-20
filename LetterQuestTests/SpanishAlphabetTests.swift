import Testing
import Foundation
@testable import LetterQuest

struct SpanishAlphabetTests {

    @Test("Alphabet.spanish has 66 letters (33 upper + 33 lower)")
    func spanishHas66Letters() {
        #expect(Alphabet.spanish.letters.count == 66)
    }

    @Test("Alphabet.spanish is a paid pack, correctly identified")
    func spanishMetadataIsCorrect() {
        let alphabet = Alphabet.spanish
        #expect(alphabet.id == "spanish")
        #expect(alphabet.isFree == false)
        #expect(alphabet.scriptCode == "Latn")
        #expect(alphabet.localeIdentifier == "es")
    }

    @Test("Alphabet.spanish is wired to the Extended Latin Pack's shared product id")
    func spanishHasExtendedLatinProductId() {
        #expect(Alphabet.spanish.productId == Alphabet.extendedLatinProductId)
    }

    @Test("every letter in Alphabet.spanish is stamped with alphabetId \"spanish\"")
    func everyLetterHasSpanishAlphabetId() {
        for letter in Alphabet.spanish.letters {
            #expect(letter.alphabetId == "spanish")
        }
    }

    @Test("every letter's id is unique")
    func everyLetterHasUniqueId() {
        let ids = Alphabet.spanish.letters.map(\.id)
        #expect(Set(ids).count == ids.count)
    }

    @Test("the 26 standard letters reuse Latin's own template images")
    func standardLettersReuseLatinTemplateImages() {
        let a = Alphabet.spanish.letters.first { $0.character == "A" }
        let z = Alphabet.spanish.letters.first { $0.character == "z" }
        #expect(a?.templateImageName == "template_A")
        #expect(z?.templateImageName == "template_lc_z")
    }

    @Test("Spanish's own 6 special characters get their own Spanish template images")
    func specialCharactersGetSpanishTemplateImages() {
        let letters = Alphabet.spanish.letters
        #expect(letters.first { $0.character == "Ñ" }?.templateImageName == "template_es_enye")
        #expect(letters.first { $0.character == "Á" }?.templateImageName == "template_es_aacute")
        #expect(letters.first { $0.character == "ñ" }?.templateImageName == "template_es_lc_enye")
        #expect(letters.first { $0.character == "ú" }?.templateImageName == "template_es_lc_uacute")
    }

    @Test("Ü/ü reuse German's template images rather than generating duplicates")
    func diaeresisLettersReuseGermanTemplateImages() {
        let letters = Alphabet.spanish.letters
        #expect(letters.first { $0.character == "Ü" }?.templateImageName == "template_de_ue")
        #expect(letters.first { $0.character == "ü" }?.templateImageName == "template_de_lc_ue")
    }
}

// MARK: - Stroke-order oracle for Spanish's own glyphs

private typealias Spec = (strokes: Int, directions: [StrokeDirection])

private let spanishLetterSpec: [Character: Spec] = [
    "Ñ": (4, [.topToBottom, .diagonal(angle: 45), .topToBottom, .curved]),
    "Á": (4, [.diagonal(angle: 45), .diagonal(angle: -45), .leftToRight, .diagonal(angle: -45)]),
    "É": (5, [.topToBottom, .leftToRight, .leftToRight, .leftToRight, .diagonal(angle: -45)]),
    "Í": (2, [.topToBottom, .diagonal(angle: -45)]),
    "Ó": (2, [.curved, .diagonal(angle: -45)]),
    "Ú": (2, [.curved, .diagonal(angle: -45)]),
    "ñ": (3, [.topToBottom, .topToBottom, .curved]),
    "á": (3, [.curved, .topToBottom, .diagonal(angle: -45)]),
    "é": (3, [.leftToRight, .curved, .diagonal(angle: -45)]),
    "í": (2, [.topToBottom, .diagonal(angle: -45)]),
    "ó": (2, [.curved, .diagonal(angle: -45)]),
    "ú": (2, [.curved, .diagonal(angle: -45)]),
    // Ü/ü resolve via GermanStrokeDefinitions (no entry in
    // SpanishStrokeDefinitions) — verified here too, confirming the
    // cross-language reuse actually works end to end.
    "Ü": (3, [.curved, .leftToRight, .leftToRight]),
    "ü": (3, [.curved, .leftToRight, .leftToRight]),
]

struct SpanishStrokeTemplateTests {

    @Test("each Spanish-specific glyph matches its expected stroke count and direction sequence",
          arguments: Array(spanishLetterSpec.keys))
    func glyphMatchesSpec(character: Character) {
        let spec = spanishLetterSpec[character]!
        let templates = StrokeTemplate.templates(for: character)
        #expect(templates.count == spec.strokes)
        #expect(templates.map(\.direction) == spec.directions)
    }
}
