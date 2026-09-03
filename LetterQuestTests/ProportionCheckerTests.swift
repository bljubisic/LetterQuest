import XCTest
import CoreGraphics
import PencilKit
@testable import LetterQuest

// MARK: - Empty / degenerate inputs

final class ProportionCheckerInputTests: XCTestCase {

    private let checker = ProportionChecker()
    private let canvasSize = CGSize(width: 400, height: 400)

    func test_emptyStrokes_returnZero() {
        let letter = Letter.alphabet.first { $0.character == "A" }!
        let guides = ProportionChecker.Guidelines.forCanvas(size: canvasSize)
        XCTAssertEqual(checker.score(strokes: [], letter: letter, guidelines: guides), 0)
    }
}

// MARK: - Guide-line geometry

final class ProportionCheckerGuidelinesTests: XCTestCase {

    func test_guidelinePositions_matchDocumentedRatios() {
        let g = ProportionChecker.Guidelines.forCanvas(size: CGSize(width: 100, height: 400))
        XCTAssertEqual(g.ascenderY,  400 * 0.20)
        XCTAssertEqual(g.xHeightY,   400 * 0.45)
        XCTAssertEqual(g.baselineY,  400 * 0.70)
        XCTAssertEqual(g.descenderY, 400 * 0.85)
    }
}

// MARK: - Cap-height behaviour (uppercase letters)

final class ProportionCheckerUppercaseTests: XCTestCase {

    private let checker = ProportionChecker()
    private let canvasSize = CGSize(width: 400, height: 400)
    private var guidelines: ProportionChecker.Guidelines {
        .forCanvas(size: canvasSize)
    }

    func test_correctCapHeight_scoresAtLeast80() {
        let letter = Letter.alphabet.first { $0.character == "I" }!
        // Cap-height band is 20%–70% = 80–280 in a 400-tall canvas.
        let strokes = [
            makeLineStroke(from: CGPoint(x: 200, y: 80),
                           to:   CGPoint(x: 200, y: 280))
        ]
        let score = checker.score(strokes: strokes, letter: letter, guidelines: guidelines)
        XCTAssertGreaterThanOrEqual(score, 80,
                                    "Correctly proportioned uppercase should score ≥ 80; got \(score)")
    }

    func test_letterBelowBaseline_isPenalised() {
        let letter = Letter.alphabet.first { $0.character == "I" }!
        // Drawn entirely below the baseline (y = 280), into descender + outside.
        let belowBaselineStrokes = [
            makeLineStroke(from: CGPoint(x: 200, y: 330),
                           to:   CGPoint(x: 200, y: 390))
        ]
        let correctStrokes = [
            makeLineStroke(from: CGPoint(x: 200, y: 80),
                           to:   CGPoint(x: 200, y: 280))
        ]
        let correct = checker.score(strokes: correctStrokes, letter: letter, guidelines: guidelines)
        let belowBaseline = checker.score(strokes: belowBaselineStrokes,
                                          letter: letter, guidelines: guidelines)
        XCTAssertLessThan(belowBaseline, correct,
                          "Below-baseline should score lower than correct; got \(belowBaseline) vs \(correct)")
    }

    func test_letterTooShort_isPenalisedVsFullCapHeight() {
        let letter = Letter.alphabet.first { $0.character == "I" }!
        let correct = checker.score(
            strokes: [makeLineStroke(from: CGPoint(x: 200, y: 80),  to: CGPoint(x: 200, y: 280))],
            letter: letter,
            guidelines: guidelines
        )
        let tooShort = checker.score(
            strokes: [makeLineStroke(from: CGPoint(x: 200, y: 200), to: CGPoint(x: 200, y: 280))],
            letter: letter,
            guidelines: guidelines
        )
        XCTAssertLessThan(tooShort, correct,
                          "Too short should score lower; got \(tooShort) vs \(correct)")
    }
}

// MARK: - Width penalty

final class ProportionCheckerWidthTests: XCTestCase {

    private let checker = ProportionChecker()
    private let canvasSize = CGSize(width: 400, height: 400)
    private var guidelines: ProportionChecker.Guidelines {
        .forCanvas(size: canvasSize)
    }

