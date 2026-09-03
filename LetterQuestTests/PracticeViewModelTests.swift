import Testing
import Foundation
import PencilKit
import RxSwift
@testable import LetterQuest

// MARK: - Mocks

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

private final class MockAssessor: HandwritingAssessing {
    var result: AssessmentResult
    init(result: AssessmentResult) { self.result = result }
    func assess(strokes: [PKStroke], for letter: Letter,
                guidelines: ProportionChecker.Guidelines) -> Single<AssessmentResult> {
        .just(result)
    }
}

private final class MockSoundService: SoundServiceProtocol {
    var isSoundEnabled = false
    func playSuccess() {}
    func playEncouragement() {}
    func playSoftError() {}
}

private final class MockHapticsService: HapticsServiceProtocol {
    var isEnabled = false
    func playSuccess() {}
    func playEncouragement() {}
    func playSoftError() {}
}

// MARK: - Helpers

private func makePassingResult() -> AssessmentResult {
    AssessmentResult(
        overallScore:     90,
        strokeOrderScore: 90,
        shapeScore:       90,
        proportionScore:  90,
        smoothnessScore:  90,
        feedback:         [],
        passed:           true
    )
}

// MARK: - Tests

struct PracticeViewModelWordAdvanceTests {

    @Test("continueToNext calls onWordAdvance instead of touching the router when provided")
    func continueToNextInvokesOnWordAdvance() {
        let router = AppRouter()
        var advanceCallCount = 0

        let vm = PracticeViewModel(
            letterId:           Letter.alphabet.first!.id,
            letterRepository:   MockLetterRepository(),
            progressRepository: MockProgressRepository(),
            assessor:           MockAssessor(result: makePassingResult()),
            soundService:       MockSoundService(),
            hapticsService:     MockHapticsService(),
            router:             router,
            onWordAdvance:      { advanceCallCount += 1 }
        )

        vm.continueToNext()

        #expect(advanceCallCount == 1)
        #expect(router.path.isEmpty)
    }

    @Test("continueToNext falls back to router navigation when onWordAdvance is nil")
    func continueToNextUsesRouterWhenNoOnWordAdvance() {
        let router = AppRouter()
        let letters = Letter.alphabet
        let vm = PracticeViewModel(
            letterId:           letters[0].id,
            letterRepository:   MockLetterRepository(letters: letters),
            progressRepository: MockProgressRepository(),
            assessor:           MockAssessor(result: makePassingResult()),
            soundService:       MockSoundService(),
            hapticsService:     MockHapticsService(),
            router:             router
        )

        vm.submit(strokes: [])
        DispatchQueue.main.sync {}
        vm.continueToNext()
        DispatchQueue.main.sync {}

        #expect(router.path.count == 1)
    }
}
