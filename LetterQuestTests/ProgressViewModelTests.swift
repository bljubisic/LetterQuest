import Testing
import Foundation
import RxSwift
@testable import LetterQuest

// MARK: - Mocks

private final class MockAlphabetRepository: AlphabetRepositoryProtocol {
    let alphabets: [Alphabet]
    init(alphabets: [Alphabet] = [.latin]) { self.alphabets = alphabets }
    func fetchAvailable() -> Single<[Alphabet]> { .just(alphabets) }
    func fetchInstalled() -> Single<[Alphabet]> { .just(alphabets) }
}

private final class MockProgressRepository: ProgressRepositoryProtocol {
    let records: [ChildProgress]
    init(records: [ChildProgress] = []) { self.records = records }
    func loadAll() -> Single<[ChildProgress]>        { .just(records) }
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

private func makeProgress(for letter: Letter, score: Int, completed: Bool) -> ChildProgress {
    ChildProgress(
        letterId:    letter.id,
        alphabetId:  letter.alphabetId,
        attempts:    [.init(timestamp: Date(), score: score)],
        bestScore:   score,
        isUnlocked:  true,
        isCompleted: completed
    )
}

private func makeVM(
    alphabets: [Alphabet] = [.latin],
    records: [ChildProgress] = [],
    settings: AppSettings = .default,
    words: [Word] = [],
    wordRecords: [WordProgress] = []
) -> ProgressViewModel {
    let vm = ProgressViewModel(
        alphabetRepository:     MockAlphabetRepository(alphabets: alphabets),
        progressRepository:     MockProgressRepository(records: records),
        settingsRepository:     MockSettingsRepository(stored: settings),
        wordRepository:         MockWordRepository(words: words),
        wordProgressRepository: MockWordProgressRepository(records: wordRecords)
    )
    DispatchQueue.main.sync {}
    return vm
}

// MARK: - Tests

struct ProgressViewModelTests {

    @Test("letters and progressMap are populated on init")
    func lettersAndProgressLoadOnInit() {
        let letter   = Letter.alphabet[0]
        let record   = makeProgress(for: letter, score: 80, completed: true)
        let vm       = makeVM(records: [record])
        #expect(vm.letters.count == 26)
        #expect(vm.progressMap[letter.id] != nil)
    }

    @Test("completedCount reflects the number of isCompleted records")
    func completedCountIsCorrect() {
        let records = Letter.alphabet.prefix(4).map {
            makeProgress(for: $0, score: 80, completed: true)
        }
        let vm = makeVM(records: Array(records))
        #expect(vm.completedCount == 4)
    }

    @Test("no badges earned with zero completions")
    func noBadgesEarnedWithZeroCompletions() {
        let vm = makeVM(records: [])
        #expect(vm.badges.allSatisfy { !$0.isEarned })
    }

    @Test("first badge earned after one completion")
    func firstBadgeEarnedAfterOneCompletion() {
        let record = makeProgress(for: Letter.alphabet[0], score: 80, completed: true)
        let vm     = makeVM(records: [record])
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
        #expect(vm.badges.first { $0.id == "halfway" }?.isEarned == true)
        #expect(vm.badges.first { $0.id == "champion" }?.isEarned == false)
    }

    @Test("champion badge earned when all 26 letters are completed")
    func championBadgeEarnedAt26() {
        let records = Letter.alphabet.map {
            makeProgress(for: $0, score: 80, completed: true)
        }
        let vm = makeVM(records: records)
        #expect(vm.badges.first { $0.id == "champion" }?.isEarned == true)
    }

    @Test("totalCount matches the active alphabet's actual letter count")
    func totalCountMatchesActiveAlphabet() {
        let vm = makeVM(records: [])
        #expect(vm.totalCount == 26)
    }

    @Test("selectedCase defaults to uppercase")
    func selectedCaseDefaultsToUppercase() {
        let vm = makeVM(records: [])
        #expect(vm.selectedCase == .upper)
    }

    @Test("selectCase switches to lowercase")
    func selectCaseSwitchesToLowercase() {
        let vm = makeVM(records: [])
        vm.selectCase(.lower)
        #expect(vm.selectedCase == .lower)
    }
}

// MARK: - Words

struct ProgressViewModelWordsTests {

    private var allLettersCompleted: [ChildProgress] {
        (Letter.alphabet + Letter.lowercaseAlphabet).map {
            makeProgress(for: $0, score: 90, completed: true)
        }
    }