    func test_excessiveWidth_isPenalised() {
        let letter = Letter.alphabet.first { $0.character == "A" }!
        // Width = 380 / 400 = 95% > 90% → width sub-score 20.
        let wideStrokes = [
            makeLineStroke(from: CGPoint(x: 10,  y: 80),
                           to:   CGPoint(x: 390, y: 280))
        ]
        let normalStrokes = [
            makeLineStroke(from: CGPoint(x: 150, y: 80),
                           to:   CGPoint(x: 250, y: 280))
        ]
        let wide   = checker.score(strokes: wideStrokes,   letter: letter, guidelines: guidelines)
        let normal = checker.score(strokes: normalStrokes, letter: letter, guidelines: guidelines)
        XCTAssertLessThan(wide, normal,
                          "Excessive width should score lower; got \(wide) vs \(normal)")
    }

    func test_tinyWidth_isPenalised() {
        let letter = Letter.alphabet.first { $0.character == "A" }!
        // 1 px width → ratio < 5% → width sub-score = 20.
        let tinyStrokes = [
            makeLineStroke(from: CGPoint(x: 200, y: 80),
                           to:   CGPoint(x: 201, y: 280))
        ]
        let tiny = checker.score(strokes: tinyStrokes, letter: letter, guidelines: guidelines)
        XCTAssertLessThan(tiny, 90, "Tiny-width letter should not score near perfect; got \(tiny)")
    }
}

// MARK: - Output range

final class ProportionCheckerRangeTests: XCTestCase {

    private let checker = ProportionChecker()
    private let canvasSize = CGSize(width: 400, height: 400)

    func test_scoreIsWithin0to100() {
        let letter = Letter.alphabet.first { $0.character == "A" }!
        let guides = ProportionChecker.Guidelines.forCanvas(size: canvasSize)
        let strokes = [
            makeLineStroke(from: CGPoint(x: 100, y: 100),
                           to:   CGPoint(x: 300, y: 300))
        ]
        let score = checker.score(strokes: strokes, letter: letter, guidelines: guides)
        XCTAssertGreaterThanOrEqual(score, 0)
        XCTAssertLessThanOrEqual(score,    100)
    }
}

// MARK: - Lowercase letter proportions

final class ProportionCheckerLowercaseTests: XCTestCase {

    private let checker = ProportionChecker()
    // 400-tall canvas: ascenderY=80, xHeightY=180, baselineY=280, descenderY=340.
    private let canvasSize = CGSize(width: 400, height: 400)
    private var guidelines: ProportionChecker.Guidelines {
        .forCanvas(size: canvasSize)
    }
    private var letterN: Letter { Letter.lowercaseAlphabet.first { $0.character == "n" }! }

    func test_correctLowercaseHeight_scoresAtLeast80() {
        // Stroke from ascenderY (80) to baselineY (280) — correct cap height.
        let strokes = [
            makeLineStroke(from: CGPoint(x: 100, y: 80),
                           to:   CGPoint(x: 300, y: 280))
        ]
        let score = checker.score(strokes: strokes, letter: letterN, guidelines: guidelines)
        XCTAssertGreaterThanOrEqual(score, 80,
            "Correctly proportioned lowercase should score ≥ 80; got \(score)")
    }

    func test_lowercaseBottomAtBaseline_outperformsDescender() {
        // Ending at baselineY (280) should score better than well below it (380).
        let atBaseline  = [makeLineStroke(from: CGPoint(x: 100, y: 80), to: CGPoint(x: 300, y: 280))]
        let atDescender = [makeLineStroke(from: CGPoint(x: 100, y: 80), to: CGPoint(x: 300, y: 380))]
        let baseScore = checker.score(strokes: atBaseline,  letter: letterN, guidelines: guidelines)
        let descScore = checker.score(strokes: atDescender, letter: letterN, guidelines: guidelines)
        XCTAssertGreaterThan(baseScore, descScore,
            "Lowercase ending at baselineY should score higher; got \(baseScore) vs \(descScore)")
    }

    func test_lowercaseScore_alwaysWithin0to100() {
        let strokes = [makeLineStroke(from: CGPoint(x: 50, y: 80), to: CGPoint(x: 350, y: 340))]
        let score = checker.score(strokes: strokes, letter: letterN, guidelines: guidelines)
        XCTAssertGreaterThanOrEqual(score, 0)
        XCTAssertLessThanOrEqual(score, 100)
    }
}
