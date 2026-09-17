import Testing
import Foundation
import RxSwift
@testable import LetterQuest

// MARK: - Mocks

private final class MockAlphabetRepository: AlphabetRepositoryProtocol {
    let alphabets: [Alphabet]
    init(alphabets: [Alphabet]) { self.alphabets = alphabets }
    func fetchAvailable() -> Single<[Alphabet]> { .just(alphabets) }
    func fetchInstalled() -> Single<[Alphabet]> { .just(alphabets) }
}

private final class MockProgressRepository: ProgressRepositoryProtocol {
    let records: [ChildProgress]
    init(records: [ChildProgress] = []) { self.records = records }
    func loadAll() -> Single<[ChildProgress]> { .just(records) }
    func save(_ progress: ChildProgress) -> Completable { .empty() }
    func resetAll() -> Completable { .empty() }
}

// MARK: - Fixtures

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

private let fictionalAlphabet = Alphabet(
    id: "fictional",
    displayName: "Fictional",
    nativeName: "Fictional",
    scriptCode: "Zzzz",
    localeIdentifier: "und",
    isFree: false,
    letters: [
        makeLetter("Ɑ", case: .upper, alphabetId: "fictional"),
        makeLetter("Ɓ", case: .upper, alphabetId: "fictional"),
        makeLetter("ɑ", case: .lower, alphabetId: "fictional"),
        makeLetter("ɓ", case: .lower, alphabetId: "fictional")
    ],
    productId: "com.letterquest.tests.fictional"
)

// MARK: - Helpers

private func makeCompletedProgress(for letter: Letter) -> ChildProgress {
    ChildProgress(
        letterId:    letter.id,
        alphabetId:  letter.alphabetId,
        attempts:    [.init(timestamp: Date(), score: 90)],
        bestScore:   90,
        isUnlocked:  true,
        isCompleted: true
    )
}

private func makeVM(
    alphabets: [Alphabet],
    records: [ChildProgress],
    router: AppRouter = AppRouter()
) -> HomeViewModel {
    let vm = HomeViewModel(
        alphabetRepository: MockAlphabetRepository(alphabets: alphabets),
        progressRepository: MockProgressRepository(records: records),
        router:             router
    )
    DispatchQueue.main.sync {}
    return vm
}

// MARK: - Word mode unlock (Latin-scoped)

struct HomeViewModelWordUnlockTests {

    @Test("isWordModeUnlocked is false before any letters are completed")
    func falseWithNoCompletions() {
        let vm = makeVM(alphabets: [.latin], records: [])
        #expect(vm.isWordModeUnlocked == false)
    }

    @Test("isWordModeUnlocked is false when only uppercase letters are completed")
    func falseWithOnlyUppercaseCompleted() {
        let records = Letter.alphabet.map(makeCompletedProgress)
        let vm = makeVM(alphabets: [.latin], records: records)
        #expect(vm.isWordModeUnlocked == false)
    }

    @Test("isWordModeUnlocked is true once all Latin uppercase and lowercase letters are completed")
    func trueWhenAllLettersCompleted() {
        let records = (Letter.alphabet + Letter.lowercaseAlphabet).map(makeCompletedProgress)
        let vm = makeVM(alphabets: [.latin], records: records)
        #expect(vm.isWordModeUnlocked == true)
    }

    @Test("isWordModeUnlocked stays gated on Latin even when a second alphabet is incomplete")
    func stillScopedToLatinWithSecondIncompleteAlphabet() {
        let records = (Letter.alphabet + Letter.lowercaseAlphabet).map(makeCompletedProgress)
        let vm = makeVM(alphabets: [.latin, fictionalAlphabet], records: records)
        #expect(vm.isWordModeUnlocked == true)
    }
}

// MARK: - Multi-alphabet selection

struct HomeViewModelAlphabetSelectionTests {

    @Test("isMultiAlphabet is false with only one installed alphabet")
    func singleAlphabetIsNotMulti() {
        let vm = makeVM(alphabets: [.latin], records: [])
        #expect(vm.isMultiAlphabet == false)
    }

    @Test("isMultiAlphabet is true with more than one installed alphabet")
    func twoAlphabetsIsMulti() {
        let vm = makeVM(alphabets: [.latin, fictionalAlphabet], records: [])
        #expect(vm.isMultiAlphabet == true)
    }

    @Test("selectAlphabet pushes the alphabet-letters route for the given alphabet")
    func selectAlphabetPushesRoute() {
        let router = AppRouter()
        let vm = makeVM(alphabets: [.latin, fictionalAlphabet], records: [], router: router)

        vm.selectAlphabet("fictional")
        DispatchQueue.main.sync {}

        #expect(router.path.count == 1)
    }
}

// MARK: - Navigation

struct HomeViewModelNavigationTests {

    @Test("navigateToSettings pushes one route onto the stack")
    func navigateToSettingsPushesRoute() {
        let router = AppRouter()
        let vm = makeVM(alphabets: [.latin], records: [], router: router)
        vm.navigateToSettings()
        DispatchQueue.main.sync {}
        #expect(router.path.count == 1)
    }
}
