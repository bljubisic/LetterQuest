import Testing
import Foundation
import RxSwift
import RxBlocking
@testable import LetterQuest

struct LetterRepositoryTests {

    private let repository = LetterRepository()

    // MARK: - fetchAll

    @Test("fetchAll returns exactly 26 letters")
    func fetchAllReturns26Letters() throws {
        let letters = try repository.fetchAll().toBlocking().single()
        #expect(letters.count == 26)
    }

    @Test("fetchAll returns letters for every uppercase ASCII character A–Z")
    func fetchAllCoversFullAlphabet() throws {
        let letters = try repository.fetchAll().toBlocking().single()
        let characters = Set(letters.map(\.character))
        for char in "ABCDEFGHIJKLMNOPQRSTUVWXYZ" {
            #expect(characters.contains(char), "Missing letter: \(char)")
        }
    }

    @Test("fetchAll returns letters in A–Z order")
    func fetchAllIsInAlphabeticalOrder() throws {
        let letters = try repository.fetchAll().toBlocking().single()
        let chars   = letters.map(\.character)
        #expect(chars == Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ"))
    }

    @Test("fetchAll letters each have at least one stroke template")
    func fetchAllLettersHaveTemplates() throws {
        let letters = try repository.fetchAll().toBlocking().single()
        for letter in letters {
            #expect(!letter.strokeTemplates.isEmpty, "Letter \(letter.character) has no stroke templates")
        }
    }

    @Test("fetchAll assigns the correct difficulty tiers")
    func fetchAllDifficultyTiersAreCorrect() throws {
        let letters = try repository.fetchAll().toBlocking().single()
        // A–E (indices 0–4) → easy
        for letter in letters.prefix(5) {
            #expect(letter.difficulty == .easy, "Expected easy for \(letter.character)")
        }
        // F–O (indices 5–14) → medium
        for letter in letters[5..<15] {
            #expect(letter.difficulty == .medium, "Expected medium for \(letter.character)")
        }
        // P–Z (indices 15–25) → hard
        for letter in letters[15...] {
            #expect(letter.difficulty == .hard, "Expected hard for \(letter.character)")
        }
    }

    @Test("fetchAll letters all have unique ids")
    func fetchAllLetterIdsAreUnique() throws {
        let letters = try repository.fetchAll().toBlocking().single()
        let ids = letters.map(\.id)
        #expect(Set(ids).count == ids.count)
    }

    // MARK: - fetch(by:)

    @Test("fetch(by:) returns the matching letter")
    func fetchByIdReturnsMatchingLetter() throws {
        let letters = try repository.fetchAll().toBlocking().single()
        let target  = letters[0]
        let fetched = try repository.fetch(by: target.id).toBlocking().single()
        #expect(fetched?.id == target.id)
        #expect(fetched?.character == target.character)
    }

    @Test("fetch(by:) returns nil for an unknown id")
    func fetchByUnknownIdReturnsNil() throws {
        let result = try repository.fetch(by: UUID()).toBlocking().single()
        #expect(result == nil)
    }

    @Test("fetch(by:) returns each letter when queried by its own id")
    func fetchByIdWorksForAllLetters() throws {
        let letters = try repository.fetchAll().toBlocking().single()
        for letter in letters {
            let fetched = try repository.fetch(by: letter.id).toBlocking().single()
            #expect(fetched?.character == letter.character)
        }
    }

    // MARK: - Consistency with Letter.alphabet

    @Test("repository data matches Letter.alphabet")
    func repositoryMatchesStaticAlphabet() throws {
        let letters = try repository.fetchAll().toBlocking().single()
        #expect(letters.count == Letter.alphabet.count)
        for (repoLetter, alphabetLetter) in zip(letters, Letter.alphabet) {
            #expect(repoLetter.character == alphabetLetter.character)
            #expect(repoLetter.difficulty == alphabetLetter.difficulty)
        }
    }

    @Test("every letter's templateImageName follows the template_<CHAR> convention")
    func templateImageNamesFollowConvention() throws {
        let letters = try repository.fetchAll().toBlocking().single()
        for letter in letters {
            if let name = letter.templateImageName {
                #expect(
                    name == "template_\(letter.character)",
                    "Letter \(letter.character) has unexpected templateImageName: \(name)"
                )
            }
        }
    }
}
