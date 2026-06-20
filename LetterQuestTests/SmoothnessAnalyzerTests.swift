import XCTest
import CoreGraphics
import PencilKit
@testable import LetterQuest

// MARK: - Empty / degenerate inputs

final class SmoothnessAnalyzerInputTests: XCTestCase {

    private let analyzer = SmoothnessAnalyzer()

    func test_emptyStrokes_returnZero() {
        XCTAssertEqual(analyzer.score(strokes: []), 0)
    }

    func test_twoPointStroke_isTreatedAsPerfectlySmooth() {
        // With < 3 sample points the analyzer can't compute turning angles
        // and falls back to a neutral 100 for the jitter component. Speed
        // consistency is also 100 because there's effectively one sample.
        let stroke = makeStroke(points: [CGPoint(x: 0, y: 0), CGPoint(x: 50, y: 0)])
        XCTAssertGreaterThanOrEqual(analyzer.score(strokes: [stroke]), 95)
    }
}

// MARK: - Behavioural extremes

final class SmoothnessAnalyzerBehaviourTests: XCTestCase {

    private let analyzer = SmoothnessAnalyzer()

    func test_straightLineAtConstantSpeed_scoresAtLeast90() {
        // 40 evenly-spaced points along a horizontal line. Constant direction
        // → near-zero turning-angle SD. Constant speed → CV ≈ 0.
        let points = (0..<40).map { i in CGPoint(x: Double(i) * 10, y: 100) }
        let stroke = makeStroke(points: points)
        let score = analyzer.score(strokes: [stroke])
        XCTAssertGreaterThanOrEqual(score, 90, "Straight line should score ≥ 90; got \(score)")
    }

    func test_shakyStroke_scoresAtMost60() {
        // Deliberately mix sharp and gentle turns so the turning-angle
        // standard deviation is large. The y-offset cycle (0, 25, -15, 30, -8)
        // produces alternating big/small reversals.
        let dyCycle: [Double] = [0, 25, -15, 30, -8]
        let points = (0..<40).map { i -> CGPoint in
            CGPoint(x: Double(i) * 10, y: 100 + dyCycle[i % dyCycle.count])
        }
        let stroke = makeStroke(points: points)
        let score = analyzer.score(strokes: [stroke])
        XCTAssertLessThanOrEqual(score, 60, "Shaky stroke should score ≤ 60; got \(score)")
    }
}

// MARK: - Multi-stroke averaging

final class SmoothnessAnalyzerCompositionTests: XCTestCase {

    private let analyzer = SmoothnessAnalyzer()

    func test_compositeScore_isMeanOfPerStrokeScores() {
        let smooth = makeStroke(points: (0..<30).map { CGPoint(x: Double($0) * 10, y: 100) })
        let shaky = makeStroke(points: (0..<30).map { i -> CGPoint in
            CGPoint(x: Double(i) * 10, y: 100 + ([0, 25, -15, 30, -8])[i % 5])
        })
        let smoothScore = analyzer.score(strokes: [smooth])
        let shakyScore  = analyzer.score(strokes: [shaky])
        let combined    = analyzer.score(strokes: [smooth, shaky])
        let expected    = (smoothScore + shakyScore) / 2
        // Allow ±1 for integer truncation between Double mean and Int cast.
        XCTAssertLessThanOrEqual(abs(combined - expected), 1,
                                 "combined=\(combined) expected≈\(expected) (smooth=\(smoothScore), shaky=\(shakyScore))")
    }
}

// MARK: - Output range

final class SmoothnessAnalyzerRangeTests: XCTestCase {

    private let analyzer = SmoothnessAnalyzer()

    func test_scoreIsWithin0to100() {
        let stroke = makeStroke(points: (0..<20).map { CGPoint(x: Double($0) * 7, y: 100) })
        let score = analyzer.score(strokes: [stroke])
        XCTAssertGreaterThanOrEqual(score, 0)
        XCTAssertLessThanOrEqual(score,    100)
    }
}
