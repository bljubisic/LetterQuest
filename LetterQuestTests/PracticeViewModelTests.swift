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
    func resetAll() -> Completable { .empty() }
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

/// Deliberately defers `loadAll()`/`save()` to subscription time via
/// `.deferred`, matching the real `ProgressRepository`'s `Single.create`
/// semantics (a `UserDefaults` read only happens when subscribed to). An
/// eager `.just(...)` mock would snapshot progress too early — before an
/// `.andThen`-sequenced save ahead of it in the chain has actually run.
private final class RecordingProgressRepository: ProgressRepositoryProtocol {
    private var records: [UUID: ChildProgress]
    private(set) var savedUnlockedIds: [UUID] = []

    init(seed: [ChildProgress] = []) {
        records = Dictionary(uniqueKeysWithValues: seed.map { ($0.letterId, $0) })
    }

    func loadAll() -> Single<[ChildProgress]> {
        .deferred { [weak self] in .just(self.map { Array($0.records.values) } ?? []) }
    }

    func save(_ progress: ChildProgress) -> Completable {
        .deferred { [weak self] in
            self?.records[progress.letterId] = progress
            if progress.isUnlocked { self?.savedUnlockedIds.append(progress.letterId) }
            return .empty()
        }
    }

    func resetAll() -> Completable { .empty() }
}

// MARK: - Helpers

private func makeLetter(_ character: Character, case letterCase: LetterCase, alphabetId: String) -> Letter {
    Letter(
        id: UUID(),
        character: character,
        strokeTemplates: [],
        difficulty: .easy,
        templateImageName: nil,
        letterCase: letterCase,
        alphabetId: alphabetId
    )
}

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

struct PracticeViewModelLowercaseUnlockTests {

    @Test("completing an alphabet's uppercase only unlocks that alphabet's lowercase, not another installed alphabet's")
    func lowercaseUnlockIsScopedToItsOwnAlphabet() {
        let alphaU1 = makeLetter("U", case: .upper, alphabetId: "alpha")
        let alphaU2 = makeLetter("V", case: .upper, alphabetId: "alpha")
        let alphaL1 = makeLetter("u", case: .lower, alphabetId: "alpha")
        let alphaL2 = makeLetter("v", case: .lower, alphabetId: "alpha")
        let betaU1  = makeLetter("U", case: .upper, alphabetId: "beta")
        let betaL1  = makeLetter("u", case: .lower, alphabetId: "beta")
        let letters = [alphaU1, alphaU2, alphaL1, alphaL2, betaU1, betaL1]

        let progressRepository = RecordingProgressRepository(seed: [
            ChildProgress(letterId: alphaU1.id, alphabetId: "alpha", attempts: [], bestScore: 90,
                          isUnlocked: true, isCompleted: true)
        ])

        let vm = PracticeViewModel(
            letterId:           alphaU2.id,
            letterRepository:   MockLetterRepository(letters: letters),
            progressRepository: progressRepository,
            assessor:           MockAssessor(result: makePassingResult()),
            soundService:       MockSoundService(),
            hapticsService:     MockHapticsService(),
            router:             AppRouter()
        )

        vm.submit(strokes: [])
        DispatchQueue.main.sync {}

        #expect(progressRepository.savedUnlockedIds.contains(alphaL1.id))
        #expect(progressRepository.savedUnlockedIds.contains(alphaL2.id))
        #expect(!progressRepository.savedUnlockedIds.contains(betaL1.id),
                "beta's uppercase was never completed, so its lowercase must stay locked")
    }
}
