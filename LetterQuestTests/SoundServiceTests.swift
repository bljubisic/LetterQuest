import Testing
import Foundation
import PencilKit
import RxSwift
@testable import LetterQuest

// MARK: - Mocks

private final class MockSoundService: SoundServiceProtocol {
    var isSoundEnabled = true
    private(set) var successCallCount       = 0
    private(set) var encouragementCallCount = 0
    private(set) var softErrorCallCount     = 0
    func playSuccess()       { successCallCount       += 1 }
    func playEncouragement() { encouragementCallCount += 1 }
    func playSoftError()     { softErrorCallCount     += 1 }
}

private final class MockAssessor: HandwritingAssessing {
    var result: AssessmentResult
    init(result: AssessmentResult) { self.result = result }
    func assess(strokes: [PKStroke], for letter: Letter,
                guidelines: ProportionChecker.Guidelines) -> Single<AssessmentResult> {
        .just(result)
    }
}

private final class MockLetterRepository: LetterRepositoryProtocol {
    let letters: [Letter]
    init(letters: [Letter] = Letter.alphabet) { self.letters = letters }
    func fetchAll() -> Single<[Letter]> { .just(letters) }
    func fetch(by id: UUID) -> Single<Letter?> { .just(letters.first { $0.id == id }) }
    func fetchNext(after id: UUID) -> Single<Letter?> {
        guard let idx = letters.firstIndex(where: { $0.id == id }),
              idx + 1 < letters.count else { return .just(nil) }
        return .just(letters[idx + 1])
    }
}

private final class MockProgressRepository: ProgressRepositoryProtocol {
    func loadAll() -> Single<[ChildProgress]> { .just([]) }
    func save(_ progress: ChildProgress) -> Completable { .empty() }
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

/// Builds a `PracticeViewModel` whose assessor always returns `result`.
private func makeVM(result: AssessmentResult, sound: MockSoundService) -> PracticeViewModel {
    PracticeViewModel(
        letterId:           Letter.alphabet.first!.id,
        letterRepository:   MockLetterRepository(),
        progressRepository: MockProgressRepository(),
        assessor:           MockAssessor(result: result),
        soundService:       sound,
        router:             AppRouter()
    )
}

// MARK: - Tests

struct SoundTriggerTests {

    @Test("playSuccess is called for a passing score")
    func passingScorePlaysSuccess() {
        let sound = MockSoundService()
        let vm    = makeVM(result: makeResult(score: 80, passed: true), sound: sound)
        vm.submit(strokes: [])
        DispatchQueue.main.sync {}
        #expect(sound.successCallCount == 1)
        #expect(sound.encouragementCallCount == 0)
        #expect(sound.softErrorCallCount == 0)
    }

    @Test("playEncouragement is called for scores 50–74")
    func midRangeScorePlaysEncouragement() {
        let sound = MockSoundService()
        let vm    = makeVM(result: makeResult(score: 62, passed: false), sound: sound)
        vm.submit(strokes: [])
        DispatchQueue.main.sync {}
        #expect(sound.successCallCount == 0)
        #expect(sound.encouragementCallCount == 1)
        #expect(sound.softErrorCallCount == 0)
    }

    @Test("playSoftError is called for scores below 50")
    func lowScorePlaysSoftError() {
        let sound = MockSoundService()
        let vm    = makeVM(result: makeResult(score: 30, passed: false), sound: sound)
        vm.submit(strokes: [])
        DispatchQueue.main.sync {}
        #expect(sound.successCallCount == 0)
        #expect(sound.encouragementCallCount == 0)
        #expect(sound.softErrorCallCount == 1)
    }

    @Test("score of exactly 50 plays encouragement, not soft error")
    func boundaryAt50PlaysEncouragement() {
        let sound = MockSoundService()
        let vm    = makeVM(result: makeResult(score: 50, passed: false), sound: sound)
        vm.submit(strokes: [])
        DispatchQueue.main.sync {}
        #expect(sound.encouragementCallCount == 1)
        #expect(sound.softErrorCallCount == 0)
    }

    @Test("no sound method is called when isSoundEnabled is false")
    func disabledSoundSkipsAllCues() {
        let sound = MockSoundService()
        sound.isSoundEnabled = false
        let vm = makeVM(result: makeResult(score: 80, passed: true), sound: sound)
        vm.submit(strokes: [])
        DispatchQueue.main.sync {}
        #expect(sound.successCallCount == 0)
        #expect(sound.encouragementCallCount == 0)
        #expect(sound.softErrorCallCount == 0)
    }
}
