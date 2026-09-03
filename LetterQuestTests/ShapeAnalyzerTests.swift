import XCTest
import CoreGraphics
import PencilKit
@testable import LetterQuest

// MARK: - Identity / degenerate inputs

final class ShapeAnalyzerInputTests: XCTestCase {

    private let analyzer   = ShapeAnalyzer()
    private let canvasSize = CGSize(width: 400, height: 400)

    func test_emptyStrokes_returnZero() {
        let letter = Letter.alphabet.first { $0.character == "A" }!
        XCTAssertEqual(analyzer.score(strokes: [], for: letter, canvasSize: canvasSize), 0)
    }

    func test_singlePointStroke_returnsZero() {
        let letter = Letter.alphabet.first { $0.character == "A" }!
        let stroke = makeStroke(points: [CGPoint(x: 200, y: 200)])
        XCTAssertEqual(analyzer.score(strokes: [stroke], for: letter, canvasSize: canvasSize), 0)
    }
}

// MARK: - Score correlates with correct position and shape

final class ShapeAnalyzerOverlapTests: XCTestCase {

    private let analyzer   = ShapeAnalyzer()
    private let canvasSize = CGSize(width: 400, height: 400)

    /// Tracing the template in the correct writing zone should score high.
    func test_tracingTemplateInZone_scoresAtLeast70() {
        let letter  = Letter.alphabet.first { $0.character == "I" }!
        let strokes = makeStrokesInZone(matching: letter.strokeTemplates,
                                        for: letter.character, in: canvasSize)
        let score = analyzer.score(strokes: strokes, for: letter, canvasSize: canvasSize)
        XCTAssertGreaterThanOrEqual(score, 70,
            "Tracing template in zone should score ≥ 70; got \(score)")
    }

    /// Drawing correct strokes but spanning the FULL canvas (not the zone) should score lower
    /// than drawing in the zone, because the ink does not overlap the zone-placed template.
    func test_drawingOutsideZone_scoresLowerThanInsideZone() {
        let letter = Letter.alphabet.first { $0.character == "I" }!

        // Correct position: inside the zone
        let inZone = makeStrokesInZone(matching: letter.strokeTemplates,
                                       for: letter.character, in: canvasSize)
        // Wrong position: full-canvas scale (top-to-bottom of the entire canvas, not just the zone)
        let fullCanvas = makeStrokes(matching: letter.strokeTemplates, in: canvasSize)

        let zoneScore   = analyzer.score(strokes: inZone,      for: letter, canvasSize: canvasSize)
        let canvasScore = analyzer.score(strokes: fullCanvas,   for: letter, canvasSize: canvasSize)

        XCTAssertGreaterThanOrEqual(zoneScore, canvasScore,
            "Zone drawing should score at least as well as full-canvas drawing; got zone=\(zoneScore) canvas=\(canvasScore)")
    }

    /// Drawing in the zone for the WRONG letter should score lower than drawing correctly.
    func test_wrongLetter_scoresLowerThanCorrect() {
        let oLetter = Letter.alphabet.first { $0.character == "O" }!
        let iLetter = Letter.alphabet.first { $0.character == "I" }!

        let iCorrect = makeStrokesInZone(matching: iLetter.strokeTemplates,
                                         for: iLetter.character, in: canvasSize)
        let oInIZone = makeStrokesInZone(matching: oLetter.strokeTemplates,
                                          for: iLetter.character, in: canvasSize)

        let right = analyzer.score(strokes: iCorrect, for: iLetter, canvasSize: canvasSize)
        let wrong = analyzer.score(strokes: oInIZone,  for: iLetter, canvasSize: canvasSize)

        XCTAssertGreaterThan(right, wrong,
            "Correct letter should score higher than wrong shape; got right=\(right) wrong=\(wrong)")
    }

    /// Correct drawings for a sample of letters should all score ≥ 70.
    func test_correctLetter_scoresAtLeast70() {
        for char: Character in ["A", "C", "O", "V"] {
            let letter  = Letter.alphabet.first { $0.character == char }!
            let strokes = makeStrokesInZone(matching: letter.strokeTemplates,
                                            for: letter.character, in: canvasSize)
            let score = analyzer.score(strokes: strokes, for: letter, canvasSize: canvasSize)
            XCTAssertGreaterThanOrEqual(score, 70,
                "\(char): tracing own template in zone should score ≥ 70; got \(score)")
        }
    }

    /// Drawing completely above the guidelines (y < ascenderY = 80) should score low.
    func test_drawingAboveGuidelines_scoresLow() {
        let letter = Letter.alphabet.first { $0.character == "I" }!
        // Draw well above ascenderY (20% = y=80 in a 400-tall canvas)
        let stroke = makeLineStroke(from: CGPoint(x: 200, y: 5), to: CGPoint(x: 200, y: 70))
        let score = analyzer.score(strokes: [stroke], for: letter, canvasSize: canvasSize)
        XCTAssertLessThan(score, 40, "Drawing above guidelines should score < 40; got \(score)")
    }

    /// Drawing completely below the baseline (y > baselineY = 280) should score low.
    func test_drawingBelowBaseline_scoresLow() {
        let letter = Letter.alphabet.first { $0.character == "I" }!
        let stroke = makeLineStroke(from: CGPoint(x: 200, y: 300), to: CGPoint(x: 200, y: 390))
        let score = analyzer.score(strokes: [stroke], for: letter, canvasSize: canvasSize)
        XCTAssertLessThan(score, 40, "Drawing below baseline should score < 40; got \(score)")
    }
}

// MARK: - Output range

final class ShapeAnalyzerRangeTests: XCTestCase {

    private let analyzer   = ShapeAnalyzer()
    private let canvasSize = CGSize(width: 400, height: 400)

    func test_scoreIsWithin0to100_acrossSampleLetters() {
        for character in ["A", "C", "I", "O", "V"] as [Character] {
            let letter  = Letter.alphabet.first { $0.character == character }!
            let strokes = makeStrokesInZone(matching: letter.strokeTemplates,
                                            for: letter.character, in: canvasSize)
            let score = analyzer.score(strokes: strokes, for: letter, canvasSize: canvasSize)
            XCTAssertGreaterThanOrEqual(score, 0,   "\(character) → \(score)")
            XCTAssertLessThanOrEqual(score,    100, "\(character) → \(score)")
        }
    }
}
