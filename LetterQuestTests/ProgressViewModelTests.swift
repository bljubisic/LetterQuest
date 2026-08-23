import Testing
import Foundation
import RxSwift
@testable import LetterQuest

// MARK: - Mocks

private final class MockLetterRepository: LetterRepositoryProtocol {
    let letters: [Letter]
    init(letters: [Letter] = Letter.alphabet) { self.letters = letters }
    func fetchAll() -> Single<[Letter]>     { .just(letters) }
    func fetch(by id: UUID) -> Single<Letter?> { .just(letters.first { $0.id == id }) }
    func fetchNext(after id: UUID) -> Single<Letter?> {
        guard let idx = letters.firstIndex(where: { $0.id == id }),
              idx + 1 < letters.count else { return .just(nil) }
        return .just(letters[idx + 1])
    }
}

private final class MockProgressRepository: ProgressRepositoryProtocol {
    let records: [ChildProgress]
    init(records: [ChildProgress] = []) { self.records = records }
    func loadAll() -> Single<[ChildProgress]>        { .just(records) }
    func save(_ progress: ChildProgress) -> Completable { .empty() }
}

// MARK: - Helpers

private func makeProgress(for letter: Letter, score: Int, completed: Bool) -> ChildProgress {
    ChildProgress(
        letterId:    letter.id,
        attempts:    [.init(timestamp: Date(), score: score)],
        bestScore:   score,
        isUnlocked:  true,
        isCompleted: completed
    )
}

private func makeVM(records: [ChildProgress]) -> ProgressViewModel {
    ProgressViewModel(
        letterRepository:   MockLetterRepository(),
        progressRepository: MockProgressRepository(records: records)
    )
}

// MARK: - Tests

struct ProgressViewModelTests {

    @Test("letters and progressMap are populated on init")
    func lettersAndProgressLoadOnInit() {
        let letter   = Letter.alphabet[0]
        let record   = makeProgress(for: letter, score: 80, completed: true)
        let vm       = makeVM(records: [record])
        DispatchQueue.main.sync {}
        #expect(vm.letters.count == 26)
        #expect(vm.progressMap[letter.id] != nil)
    }

    @Test("completedCount reflects the number of isCompleted records")
    func completedCountIsCorrect() {
        let records = Letter.alphabet.prefix(4).map {
            makeProgress(for: $0, score: 80, completed: true)
        }
        let vm = makeVM(records: Array(records))
        DispatchQueue.main.sync {}
        #expect(vm.completedCount == 4)
    }

    @Test("no badges earned with zero completions")
    func noBadgesEarnedWithZeroCompletions() {
        let vm = makeVM(records: [])
        DispatchQueue.main.sync {}
        #expect(vm.badges.allSatisfy { !$0.isEarned })
    }

    @Test("first badge earned after one completion")
    func firstBadgeEarnedAfterOneCompletion() {
        let record = makeProgress(for: Letter.alphabet[0], score: 80, completed: true)
        let vm     = makeVM(records: [record])
        DispatchQueue.main.sync {}
        let firstBadge = vm.badges.first { $0.id == "first_letter" }
        #expect(firstBadge?.isEarned == true)
        #expect(vm.badges.first { $0.id == "halfway" }?.isEarned == false)
        #expect(vm.badges.first { $0.id == "champion" }?.isEarned == false)
    }

    @Test("halfway badge earned at 13 completions")
    func halfwayBadgeEarnedAt13() {
        let records = Letter.alphabet.prefix(13).map {
            makeProgress(for: $0, score: 80, completed: true)
        }
        let vm = makeVM(records: Array(records))
        DispatchQueue.main.sync {}
        #expect(vm.badges.first { $0.id == "halfway" }?.isEarned == true)
        #expect(vm.badges.first { $0.id == "champion" }?.isEarned == false)
    }

    @Test("champion badge earned when all 26 letters are completed")
    func championBadgeEarnedAt26() {
        let records = Letter.alphabet.map {
            makeProgress(for: $0, score: 80, completed: true)
        }
        let vm = makeVM(records: records)
        DispatchQueue.main.sync {}
        #expect(vm.badges.allSatisfy { $0.isEarned })
    }

    @Test("totalCount is always 26")
    func totalCountIsAlways26() {
        let vm = makeVM(records: [])
        #expect(vm.totalCount == 26)
    }
}
