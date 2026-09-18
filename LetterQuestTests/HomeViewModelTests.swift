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

private final class MockSettingsRepository: SettingsRepositoryProtocol {
    var stored: AppSettings
    init(stored: AppSettings = .default) { self.stored = stored }
    func load() -> Single<AppSettings> { .just(stored) }
    func save(_ settings: AppSettings) -> Completable {
        stored = settings
        return .empty()
    }
}

private final class MockWordRepository: WordRepositoryProtocol {
    let words: [Word]
    init(words: [Word] = []) { self.words = words }
    func fetchAll() -> Single<[Word]> { .just(words) }
    func fetch(by id: UUID) -> Single<Word?> { .just(words.first { $0.id == id }) }
}

private final class MockWordProgressRepository: WordProgressRepositoryProtocol {
    let records: [WordProgress]
    init(records: [WordProgress] = []) { self.records = records }
    func loadAll() -> Single<[WordProgress]> { .just(records) }
    func save(_ progress: WordProgress) -> Completable { .empty() }
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
    settings: AppSettings = .default,
    words: [Word] = [],
    wordRecords: [WordProgress] = [],
    router: AppRouter = AppRouter()
) -> HomeViewModel {
    let vm = HomeViewModel(
        alphabetRepository:     MockAlphabetRepository(alphabets: alphabets),
        progressRepository:     MockProgressRepository(records: records),
        settingsRepository:     MockSettingsRepository(stored: settings),
        wordRepository:         MockWordRepository(words: words),
        wordProgressRepository: MockWordProgressRepository(records: wordRecords),
        router:                 router
    )
    DispatchQueue.main.sync {}
    return vm
}

// MARK: - Active alphabet resolution

struct HomeViewModelActiveAlphabetTests {

    @Test("letters resolve from the persisted activeAlphabetId when it's still installed")
    func resolvesPersistedActiveAlphabet() {
        let vm = makeVM(
            alphabets: [.latin, fictionalAlphabet],
            records: [],
            settings: AppSettings(difficulty: .standard, activeAlphabetId: "fictional")
        )
        #expect(vm.letters.allSatisfy { $0.alphabetId == "fictional" })
        #expect(vm.activeAlphabetDisplayName == "Fictional")
    }

    @Test("falls back to the first installed alphabet when no active alphabet is persisted")
    func fallsBackWhenNoActiveAlphabetPersisted() {
        let vm = makeVM(alphabets: [.latin, fictionalAlphabet], records: [], settings: .default)
        #expect(vm.letters.allSatisfy { $0.alphabetId == Alphabet.latinId })
    }

    @Test("falls back to the first installed alphabet when the persisted id is no longer installed")
    func fallsBackWhenPersistedAlphabetIsGone() {
        let vm = makeVM(
            alphabets: [.latin],
            records: [],
            settings: AppSettings(difficulty: .standard, activeAlphabetId: "no-longer-installed")
        )
        #expect(vm.letters.allSatisfy { $0.alphabetId == Alphabet.latinId })
    }
}

// MARK: - Word mode unlock

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

    @Test("isWordModeUnlocked is true once all of the active alphabet's uppercase and lowercase letters are completed")
    func trueWhenAllLettersCompleted() {
        let records = (Letter.alphabet + Letter.lowercaseAlphabet).map(makeCompletedProgress)
        let vm = makeVM(alphabets: [.latin], records: records)
        #expect(vm.isWordModeUnlocked == true)
    }

    @Test("isWordModeUnlocked scopes to the active alphabet, not merely the first installed one")
    func scopesToActiveAlphabetNotFirstInstalled() {
        let records = fictionalAlphabet.letters.map(makeCompletedProgress)
        let vm = makeVM(
            alphabets: [.latin, fictionalAlphabet],
            records: records,
            settings: AppSettings(difficulty: .standard, activeAlphabetId: "fictional")
        )
        // Latin is untouched, but "fictional" (the active one) is fully completed.
        #expect(vm.isWordModeUnlocked == true)
    }
}

// MARK: - Multi-alphabet

struct HomeViewModelMultiAlphabetTests {

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

    @Test("navigateToSwitchAlphabet pushes one route")
    func navigateToSwitchAlphabetPushesRoute() {
        let router = AppRouter()
        let vm = makeVM(alphabets: [.latin, fictionalAlphabet], records: [], router: router)

        vm.navigateToSwitchAlphabet()
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

// MARK: - Words

struct HomeViewModelWordsTests {

    @Test("words scopes to the active alphabet, not merely the first installed one")
    func wordsScopesToActiveAlphabet() {
        let latinWord     = Word(id: UUID(), text: "cat", alphabetId: Alphabet.latinId)
        let fictionalWord = Word(id: UUID(), text: "ɑɓ", alphabetId: "fictional")
        let vm = makeVM(
            alphabets: [.latin, fictionalAlphabet],
            records: [],
            settings: AppSettings(difficulty: .standard, activeAlphabetId: "fictional"),
            words: [latinWord, fictionalWord]
        )
        #expect(vm.words == [fictionalWord])
    }

    @Test("wordProgressMap keys progress records by word id")
    func wordProgressMapKeyedByWordId() {
        let word = Word(id: UUID(), text: "cat", alphabetId: Alphabet.latinId)
        let progress = WordProgress(wordId: word.id, isCompleted: true)
        let vm = makeVM(alphabets: [.latin], records: [], words: [word], wordRecords: [progress])
        #expect(vm.wordProgressMap[word.id]?.isCompleted == true)
    }

    @Test("selectWord pushes the word practice route")
    func selectWordPushesRoute() {
        let router = AppRouter()
        let word = Word(id: UUID(), text: "cat", alphabetId: Alphabet.latinId)
        let vm = makeVM(alphabets: [.latin], records: [], words: [word], router: router)

        vm.selectWord(word)
        DispatchQueue.main.sync {}

        #expect(router.path.count == 1)
    }
}
