import Testing
import Foundation
import PencilKit
import RxSwift
@testable import LetterQuest

// MARK: - Mocks

private final class MockWordRepository: WordRepositoryProtocol {
    let words: [Word]
    init(words: [Word]) { self.words = words }
    func fetchAll() -> Single<[Word]> { .just(words) }
    func fetch(by id: UUID) -> Single<Word?> { .just(words.first { $0.id == id }) }
}

private final class MockLetterRepository: LetterRepositoryProtocol {
    let letters: [Letter]
    init(letters: [Letter] = Letter.lowercaseAlphabet) { self.letters = letters }
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

private final class MockWordProgressRepository: WordProgressRepositoryProtocol {
    private(set) var saved: [WordProgress] = []
    func loadAll() -> Single<[WordProgress]> { .just(saved) }
    func save(_ progress: WordProgress) -> Completable {
        saved.append(progress)
        return .empty()
    }
    func resetAll() -> Completable {
        saved.removeAll()
        return .empty()
    }
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

private func makeResult(passed: Bool) -> AssessmentResult {
    let score = passed ? 90 : 20
    return AssessmentResult(
        overallScore:     score,
        strokeOrderScore: score,
        shapeScore:       score,
        proportionScore:  score,
        smoothnessScore:  score,
        feedback:         [],
        passed:           passed
    )
}

private struct Fixture {
    let word: Word
    let vm: WordPracticeViewModel
    let assessor: MockAssessor
    let wordProgressRepository: MockWordProgressRepository
}

private func makeFixture(passed: Bool = true) -> Fixture {
    let word     = Word(id: UUID(), text: "cat")
    let assessor = MockAssessor(result: makeResult(passed: passed))
    let wordProgressRepository = MockWordProgressRepository()
    let vm = WordPracticeViewModel(
        wordId:                 word.id,
        wordRepository:         MockWordRepository(words: [word]),
        letterRepository:       MockLetterRepository(),
        progressRepository:     MockProgressRepository(),
        wordProgressRepository: wordProgressRepository,
        assessor:               assessor,
        soundService:           MockSoundService(),
        hapticsService:         MockHapticsService(),
        router:                 AppRouter()
    )
    return Fixture(word: word, vm: vm, assessor: assessor, wordProgressRepository: wordProgressRepository)
}

/// Submits to the current letter's `PracticeViewModel` and, if it passed,
/// taps through to the next letter exactly like `CelebrationView`'s
/// continue button would.
private func passCurrentLetter(_ fixture: Fixture) throws {
    let letterVM = try #require(fixture.vm.makeLetterViewModel())
    letterVM.submit(strokes: [])
    DispatchQueue.main.sync {}
    letterVM.continueToNext()
    DispatchQueue.main.sync {}
}

// MARK: - Tests

struct WordPracticeViewModelTests {

    @Test("makeLetterViewModel returns nil before the word has resolved to a Letter id")
    func makeLetterViewModelReturnsNilForUnknownWord() {
        let word = Word(id: UUID(), text: "cat")
        // Empty letter catalogue: "c" can never resolve to a Letter id.
        let vm = WordPracticeViewModel(
            wordId:                 word.id,
            wordRepository:         MockWordRepository(words: [word]),
            letterRepository:       MockLetterRepository(letters: []),
            progressRepository:     MockProgressRepository(),
            wordProgressRepository: MockWordProgressRepository(),
            assessor:               MockAssessor(result: makeResult(passed: true)),
            soundService:           MockSoundService(),
            hapticsService:         MockHapticsService(),
            router:                 AppRouter()
        )
        DispatchQueue.main.sync {}
        #expect(vm.word?.text == "cat")
        #expect(vm.makeLetterViewModel() == nil)
    }

    @Test("word loads asynchronously and starts at index 0")
    func wordLoadsAndStartsAtIndexZero() {
        let fixture = makeFixture()
        DispatchQueue.main.sync {}
        #expect(fixture.vm.word?.text == "cat")
        #expect(fixture.vm.currentIndex == 0)
        #expect(fixture.vm.isWordCompleted == false)
    }

    @Test("makeLetterViewModel resolves the correct lowercase Letter for the current index")
    func makeLetterViewModelResolvesCorrectLetter() throws {
        let fixture = makeFixture()
        DispatchQueue.main.sync {}
        let letterVM = try #require(fixture.vm.makeLetterViewModel())
        DispatchQueue.main.sync {}
        #expect(letterVM.letter?.character == "c")
    }

    @Test("passing a letter advances currentIndex without completing the word")
    func passingOneLetterAdvancesIndex() throws {
        let fixture = makeFixture(passed: true)
        DispatchQueue.main.sync {}
        try passCurrentLetter(fixture)
        #expect(fixture.vm.currentIndex == 1)
        #expect(fixture.vm.isWordCompleted == false)
        #expect(fixture.wordProgressRepository.saved.isEmpty)
    }

    @Test("passing every letter marks the word completed and persists WordProgress once")
    func passingAllLettersCompletesWord() throws {
        let fixture = makeFixture(passed: true)
        DispatchQueue.main.sync {}
        try passCurrentLetter(fixture) // c
        try passCurrentLetter(fixture) // a
        try passCurrentLetter(fixture) // t
        #expect(fixture.vm.isWordCompleted == true)
        #expect(fixture.wordProgressRepository.saved.count == 1)
        #expect(fixture.wordProgressRepository.saved.first?.wordId == fixture.word.id)
        #expect(fixture.wordProgressRepository.saved.first?.isCompleted == true)
    }

    @Test("a failing submission does not advance the sequence")
    func failingSubmissionDoesNotAdvance() throws {
        let fixture = makeFixture(passed: false)
        DispatchQueue.main.sync {}
        let letterVM = try #require(fixture.vm.makeLetterViewModel())
        letterVM.submit(strokes: [])
        DispatchQueue.main.sync {}
        #expect(letterVM.showCelebration == false)
        #expect(fixture.vm.currentIndex == 0)
        #expect(fixture.vm.isWordCompleted == false)
    }
}
