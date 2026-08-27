import XCTest
import CoreGraphics
import PencilKit
@testable import LetterQuest

// MARK: - Identity / degenerate inputs

final class ShapeAnalyzerInputTests: XCTestCase {

    private let analyzer = ShapeAnalyzer()

    func test_emptyStrokes_returnZero() {
        let letter = Letter.alphabet.first { $0.character == "A" }!
        XCTAssertEqual(analyzer.score(strokes: [], for: letter), 0)
    }

    func test_singlePointStroke_returnsZero() {
        // Degenerate bounds (a single point) cannot be rasterised; score is 0.
        let letter = Letter.alphabet.first { $0.character == "A" }!
        let stroke = makeStroke(points: [CGPoint(x: 50, y: 50)])
        XCTAssertEqual(analyzer.score(strokes: [stroke], for: letter), 0)
    }
}

// MARK: - Score correlates with overlap

final class ShapeAnalyzerOverlapTests: XCTestCase {

    private let analyzer = ShapeAnalyzer()
    private let canvasSize = CGSize(width: 400, height: 400)

    func test_tracingTemplate_scoresAtLeast80() {
        let letter = Letter.alphabet.first { $0.character == "I" }!
        let strokes = makeStrokes(matching: letter.strokeTemplates, in: canvasSize)
        let score = analyzer.score(strokes: strokes, for: letter)
        XCTAssertGreaterThanOrEqual(score, 80, "Tracing template should score high; got \(score)")
    }

    func test_perpendicularStrokeAgainstVerticalTemplate_scoresLow() {
        // "I" template is vertical at x = 0.5. A horizontal stroke across the
        // middle has very little ink overlap once both are bounds-fit.
        // With perfectIoU=0.60 this wrong shape should score well below 50.
        let letter = Letter.alphabet.first { $0.character == "I" }!
        let strokes = [makeLineStroke(from: CGPoint(x: 50, y: 200),
                                      to:   CGPoint(x: 350, y: 200))]
        let score = analyzer.score(strokes: strokes, for: letter)
        XCTAssertLessThan(score, 50, "Perpendicular stroke should score low; got \(score)")
    }

    func test_letterI_avoidsDegenerateZero() {
        // Regression guard: the original `bounds.isEmpty` check returned `nil`
        // for any zero-width or zero-height polyline, which made "I" always
        // return 0. The fix uses `bounds.isNull` plus an axis-wise scale.
        let letter = Letter.alphabet.first { $0.character == "I" }!
        let strokes = makeStrokes(matching: letter.strokeTemplates, in: canvasSize)
        XCTAssertGreaterThan(analyzer.score(strokes: strokes, for: letter), 0)
    }

    func test_wrongLetter_scoresLowerThanCorrect() {
        let oTemplates = Letter.alphabet.first { $0.character == "O" }!.strokeTemplates
        let iLetter    = Letter.alphabet.first { $0.character == "I" }!
        let oTraced   = makeStrokes(matching: oTemplates, in: canvasSize)
        let iTraced   = makeStrokes(matching: iLetter.strokeTemplates, in: canvasSize)
        let wrong = analyzer.score(strokes: oTraced, for: iLetter)
        let right = analyzer.score(strokes: iTraced, for: iLetter)
        XCTAssertGreaterThan(right, wrong,
                             "Tracing should beat mis-match: right=\(right) wrong=\(wrong)")
    }

    func test_wrongLetter_scoresBelowPassThreshold() {
        // Drawing 'O' when asked for 'I' should score < 60 with perfectIoU=0.60.
        let oTemplates = Letter.alphabet.first { $0.character == "O" }!.strokeTemplates
        let iLetter    = Letter.alphabet.first { $0.character == "I" }!
        let oTraced    = makeStrokes(matching: oTemplates, in: canvasSize)
        let score = analyzer.score(strokes: oTraced, for: iLetter)
        XCTAssertLessThan(score, 60, "Wrong letter should score < 60; got \(score)")
    }

    func test_correctLetter_scoresAtLeast80() {
        // Tracing any letter's own template should score ≥ 80 with perfectIoU=0.60.
        for char: Character in ["A", "C", "O", "V"] {
            let letter  = Letter.alphabet.first { $0.character == char }!
            let strokes = makeStrokes(matching: letter.strokeTemplates, in: canvasSize)
            let score   = analyzer.score(strokes: strokes, for: letter)
            XCTAssertGreaterThanOrEqual(score, 80,
                "\(char): tracing own template should score ≥ 80; got \(score)")
        }
    }
}

// MARK: - Output range

final class ShapeAnalyzerRangeTests: XCTestCase {

    private let analyzer = ShapeAnalyzer()
    private let canvasSize = CGSize(width: 400, height: 400)

    func test_scoreIsWithin0to100_acrossSampleLetters() {
        for character in ["A", "C", "I", "O", "V"] as [Character] {
            let letter = Letter.alphabet.first { $0.character == character }!
            let strokes = makeStrokes(matching: letter.strokeTemplates, in: canvasSize)
            let score = analyzer.score(strokes: strokes, for: letter)
            XCTAssertGreaterThanOrEqual(score, 0,   "\(character) → \(score)")
            XCTAssertLessThanOrEqual(score,    100, "\(character) → \(score)")
        }
    }
}
