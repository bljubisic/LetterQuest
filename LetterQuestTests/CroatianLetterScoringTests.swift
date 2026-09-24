import XCTest
import RxSwift
import RxBlocking
import PencilKit
@testable import LetterQuest

// Runs the full scoring pipeline over the Croatian alphabet, mirroring
// `LetterScoringTests`. Beyond "every letter passes when traced correctly",
// it guards the pairs that differ only by a small mark: Č and Ć have the
// same stroke count, so the recognition gate is active between them.
final class CroatianLetterScoringTests: XCTestCase {

    /// Recognition candidates come from *installed* alphabets, so the
    /// catalogue is limited to Croatian — otherwise the paid pack isn't
    /// installed and the gate this suite guards never runs.
    private let assessor = HandwritingAssessor(
        letterRepository: LetterRepository(
            alphabetRepository: AlphabetRepository(catalogue: [.croatian],
                                                   entitlementProvider: CroatianEntitlement())
        )
    )
    private let canvasSize = CGSize(width: 400, height: 400)
    private var guidelines: ProportionChecker.Guidelines {
        .forCanvas(size: canvasSize)
    }

    func test_everyLetter_correctStrokes_pass() throws {
        for letter in Alphabet.croatian.letters {
            let result = try assess(drawing: letter, for: letter)
            XCTAssertTrue(result.passed,
                "'\(letter.character)' correct strokes should pass; score=\(result.overallScore)")
        }
    }

    func test_caronAndAcute_areNotInterchangeable() throws {
        for (target, drawn) in [("Č", "Ć"), ("Ć", "Č"), ("č", "ć"), ("ć", "č")] as [(Character, Character)] {
            let result = try assess(drawing: letter(drawn), for: letter(target))
            XCTAssertFalse(result.passed,
                "'\(target)' drawn as '\(drawn)' should fail; score=\(result.overallScore)")
        }
    }

    /// Regression: a correctly drawn Ć used to be rejected as "That looks like
    /// Č" — shape scoring can't tell the two small marks apart, every diagonal
    /// got the same flat direction score as a curve, and near-ties went to
    /// whichever candidate came first (Č). Children draw the tick either way
    /// round and not exactly on the guide, so cover both.
    func test_acuteDrawnNaturally_isNotMistakenForCaron() throws {
        let ticks: [(name: String, from: CGPoint, to: CGPoint)] = [
            ("down-left, like handwriting", StrokeTemplate.p(0.56, -0.02), StrokeTemplate.p(0.44, 0.08)),
            ("steeper, down-left", StrokeTemplate.p(0.58, -0.04), StrokeTemplate.p(0.48, 0.12)),
            ("longer, up-right", StrokeTemplate.p(0.40, 0.12), StrokeTemplate.p(0.60, -0.06)),
        ]
        for character: Character in ["Ć", "ć"] {
            let target = letter(character)
            let zone = testWritingZone(canvasSize: canvasSize, character: character)
            func onCanvas(_ point: CGPoint) -> CGPoint {
                CGPoint(x: zone.minX + point.x * zone.width, y: zone.minY + point.y * zone.height)
            }
            let body = makeStroke(points: target.strokeTemplates[0].points.map(onCanvas))
            for tick in ticks {
                // Lowercase marks sit 0.02 higher than uppercase ones.
                let shift: CGFloat = character == "ć" ? -0.02 : 0
                let from = CGPoint(x: tick.from.x, y: tick.from.y + shift)
                let to = CGPoint(x: tick.to.x, y: tick.to.y + shift)
                let mark = makeStroke(points: StrokeTemplate.line(from: from, to: to, steps: 8).map(onCanvas))
                let result = try assessor.assess(strokes: [body, mark], for: target, guidelines: guidelines)
                    .toBlocking(timeout: 5)
                    .single()
                XCTAssertTrue(result.passed,
                    "'\(character)' with tick \(tick.name) should pass; score=\(result.overallScore), feedback=\(result.feedback.map(\.message))")
            }
        }
    }

    /// Regression: the acute traced exactly backwards along its guide (top-right
    /// → bottom-left) lost to Č, because path matching follows drawing order
    /// and Č's V is symmetric. Recognition must not care which end a stroke
    /// starts from.
    func test_acuteTracedBackwards_isNotMistakenForCaron() throws {
        for character: Character in ["Ć", "ć"] {
            let target = letter(character)
            let strokes = makeStrokesInZone(matching: target.strokeTemplates, for: character, in: canvasSize)
            let backwardsMark = makeStrokesInZone(
                matching: [StrokeTemplate.lensPoints.over(target.strokeTemplates[1]) { $0.reversed() }],
                for: character, in: canvasSize)
            let result = try assessor.assess(strokes: [strokes[0]] + backwardsMark, for: target, guidelines: guidelines)
                .toBlocking(timeout: 5)
                .single()
            XCTAssertFalse(result.feedback.contains { $0.message.contains("looks like") },
                "'\(character)' with its tick traced backwards was misrecognised: \(result.feedback.map(\.message))")
            XCTAssertTrue(result.passed, "'\(character)' with its tick traced backwards should pass; score=\(result.overallScore)")
        }
    }

    func test_baseLetterWithoutMark_fails() throws {
        let pairs: [(Character, Character)] = [
            ("Č", "C"), ("Ć", "C"), ("Š", "S"), ("Ž", "Z"), ("Đ", "D"),
            ("č", "c"), ("ć", "c"), ("š", "s"), ("ž", "z"), ("đ", "d"),
        ]
        for (target, drawn) in pairs {
            let result = try assess(drawing: letter(drawn), for: letter(target))
            XCTAssertFalse(result.passed,
                "'\(target)' drawn as '\(drawn)' should fail; score=\(result.overallScore)")
        }
    }

    // MARK: - Helpers

    private struct CroatianEntitlement: AlphabetEntitlementProviding {
        func isEntitled(to productId: String) -> Bool { true }
        func refresh() -> Completable { .empty() }
    }

    private func letter(_ character: Character) -> Letter {
        Alphabet.croatian.letters.first { $0.character == character }!
    }

    /// Traces `drawn`'s template strokes in `target`'s writing zone.
    private func assess(drawing drawn: Letter, for target: Letter) throws -> AssessmentResult {
        let strokes = makeStrokesInZone(matching: drawn.strokeTemplates,
                                        for: target.character, in: canvasSize)
        return try assessor.assess(strokes: strokes, for: target, guidelines: guidelines)
            .toBlocking(timeout: 5)
            .single()
    }
}
