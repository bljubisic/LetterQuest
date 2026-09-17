import Testing
import Foundation
import RxSwift
import RxBlocking
@testable import LetterQuest

/// Verifies the curated word catalogue served by `WordRepository`.
struct WordRepositoryTests {

    private let repository = WordRepository()

    @Test("fetchAll returns at least 20 curated words")
    func fetchAllReturnsAtLeast20Words() throws {
        let words = try repository.fetchAll().toBlocking().single()
        #expect(words.count >= 20)
    }

    @Test("fetchAll returns words with unique ids")
    func fetchAllWordsHaveUniqueIds() throws {
        let words = try repository.fetchAll().toBlocking().single()
        #expect(Set(words.map(\.id)).count == words.count)
    }

    @Test("every word is a 3-letter lowercase CVC word")
    func everyWordIsThreeLowercaseLetters() throws {
        let words = try repository.fetchAll().toBlocking().single()
        for word in words {
            #expect(word.text.count == 3, "\(word.text) is not 3 letters")
            #expect(word.text == word.text.lowercased(), "\(word.text) is not lowercase")
        }
    }

    @Test("every character in every word exists in its own alphabet's lowercase letters")
    func everyCharacterExistsInItsOwnAlphabetsLowercaseLetters() throws {
        let alphabets = [Alphabet.latin, Alphabet.cyrillicSr]
        let words = try repository.fetchAll().toBlocking().single()
        for word in words {
            let alphabet = try #require(alphabets.first { $0.id == word.alphabetId },
                                        "\(word.text) has unknown alphabetId '\(word.alphabetId)'")
            let lowercaseChars = Set(alphabet.letters.filter { $0.letterCase == .lower }.map(\.character))
            for character in word.characters {
                #expect(lowercaseChars.contains(character),
                        "\(word.text) contains '\(character)' with no matching Letter in \(alphabet.id)")
            }
        }
    }

    @Test("the Cyrillic curated list has 26 words, all tagged with the Cyrillic alphabet id")
    func cyrillicCuratedListIsComplete() {
        #expect(Word.curatedCyrillicSr.count == 26)
        #expect(Word.curatedCyrillicSr.allSatisfy { $0.alphabetId == Alphabet.cyrillicSrId })
    }

    @Test("fetch(by:) returns the matching word")
    func fetchByIdReturnsMatchingWord() throws {
        let words = try repository.fetchAll().toBlocking().single()
        let target = try #require(words.first)
        let result = try repository.fetch(by: target.id).toBlocking().single()
        #expect(result?.id == target.id)
    }

    @Test("fetch(by:) returns nil for an unknown id")
    func fetchByIdReturnsNilForUnknownId() throws {
        let result = try repository.fetch(by: UUID()).toBlocking().single()
        #expect(result == nil)
    }
}
