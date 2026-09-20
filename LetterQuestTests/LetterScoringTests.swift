import XCTest
import RxBlocking
import PencilKit
@testable import LetterQuest

// Tests the full scoring pipeline for all supported characters.
// Each character is tested twice:
//   1. Correct: template strokes traced in the writing zone  → result.passed == true
//   2. Wrong:   the next character's strokes in the same zone → result.passed == false

final class LetterScoringTests: XCTestCase {

    private let assessor   = HandwritingAssessor()
    private let canvasSize = CGSize(width: 400, height: 400)
    private var guidelines: ProportionChecker.Guidelines {
        .forCanvas(size: canvasSize)
    }

    // MARK: - Uppercase

    func test_uppercase_correctStrokes_pass() throws {
        for letter in Letter.alphabet {
            let strokes = makeStrokesInZone(matching: letter.strokeTemplates,
                                            for: letter.character, in: canvasSize)
            let result = try assess(strokes: strokes, for: letter)
            XCTAssertTrue(result.passed,
                "'\(letter.character)' correct strokes should pass; score=\(result.overallScore)")
        }
    }

    func test_uppercase_wrongStrokes_fail() throws {
        let letters = Letter.alphabet
        for (i, letter) in letters.enumerated() {
            let foil = letters[(i + 13) % letters.count]
            let strokes = makeStrokesInZone(matching: foil.strokeTemplates,
                                            for: letter.character, in: canvasSize)
            let result = try assess(strokes: strokes, for: letter)
            XCTAssertFalse(result.passed,
                "'\(letter.character)' drawn as '\(foil.character)' should fail; score=\(result.overallScore)")
        }
    }

    // MARK: - Lowercase

    func test_lowercase_correctStrokes_pass() throws {
        for letter in Letter.lowercaseAlphabet {
            let strokes = makeStrokesInZone(matching: letter.strokeTemplates,
                                            for: letter.character, in: canvasSize)
            let result = try assess(strokes: strokes, for: letter)
            XCTAssertTrue(result.passed,
                "'\(letter.character)' correct strokes should pass; score=\(result.overallScore)")
        }
    }

    func test_lowercase_wrongStrokes_fail() throws {
        let letters = Letter.lowercaseAlphabet
        for (i, letter) in letters.enumerated() {
            let foil = letters[(i + 7) % letters.count]
            let strokes = makeStrokesInZone(matching: foil.strokeTemplates,
                                            for: letter.character, in: canvasSize)
            let result = try assess(strokes: strokes, for: letter)
            XCTAssertFalse(result.passed,
                "'\(letter.character)' drawn as '\(foil.character)' should fail; score=\(result.overallScore)")
        }
    }

    // MARK: - Helper

    private func assess(strokes: [PKStroke], for letter: Letter) throws -> AssessmentResult {
        try assessor.assess(strokes: strokes, for: letter, guidelines: guidelines)
            .toBlocking(timeout: 5)
            .single()
    }
}
