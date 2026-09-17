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
    alphabetId: String,
    alphabets: [Alphabet],
    records: [ChildProgress] = [],
    router: AppRouter = AppRouter()
) -> AlphabetLettersViewModel {
    let vm = AlphabetLettersViewModel(
        alphabetId:         alphabetId,
        alphabetRepository: MockAlphabetRepository(alphabets: alphabets),
        progressRepository: MockProgressRepository(records: records),
        router:             router
    )
    DispatchQueue.main.sync {}
    return vm
}

// MARK: - Letters

struct AlphabetLettersViewModelLettersTests {

    @Test("letters are filtered to the given alphabetId and selected case")
    func lettersFilteredByAlphabetAndCase() {
        let vm = makeVM(alphabetId: "fictional", alphabets: [.latin, fictionalAlphabet])

        #expect(vm.letters.allSatisfy { $0.alphabetId == "fictional" })
        #expect(vm.letters.allSatisfy { $0.letterCase == .upper })
        #expect(vm.letters.count == 2)
    }

    @Test("selectCase switches the visible set")
    func selectCaseSwitchesVisibleSet() {
        let vm = makeVM(alphabetId: "fictional", alphabets: [.latin, fictionalAlphabet])

        vm.selectCase(.lower)

        #expect(vm.selectedCase == .lower)
        #expect(vm.letters.allSatisfy { $0.letterCase == .lower })
        #expect(vm.letters.count == 2)
    }

    @Test("alphabetDisplayName matches the resolved alphabet")
    func alphabetDisplayNameMatches() {
        let vm = makeVM(alphabetId: "fictional", alphabets: [.latin, fictionalAlphabet])
        #expect(vm.alphabetDisplayName == "Fictional")
    }
}

// MARK: - Default unlock

struct AlphabetLettersViewModelUnlockTests {

    @Test("this alphabet's own first uppercase letter is unlocked by default")
    func defaultUnlockIsScopedToThisAlphabet() {
        let vm = makeVM(alphabetId: "fictional", alphabets: [.latin, fictionalAlphabet])

        let fictionalFirst = try! #require(fictionalAlphabet.letters.first { $0.letterCase == .upper })
        let fictionalSecond = try! #require(fictionalAlphabet.letters.first { $0.character == "Ɓ" })

        #expect(vm.isUnlocked(fictionalFirst) == true)
        #expect(vm.isUnlocked(fictionalSecond) == false)
    }
}

// MARK: - Word mode unlock

struct AlphabetLettersViewModelWordUnlockTests {

    @Test("isWordModeUnlocked is false before this alphabet's letters are completed")
    func falseBeforeCompletion() {
        let vm = makeVM(alphabetId: "fictional", alphabets: [.latin, fictionalAlphabet])
        #expect(vm.isWordModeUnlocked == false)
    }

    @Test("isWordModeUnlocked is true once this alphabet's own upper and lower letters are completed")
    func trueOnceThisAlphabetIsComplete() {
        let records = fictionalAlphabet.letters.map(makeCompletedProgress)
        let vm = makeVM(alphabetId: "fictional", alphabets: [.latin, fictionalAlphabet], records: records)
        #expect(vm.isWordModeUnlocked == true)
    }
}

// MARK: - Navigation

struct AlphabetLettersViewModelNavigationTests {

    @Test("selectLetter pushes the learn route for the tapped letter")
    func selectLetterPushesLearnRoute() {
        let router = AppRouter()
        let vm = makeVM(alphabetId: "fictional", alphabets: [.latin, fictionalAlphabet], router: router)

        let letter = try! #require(fictionalAlphabet.letters.first)
        vm.selectLetter(letter)
        DispatchQueue.main.sync {}

        #expect(router.path.count == 1)
    }

    @Test("navigateToWords pushes the words route for this alphabet")
    func navigateToWordsPushesRoute() {
        let router = AppRouter()
        let vm = makeVM(alphabetId: "fictional", alphabets: [.latin, fictionalAlphabet], router: router)

        vm.navigateToWords()
        DispatchQueue.main.sync {}

        #expect(router.path.count == 1)
    }
}
