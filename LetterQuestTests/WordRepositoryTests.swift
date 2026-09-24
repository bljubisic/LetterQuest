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

    @Test("every English and Serbian Cyrillic word is a 3-letter lowercase CVC word")
    func everyLatinAndCyrillicWordIsThreeLowercaseLetters() throws {
        let words = try repository.fetchAll().toBlocking().single()
            .filter { [Alphabet.latinId, Alphabet.cyrillicSrId].contains($0.alphabetId) }
        for word in words {
            #expect(word.text.count == 3, "\(word.text) is not 3 letters")
            #expect(word.text == word.text.lowercased(), "\(word.text) is not lowercase")
        }
    }

    @Test("every German word is a 3–4 letter noun: capitalised first letter, lowercase after")
    func everyGermanWordIsACapitalisedShortNoun() {
        for word in Word.curatedGerman {
            #expect((3...4).contains(word.text.count), "\(word.text) is not 3–4 letters")
            let first = word.text.prefix(1), rest = word.text.dropFirst()
            #expect(first == first.uppercased(), "\(word.text) doesn't start with a capital")
            #expect(rest == rest.lowercased(), "\(word.text) has a capital after its first letter")
        }
    }

    @Test("every character in every word exists in its own alphabet's letters")
    func everyCharacterExistsInItsOwnAlphabetsLetters() throws {
        let alphabets = [Alphabet.latin, Alphabet.cyrillicSr, Alphabet.german]
        let words = try repository.fetchAll().toBlocking().single()
        for word in words {
            let alphabet = try #require(alphabets.first { $0.id == word.alphabetId },
                                        "\(word.text) has unknown alphabetId '\(word.alphabetId)'")
            let characters = Set(alphabet.letters.map(\.character))
            for character in word.characters {
                #expect(characters.contains(character),
                        "\(word.text) contains '\(character)' with no matching Letter in \(alphabet.id)")
            }
        }
    }

    @Test("the German curated list has 26 words, all tagged with the German alphabet id")
    func germanCuratedListIsComplete() {
        #expect(Word.curatedGerman.count == 26)
        #expect(Word.curatedGerman.allSatisfy { $0.alphabetId == Alphabet.germanId })
    }

    @Test("the German words between them use each of ä, ö, ü and ß")
    func germanWordsCoverSpecialLetters() {
        let characters = Set(Word.curatedGerman.flatMap(\.characters))
        for special: Character in ["ä", "ö", "ü", "ß"] {
            #expect(characters.contains(special), "no German word uses '\(special)'")
        }
    }

    @Test("German word ids are namespaced by alphabet, so they never collide with another list's")
    func germanWordIdsAreNamespaced() {
        for word in Word.curatedGerman {
            #expect(word.id == DeterministicID.uuid(name: "word.\(Alphabet.germanId).\(word.text)"))
        }
    }

    @Test("fetchAll includes the German words")
    func fetchAllIncludesGermanWords() throws {
        let words = try repository.fetchAll().toBlocking().single()
        #expect(words.filter { $0.alphabetId == Alphabet.germanId }.count == Word.curatedGerman.count)
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
