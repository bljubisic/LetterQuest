import Testing
import Foundation
import RxSwift
@testable import LetterQuest

// MARK: - Mocks

private final class MockLetterRepository: LetterRepositoryProtocol {
    let letters: [Letter]
    init(letters: [Letter]) { self.letters = letters }
    func fetchAll() -> Single<[Letter]> { .just(letters) }
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
    func loadAll() -> Single<[ChildProgress]> { .just(records) }
    func save(_ progress: ChildProgress) -> Completable { .empty() }
    func resetAll() -> Completable { .empty() }
}

// MARK: - Helpers

private func makeCompletedProgress(for letter: Letter) -> ChildProgress {
    ChildProgress(
        letterId:    letter.id,
        attempts:    [.init(timestamp: Date(), score: 90)],
        bestScore:   90,
        isUnlocked:  true,
        isCompleted: true
    )
}

private func makeVM(
    letters: [Letter],
    records: [ChildProgress],
    router: AppRouter = AppRouter()
) -> HomeViewModel {
    HomeViewModel(
        letterRepository:   MockLetterRepository(letters: letters),
        progressRepository: MockProgressRepository(records: records),
        router:             router
    )
}

// MARK: - Tests

struct HomeViewModelWordUnlockTests {

    @Test("isWordModeUnlocked is false before any letters are completed")
    func falseWithNoCompletions() {
        let letters = Letter.alphabet + Letter.lowercaseAlphabet
        let vm = makeVM(letters: letters, records: [])
        DispatchQueue.main.sync {}
        #expect(vm.isWordModeUnlocked == false)
    }

    @Test("isWordModeUnlocked is false when only uppercase letters are completed")
    func falseWithOnlyUppercaseCompleted() {
        let letters = Letter.alphabet + Letter.lowercaseAlphabet
        let records = Letter.alphabet.map(makeCompletedProgress)
        let vm = makeVM(letters: letters, records: records)
        DispatchQueue.main.sync {}
        #expect(vm.isWordModeUnlocked == false)
    }

    @Test("isWordModeUnlocked is true once all uppercase and lowercase letters are completed")
    func trueWhenAllLettersCompleted() {
        let letters = Letter.alphabet + Letter.lowercaseAlphabet
        let records = letters.map(makeCompletedProgress)
        let vm = makeVM(letters: letters, records: records)
        DispatchQueue.main.sync {}
        #expect(vm.isWordModeUnlocked == true)
    }
}

struct HomeViewModelNavigationTests {

    @Test("navigateToSettings pushes one route onto the stack")
    func navigateToSettingsPushesRoute() {
        let router = AppRouter()
        let vm = makeVM(letters: Letter.alphabet, records: [], router: router)
        vm.navigateToSettings()
        DispatchQueue.main.sync {}
        #expect(router.path.count == 1)
    }
}
