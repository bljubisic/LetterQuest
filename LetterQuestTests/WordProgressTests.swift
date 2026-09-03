import Testing
import Foundation
import RxSwift
import RxBlocking
@testable import LetterQuest

// MARK: - WordProgress lens

struct WordProgressLensTests {

    @Test("lensIsCompleted.set updates isCompleted, leaving wordId intact")
    func lensIsCompletedSetsFlag() {
        let progress = WordProgress(wordId: UUID(), isCompleted: false)
        let updated  = WordProgress.lensIsCompleted.set(progress, true)
        #expect(updated.isCompleted == true)
        #expect(updated.wordId == progress.wordId)
    }
}

// MARK: - WordProgressRepository (UserDefaults-backed)

struct WordProgressRepositoryTests {

    private let suiteName = "com.letterquest.tests.\(UUID().uuidString)"

    private var repository: WordProgressRepository {
        WordProgressRepository(userDefaults: UserDefaults(suiteName: suiteName)!)
    }

    @Test("loadAll returns an empty array when no progress has been saved")
    func loadAllInitiallyEmpty() throws {
        let repo = repository
        let all = try repo.loadAll().toBlocking().single()
        #expect(all.isEmpty)
    }

    @Test("save then loadAll round-trips a WordProgress record correctly")
    func saveAndLoadRoundTrips() throws {
        let repo     = repository
        let progress = WordProgress(wordId: UUID(), isCompleted: true)
        try repo.save(progress).toBlocking().first()
        let all = try repo.loadAll().toBlocking().single()
        #expect(all.count == 1)
        #expect(all[0].wordId == progress.wordId)
        #expect(all[0].isCompleted == true)
    }

    @Test("saving a progress record for the same word replaces the previous record")
    func savingReplacesSameWord() throws {
        let repo   = repository
        let wordId = UUID()
        try repo.save(WordProgress(wordId: wordId, isCompleted: false)).toBlocking().first()
        try repo.save(WordProgress(wordId: wordId, isCompleted: true)).toBlocking().first()
        let all = try repo.loadAll().toBlocking().single()
        #expect(all.count == 1)
        #expect(all[0].isCompleted == true)
    }

    @Test("saving progress records for different words keeps all of them")
    func savingDifferentWordsKeepsAll() throws {
        let repo = repository
        try repo.save(WordProgress(wordId: UUID(), isCompleted: true)).toBlocking().first()
        try repo.save(WordProgress(wordId: UUID(), isCompleted: false)).toBlocking().first()
        let all = try repo.loadAll().toBlocking().single()
        #expect(all.count == 2)
    }
}
