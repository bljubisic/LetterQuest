import Testing
import CoreGraphics
@testable import LetterQuest

// MARK: - Expected stroke spec for all 30 uppercase Serbian Cyrillic letters
//
// Mirrors `StrokeTemplateTests.swift`'s `letterSpec` oracle for the Latin
// alphabet — each entry defines the stroke count and direction sequence
// `CyrillicStrokeDefinitions` should produce.

private typealias Spec = (strokes: Int, directions: [StrokeDirection])

private let cyrillicLetterSpec: [Character: Spec] = [
    "А": (3, [.diagonal(angle: 45), .diagonal(angle: -45), .leftToRight]),
    "Б": (3, [.topToBottom, .leftToRight, .curved]),
    "В": (2, [.topToBottom, .curved]),
    "Г": (2, [.leftToRight, .topToBottom]),
    "Д": (4, [.leftToRight, .topToBottom, .topToBottom, .leftToRight]),
    "Ђ": (3, [.leftToRight, .topToBottom, .curved]),
    "Е": (4, [.topToBottom, .leftToRight, .leftToRight, .leftToRight]),
    "Ж": (5, [.topToBottom, .diagonal(angle: 45), .diagonal(angle: -45), .diagonal(angle: -45), .diagonal(angle: 45)]),
    "З": (1, [.curved]),
    "И": (3, [.topToBottom, .diagonal(angle: -45), .topToBottom]),
    "Ј": (2, [.topToBottom, .curved]),
    "К": (3, [.topToBottom, .diagonal(angle: -45), .diagonal(angle: 45)]),
    "Л": (2, [.diagonal(angle: -45), .diagonal(angle: 45)]),
    "Љ": (4, [.leftToRight, .topToBottom, .topToBottom, .curved]),
    "М": (4, [.topToBottom, .diagonal(angle: 45), .diagonal(angle: -45), .topToBottom]),
    "Н": (3, [.topToBottom, .topToBottom, .leftToRight]),
    "Њ": (4, [.topToBottom, .topToBottom, .leftToRight, .curved]),
    "О": (1, [.curved]),
    "П": (3, [.leftToRight, .topToBottom, .topToBottom]),
    "Р": (2, [.topToBottom, .curved]),
    "С": (1, [.curved]),
    "Т": (2, [.leftToRight, .topToBottom]),
    "Ћ": (3, [.leftToRight, .topToBottom, .curved]),
    "У": (3, [.diagonal(angle: 45), .diagonal(angle: -45), .topToBottom]),
    "Ф": (2, [.topToBottom, .curved]),
    "Х": (2, [.diagonal(angle: 45), .diagonal(angle: -45)]),
    "Ц": (2, [.curved, .topToBottom]),
    "Ч": (2, [.topToBottom, .curved]),
    "Џ": (2, [.curved, .topToBottom]),
    "Ш": (4, [.topToBottom, .topToBottom, .topToBottom, .leftToRight])
]

private let allCyrillicUppercase = Array("АБВГДЂЕЖЗИЈКЛЉМНЊОПРСТЋУФХЦЧЏШ")
private let allCyrillicLetters = Array("АБВГДЂЕЖЗИЈКЛЉМНЊОПРСТЋУФХЦЧЏШабвгдђежзијклљмнњопрстћуфхцчџш")

// MARK: - Structural integrity (all 60 letters, upper + lower)

struct CyrillicStrokeTemplateStructureTests {

    @Test("Each letter returns at least one stroke template", arguments: allCyrillicLetters)
    func hasAtLeastOneStroke(letter: Character) {
        #expect(!StrokeTemplate.templates(for: letter).isEmpty)
    }

    @Test("strokeIndex values are zero-based and sequential", arguments: allCyrillicLetters)
    func strokeIndicesAreSequential(letter: Character) {
        let templates = StrokeTemplate.templates(for: letter)
        for (expected, template) in templates.enumerated() {
            #expect(template.strokeIndex == expected,
                    "Letter \(letter) stroke \(expected): strokeIndex is \(template.strokeIndex)")
        }
    }

    @Test("Every stroke has at least one reference point", arguments: allCyrillicLetters)
    func strokePointsNonEmpty(letter: Character) {
        for template in StrokeTemplate.templates(for: letter) {
            #expect(!template.points.isEmpty, "Letter \(letter) stroke \(template.strokeIndex) has no points")
        }
    }

    @Test("All reference points lie within the normalised 0–1 coordinate space", arguments: allCyrillicLetters)
    func strokePointsNormalized(letter: Character) {
        let tolerance = 0.01
        for template in StrokeTemplate.templates(for: letter) {
            for point in template.points {
                #expect(Double(point.x) >= -tolerance && Double(point.x) <= 1.0 + tolerance,
                        "Letter \(letter) stroke \(template.strokeIndex): x=\(point.x) is out of [0,1]")
                #expect(Double(point.y) >= -tolerance && Double(point.y) <= 1.0 + tolerance,
                        "Letter \(letter) stroke \(template.strokeIndex): y=\(point.y) is out of [0,1]")
            }
        }
    }

    @Test("Calling templates(for:) twice returns identical point sequences", arguments: allCyrillicLetters)
    func templateIsDeterministic(letter: Character) {
        let first  = StrokeTemplate.templates(for: letter).map(\.points)
        let second = StrokeTemplate.templates(for: letter).map(\.points)
        #expect(first == second, "Letter \(letter) templates are non-deterministic")
    }

    @Test("Every stroke has a unique id within its letter", arguments: allCyrillicLetters)
    func strokeIdsAreUnique(letter: Character) {
        let ids = StrokeTemplate.templates(for: letter).map(\.id)
        #expect(Set(ids).count == ids.count, "Letter \(letter) has duplicate stroke ids")
    }
}

// MARK: - Pedagogical correctness (uppercase only, mirroring the Latin asymmetry)

struct CyrillicStrokeTemplateCorrectnessTests {

    @Test("Each uppercase letter has the correct number of strokes", arguments: allCyrillicUppercase)
    func strokeCount(letter: Character) throws {
        let spec = try #require(cyrillicLetterSpec[letter], "No spec defined for letter \(letter)")
        let templates = StrokeTemplate.templates(for: letter)
        #expect(templates.count == spec.strokes,
                "Letter \(letter): expected \(spec.strokes) stroke(s), got \(templates.count)")
    }

    @Test("Each uppercase stroke has the correct expected direction", arguments: allCyrillicUppercase)
    func strokeDirections(letter: Character) throws {
        let spec = try #require(cyrillicLetterSpec[letter])
        let templates = StrokeTemplate.templates(for: letter)
        guard templates.count == spec.strokes else { return }
        for (index, (template, expected)) in zip(templates, spec.directions).enumerated() {
            #expect(template.direction == expected,
                    "Letter \(letter) stroke \(index): expected \(expected), got \(template.direction)")
        }
    }

    @Test("No uppercase letter still uses the generic single-stroke fallback", arguments: allCyrillicUppercase)
    func noSpuriousFallback(letter: Character) throws {
        let spec = try #require(cyrillicLetterSpec[letter])
        guard spec.strokes > 1 else { return }
        let templates = StrokeTemplate.templates(for: letter)
        #expect(templates.count > 1,
                "Letter \(letter) should have \(spec.strokes) strokes but uses the single-stroke fallback")
    }
}
