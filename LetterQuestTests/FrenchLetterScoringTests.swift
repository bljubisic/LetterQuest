import XCTest
import RxSwift
import RxBlocking
import PencilKit
@testable import LetterQuest

// Runs the full scoring pipeline over the French alphabet, mirroring
// `CroatianLetterScoringTests`. Beyond "every letter passes when traced
// correctly", it guards the letters that differ only by a small mark and have
// the same stroke count — É/È/Ê, À/Â, Ù/Û and î/i — since the recognition
// gate is active between them (the Č/Ć bug from #56 in French form).
final class FrenchLetterScoringTests: XCTestCase {

    /// Recognition candidates come from *installed* alphabets, so the
    /// catalogue is limited to French — otherwise the paid pack isn't
    /// installed and the gate this suite guards never runs.
    private let assessor = HandwritingAssessor(
        letterRepository: LetterRepository(
            alphabetRepository: AlphabetRepository(catalogue: [.french],
                                                   entitlementProvider: FrenchEntitlement())
        )
    )
    private let canvasSize = CGSize(width: 400, height: 400)
    private var guidelines: ProportionChecker.Guidelines {
        .forCanvas(size: canvasSize)
    }

    func test_everyLetter_correctStrokes_pass() throws {
        for letter in Alphabet.french.letters {
            let result = try assess(drawing: letter, for: letter)
            XCTAssertTrue(result.passed,
                "'\(letter.character)' correct strokes should pass; score=\(result.overallScore)")
        }
    }

    func test_lettersDifferingOnlyByMark_areNotInterchangeable() throws {
        let groups: [String] = ["ÉÈÊ", "éèê", "ÀÂ", "àâ", "ÙÛ", "ùû", "îi"]
        for group in groups {
            for target in group {
                for drawn in group where drawn != target {
                    let result = try assess(drawing: letter(drawn), for: letter(target))
                    XCTAssertFalse(result.passed,
                        "'\(target)' drawn as '\(drawn)' should fail; score=\(result.overallScore)")
                }
            }
        }
    }

    /// Children draw the grave tick either way round and not exactly on the
    /// guide — none of those variations may be mistaken for an acute or a
    /// circumflex.
    func test_graveDrawnNaturally_isRecognised() throws {
        let variations: [(name: String, from: CGVector, to: CGVector)] = [
            ("backwards, bottom-right to top-left", CGVector(dx: 0.06, dy: 0.05), CGVector(dx: -0.06, dy: -0.05)),
            ("steeper", CGVector(dx: -0.04, dy: -0.07), CGVector(dx: 0.04, dy: 0.07)),
            ("longer", CGVector(dx: -0.09, dy: -0.07), CGVector(dx: 0.09, dy: 0.07)),
            ("off the guide", CGVector(dx: -0.03, dy: -0.03), CGVector(dx: 0.09, dy: 0.07)),
        ]
        for character: Character in ["È", "è", "À", "à", "Ù", "ù"] {
            let target = letter(character)
            let guide = try XCTUnwrap(target.strokeTemplates.last?.points)
            let center = CGPoint(x: (guide[0].x + guide[guide.count - 1].x) / 2,
                                 y: (guide[0].y + guide[guide.count - 1].y) / 2)
            let zone = testWritingZone(canvasSize: canvasSize, character: character)
            func onCanvas(_ point: CGPoint) -> CGPoint {
                CGPoint(x: zone.minX + point.x * zone.width, y: zone.minY + point.y * zone.height)
            }
            let body = target.strokeTemplates.dropLast().map { makeStroke(points: $0.points.map(onCanvas)) }
            for variation in variations {
                let from = CGPoint(x: center.x + variation.from.dx, y: center.y + variation.from.dy)
                let to = CGPoint(x: center.x + variation.to.dx, y: center.y + variation.to.dy)
                let mark = makeStroke(points: StrokeTemplate.line(from: from, to: to, steps: 8).map(onCanvas))
                let result = try assessor.assess(strokes: body + [mark], for: target, guidelines: guidelines)
                    .toBlocking(timeout: 5)
                    .single()
                XCTAssertFalse(result.feedback.contains { $0.message.contains("looks like") },
                    "'\(character)' with grave \(variation.name) was misrecognised: \(result.feedback.map(\.message))")
                XCTAssertTrue(result.passed,
                    "'\(character)' with grave \(variation.name) should pass; score=\(result.overallScore)")
            }
        }
    }

    func test_baseLetterWithoutMark_fails() throws {
        let pairs: [(Character, Character)] = [
            ("À", "A"), ("È", "E"), ("Ê", "E"), ("Ç", "C"), ("Ô", "O"), ("Ù", "U"),
            ("à", "a"), ("è", "e"), ("ê", "e"), ("ç", "c"), ("ô", "o"), ("ù", "u"),
        ]
        for (target, drawn) in pairs {
            let result = try assess(drawing: letter(drawn), for: letter(target))
            XCTAssertFalse(result.passed,
                "'\(target)' drawn as '\(drawn)' should fail; score=\(result.overallScore)")
        }
    }

    // MARK: - Helpers

    private struct FrenchEntitlement: AlphabetEntitlementProviding {
        func isEntitled(to productId: String) -> Bool { true }
        func refresh() -> Completable { .empty() }
    }

    private func letter(_ character: Character) -> Letter {
        Alphabet.french.letters.first { $0.character == character }!
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
