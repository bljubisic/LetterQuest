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
