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
        let alphabets = [Alphabet.latin, Alphabet.cyrillicSr, Alphabet.german, Alphabet.spanish, Alphabet.swedish,
                         Alphabet.croatian, Alphabet.french]
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

    @Test("the Spanish curated list has 26 words, all tagged with the Spanish alphabet id")
    func spanishCuratedListIsComplete() {
        #expect(Word.curatedSpanish.count == 26)
        #expect(Word.curatedSpanish.allSatisfy { $0.alphabetId == Alphabet.spanishId })
    }

    @Test("every Spanish word is a 3–4 letter lowercase word")
    func everySpanishWordIsAShortLowercaseWord() {
        for word in Word.curatedSpanish {
            #expect((3...4).contains(word.text.count), "\(word.text) is not 3–4 letters")
            #expect(word.text == word.text.lowercased(), "\(word.text) is not lowercase")
        }
    }

    @Test("the Spanish words between them use each of ñ, á, é, í, ó and ú")
    func spanishWordsCoverSpecialLetters() {
        let characters = Set(Word.curatedSpanish.flatMap(\.characters))
        for special: Character in ["ñ", "á", "é", "í", "ó", "ú"] {
            #expect(characters.contains(special), "no Spanish word uses '\(special)'")
        }
    }

    @Test("Spanish word ids are namespaced by alphabet, so they never collide with another list's")
    func spanishWordIdsAreNamespaced() {
        for word in Word.curatedSpanish {
            #expect(word.id == DeterministicID.uuid(name: "word.\(Alphabet.spanishId).\(word.text)"))
        }
    }

    @Test("fetchAll includes the Spanish words")
    func fetchAllIncludesSpanishWords() throws {
        let words = try repository.fetchAll().toBlocking().single()
        #expect(words.filter { $0.alphabetId == Alphabet.spanishId }.count == Word.curatedSpanish.count)
    }

    @Test("the Swedish curated list has 26 words, all tagged with the Swedish alphabet id")
    func swedishCuratedListIsComplete() {
        #expect(Word.curatedSwedish.count == 26)
        #expect(Word.curatedSwedish.allSatisfy { $0.alphabetId == Alphabet.swedishId })
    }

    @Test("every Swedish word is a 3–4 letter lowercase word")
    func everySwedishWordIsAShortLowercaseWord() {
        for word in Word.curatedSwedish {
            #expect((3...4).contains(word.text.count), "\(word.text) is not 3–4 letters")
            #expect(word.text == word.text.lowercased(), "\(word.text) is not lowercase")
        }
    }

    @Test("the Swedish words between them use each of å, ä and ö")
    func swedishWordsCoverSpecialLetters() {
        let characters = Set(Word.curatedSwedish.flatMap(\.characters))
        for special: Character in ["å", "ä", "ö"] {
            #expect(characters.contains(special), "no Swedish word uses '\(special)'")
        }
    }

    @Test("Swedish word ids are namespaced by alphabet, so they never collide with another list's")
    func swedishWordIdsAreNamespaced() {
        for word in Word.curatedSwedish {
            #expect(word.id == DeterministicID.uuid(name: "word.\(Alphabet.swedishId).\(word.text)"))
        }
    }

    @Test("fetchAll includes the Swedish words")
    func fetchAllIncludesSwedishWords() throws {
        let words = try repository.fetchAll().toBlocking().single()
        #expect(words.filter { $0.alphabetId == Alphabet.swedishId }.count == Word.curatedSwedish.count)
    }

    @Test("the Croatian curated list has 26 words, all tagged with the Croatian alphabet id")
    func croatianCuratedListIsComplete() {
        #expect(Word.curatedCroatian.count == 26)
        #expect(Word.curatedCroatian.allSatisfy { $0.alphabetId == Alphabet.croatianId })
    }

    @Test("every Croatian word is a 3–4 letter lowercase word")
    func everyCroatianWordIsAShortLowercaseWord() {
        for word in Word.curatedCroatian {
            #expect((3...4).contains(word.text.count), "\(word.text) is not 3–4 letters")
            #expect(word.text == word.text.lowercased(), "\(word.text) is not lowercase")
        }
    }

    @Test("the Croatian words between them use each of č, ć, đ, š and ž")
    func croatianWordsCoverSpecialLetters() {
        let characters = Set(Word.curatedCroatian.flatMap(\.characters))
        for special: Character in ["č", "ć", "đ", "š", "ž"] {
            #expect(characters.contains(special), "no Croatian word uses '\(special)'")
        }
    }

    @Test("no Croatian word contains the digraphs lj/nj/dž, spelled out or as ǉ/ǌ/ǆ")
    func croatianWordsAvoidDigraphs() {
        for word in Word.curatedCroatian {
            for digraph in ["lj", "nj", "dž", "ǉ", "ǌ", "ǆ"] {
                #expect(!word.text.contains(digraph), "\(word.text) contains the digraph '\(digraph)'")
            }
        }
    }

    @Test("Croatian word ids are namespaced by alphabet, so they never collide with another list's")
    func croatianWordIdsAreNamespaced() {
        for word in Word.curatedCroatian {
            #expect(word.id == DeterministicID.uuid(name: "word.\(Alphabet.croatianId).\(word.text)"))
        }
    }

    @Test("fetchAll includes the Croatian words")
    func fetchAllIncludesCroatianWords() throws {
        let words = try repository.fetchAll().toBlocking().single()
        #expect(words.filter { $0.alphabetId == Alphabet.croatianId }.count == Word.curatedCroatian.count)
    }

    @Test("the French curated list has 26 words, all tagged with the French alphabet id")
    func frenchCuratedListIsComplete() {
        #expect(Word.curatedFrench.count == 26)
        #expect(Word.curatedFrench.allSatisfy { $0.alphabetId == Alphabet.frenchId })
    }

    @Test("every French word is a 3–4 letter lowercase word (œ counting as one letter)")
    func everyFrenchWordIsAShortLowercaseWord() {
        for word in Word.curatedFrench {
            #expect((3...4).contains(word.text.count), "\(word.text) is not 3–4 letters")
            #expect(word.text == word.text.lowercased(), "\(word.text) is not lowercase")
        }
    }

    @Test("the French words between them use each of é, è, ê, â, î, ï, ô, û and œ")
    func frenchWordsCoverTheirAccentedLetters() {
        let characters = Set(Word.curatedFrench.flatMap(\.characters))
        for special: Character in ["é", "è", "ê", "â", "î", "ï", "ô", "û", "œ"] {
            #expect(characters.contains(special), "no French word uses '\(special)'")
        }
    }

    @Test("French word ids are namespaced by alphabet, so they never collide with another list's")
    func frenchWordIdsAreNamespaced() {
        for word in Word.curatedFrench {
            #expect(word.id == DeterministicID.uuid(name: "word.\(Alphabet.frenchId).\(word.text)"))
        }
    }

    @Test("fetchAll includes the French words")
    func fetchAllIncludesFrenchWords() throws {
        let words = try repository.fetchAll().toBlocking().single()
        #expect(words.filter { $0.alphabetId == Alphabet.frenchId }.count == Word.curatedFrench.count)
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
