import Testing
import Foundation
import PencilKit
import RxSwift
@testable import LetterQuest

// MARK: - Mock

private final class MockHapticsService: HapticsServiceProtocol {
    var isEnabled = true
    private(set) var successCallCount       = 0
    private(set) var encouragementCallCount = 0
    private(set) var softErrorCallCount     = 0
    func playSuccess()       { successCallCount       += 1 }
    func playEncouragement() { encouragementCallCount += 1 }
    func playSoftError()     { softErrorCallCount     += 1 }
}

// MARK: - Helpers

private func makeResult(score: Int, passed: Bool) -> AssessmentResult {
    AssessmentResult(
        overallScore:     score,
        strokeOrderScore: score,
        shapeScore:       score,
        proportionScore:  score,
        smoothnessScore:  score,
        feedback:         [],
        passed:           passed
    )
}

private func makeVM(result: AssessmentResult, haptics: MockHapticsService) -> PracticeViewModel {
    PracticeViewModel(
        letterId:           Letter.alphabet.first!.id,
        letterRepository:   MockLetterRepository(),
        progressRepository: MockProgressRepository(),
        assessor:           MockAssessor(result: result),
        soundService:       MockSoundService(),
        hapticsService:     haptics,
        router:             AppRouter()
    )
}

// MARK: - Tests

struct HapticTriggerTests {

    @Test("playSuccess is called for a passing score")
    func passingScorePlaysSuccess() {
        let haptics = MockHapticsService()
        let vm      = makeVM(result: makeResult(score: 80, passed: true), haptics: haptics)
        vm.submit(strokes: [])
        DispatchQueue.main.sync {}
        #expect(haptics.successCallCount == 1)
        #expect(haptics.encouragementCallCount == 0)
        #expect(haptics.softErrorCallCount == 0)
    }

    @Test("playEncouragement is called for scores 50–74")
    func midRangeScorePlaysEncouragement() {
        let haptics = MockHapticsService()
        let vm      = makeVM(result: makeResult(score: 62, passed: false), haptics: haptics)
        vm.submit(strokes: [])
        DispatchQueue.main.sync {}
        #expect(haptics.successCallCount == 0)
        #expect(haptics.encouragementCallCount == 1)
        #expect(haptics.softErrorCallCount == 0)
    }

    @Test("playSoftError is called for scores below 50")
    func lowScorePlaysSoftError() {
        let haptics = MockHapticsService()
        let vm      = makeVM(result: makeResult(score: 30, passed: false), haptics: haptics)
        vm.submit(strokes: [])
        DispatchQueue.main.sync {}
        #expect(haptics.successCallCount == 0)
        #expect(haptics.encouragementCallCount == 0)
        #expect(haptics.softErrorCallCount == 1)
    }

    @Test("score of exactly 50 plays encouragement, not soft error")
    func boundaryAt50PlaysEncouragement() {
        let haptics = MockHapticsService()
        let vm      = makeVM(result: makeResult(score: 50, passed: false), haptics: haptics)
        vm.submit(strokes: [])
        DispatchQueue.main.sync {}
        #expect(haptics.encouragementCallCount == 1)
        #expect(haptics.softErrorCallCount == 0)
    }

    @Test("no haptic method is called when isEnabled is false")
    func disabledHapticsSkipsAllPatterns() {
        let haptics = MockHapticsService()
        haptics.isEnabled = false
        let vm = makeVM(result: makeResult(score: 80, passed: true), haptics: haptics)
        vm.submit(strokes: [])
        DispatchQueue.main.sync {}
        #expect(haptics.successCallCount == 0)
        #expect(haptics.encouragementCallCount == 0)
        #expect(haptics.softErrorCallCount == 0)
    }
}

// MARK: - Shared test mocks (mirror of SoundServiceTests)

private final class MockSoundService: SoundServiceProtocol {
    var isSoundEnabled = true
    func playSuccess() {}
    func playEncouragement() {}
    func playSoftError() {}
}

private final class MockLetterRepository: LetterRepositoryProtocol {
    func fetchAll() -> Single<[Letter]> { .just(Letter.alphabet) }
    func fetch(by id: UUID) -> Single<Letter?> { .just(Letter.alphabet.first { $0.id == id }) }
    func fetchNext(after id: UUID) -> Single<Letter?> {
        let letters = Letter.alphabet
        guard let idx = letters.firstIndex(where: { $0.id == id }),
              idx + 1 < letters.count else { return .just(nil) }
        return .just(letters[idx + 1])
    }
}

private final class MockProgressRepository: ProgressRepositoryProtocol {
    func loadAll() -> Single<[ChildProgress]> { .just([]) }
    func save(_ progress: ChildProgress) -> Completable { .empty() }
}

private final class MockAssessor: HandwritingAssessing {
    let result: AssessmentResult
    init(result: AssessmentResult) { self.result = result }
    func assess(strokes: [PKStroke], for letter: Letter,
                guidelines: ProportionChecker.Guidelines) -> Single<AssessmentResult> {
        .just(result)
    }
}