    @Test("isWordSectionVisible is false before all letters are completed")
    func wordSectionHiddenBeforeAllLettersCompleted() {
        let vm = makeVM(records: [])
        #expect(vm.isWordSectionVisible == false)
    }

    @Test("isWordSectionVisible is true once every letter is completed")
    func wordSectionVisibleOnceAllLettersCompleted() {
        let vm = makeVM(records: allLettersCompleted)
        #expect(vm.isWordSectionVisible == true)
    }

    @Test("completedWordsCount reflects the number of completed word records")
    func completedWordsCountIsCorrect() {
        let words = [
            Word(id: UUID(), text: "cat", alphabetId: Alphabet.latinId),
            Word(id: UUID(), text: "dog", alphabetId: Alphabet.latinId)
        ]
        let wordRecords = [WordProgress(wordId: words[0].id, isCompleted: true)]
        let vm = makeVM(records: [], words: words, wordRecords: wordRecords)
        #expect(vm.completedWordsCount == 1)
    }

    @Test("Wordsmith badge is not earned before the word section is visible")
    func wordsmithNotEarnedBeforeWordSectionVisible() {
        let words = [Word(id: UUID(), text: "cat", alphabetId: Alphabet.latinId)]
        let wordRecords = [WordProgress(wordId: words[0].id, isCompleted: true)]
        let vm = makeVM(records: [], words: words, wordRecords: wordRecords)
        #expect(vm.badges.first { $0.id == "wordsmith" }?.isEarned == false)
    }

    @Test("Wordsmith badge is earned once every active-alphabet word is completed")
    func wordsmithEarnedWhenAllWordsCompleted() {
        let words = [
            Word(id: UUID(), text: "cat", alphabetId: Alphabet.latinId),
            Word(id: UUID(), text: "dog", alphabetId: Alphabet.latinId)
        ]
        let wordRecords = words.map { WordProgress(wordId: $0.id, isCompleted: true) }
        let vm = makeVM(records: allLettersCompleted, words: words, wordRecords: wordRecords)
        #expect(vm.badges.first { $0.id == "wordsmith" }?.isEarned == true)
    }

    @Test("Wordsmith badge is not earned when only some words are completed")
    func wordsmithNotEarnedWithPartialWordCompletion() {
        let words = [
            Word(id: UUID(), text: "cat", alphabetId: Alphabet.latinId),
            Word(id: UUID(), text: "dog", alphabetId: Alphabet.latinId)
        ]
        let wordRecords = [WordProgress(wordId: words[0].id, isCompleted: true)]
        let vm = makeVM(records: allLettersCompleted, words: words, wordRecords: wordRecords)
        #expect(vm.badges.first { $0.id == "wordsmith" }?.isEarned == false)
    }
}

// MARK: - Multi-alphabet scoping

struct ProgressViewModelActiveAlphabetTests {

    @Test("with two installed alphabets, letters/totalCount/badges reflect only the active one")
    func scopesToActiveAlphabetNotAllInstalled() {
        let vm = makeVM(
            alphabets: [.latin, fictionalAlphabet],
            records: [],
            settings: AppSettings(difficulty: .standard, activeAlphabetId: "fictional")
        )

        #expect(vm.letters.allSatisfy { $0.alphabetId == "fictional" })
        #expect(vm.letters.count == 2) // fictionalAlphabet has 2 uppercase letters
        #expect(vm.totalCount == 2)
    }

    @Test("champion badge threshold scales to the active alphabet's own uppercase count")
    func championThresholdScalesToActiveAlphabet() {
        let letters = fictionalAlphabet.letters.filter { $0.letterCase == .upper }
        let records = letters.map { makeProgress(for: $0, score: 80, completed: true) }
        let vm = makeVM(
            alphabets: [.latin, fictionalAlphabet],
            records: records,
            settings: AppSettings(difficulty: .standard, activeAlphabetId: "fictional")
        )

        #expect(vm.badges.first { $0.id == "champion" }?.isEarned == true)
    }

    @Test("falls back to the first installed alphabet when no active alphabet is persisted")
    func fallsBackToFirstInstalledWhenNoActiveAlphabet() {
        let vm = makeVM(alphabets: [.latin, fictionalAlphabet], records: [], settings: .default)
        #expect(vm.letters.allSatisfy { $0.alphabetId == Alphabet.latinId })
    }
}
