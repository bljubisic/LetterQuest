import Testing
import Foundation
import RxSwift
import RxBlocking
@testable import LetterQuest

struct LetterRepositoryTests {

    private let repository = LetterRepository()

    // MARK: - fetchAll

    @Test("fetchAll returns all 52 letters (26 upper + 26 lower)")
    func fetchAllReturns52Letters() throws {
        let letters = try repository.fetchAll().toBlocking().single()
        #expect(letters.count == 52)
    }

    @Test("fetchAll returns exactly 26 uppercase letters")
    func fetchAllReturns26UppercaseLetters() throws {
        let letters = try repository.fetchAll().toBlocking().single()
        let uppercase = letters.filter { $0.letterCase == .upper }
        #expect(uppercase.count == 26)
    }

    @Test("fetchAll returns exactly 26 lowercase letters")
    func fetchAllReturns26LowercaseLetters() throws {
        let letters = try repository.fetchAll().toBlocking().single()
        let lowercase = letters.filter { $0.letterCase == .lower }
        #expect(lowercase.count == 26)
    }

    @Test("fetchAll uppercase letters cover A–Z")
    func fetchAllUppercaseCoversAlphabet() throws {
        let letters = try repository.fetchAll().toBlocking().single()
        let chars = Set(letters.filter { $0.letterCase == .upper }.map(\.character))
        for char in "ABCDEFGHIJKLMNOPQRSTUVWXYZ" {
            #expect(chars.contains(char), "Missing uppercase letter: \(char)")
        }
    }

    @Test("fetchAll lowercase letters cover a–z")
    func fetchAllLowercaseCoversAlphabet() throws {
        let letters = try repository.fetchAll().toBlocking().single()
        let chars = Set(letters.filter { $0.letterCase == .lower }.map(\.character))
        for char in "abcdefghijklmnopqrstuvwxyz" {
            #expect(chars.contains(char), "Missing lowercase letter: \(char)")
        }
    }

    @Test("fetchAll returns uppercase A–Z before lowercase a–z")
    func fetchAllUppercaseComesFirst() throws {
        let letters = try repository.fetchAll().toBlocking().single()
        let upperChars = Array(letters.prefix(26).map(\.character))
        let lowerChars = Array(letters.suffix(26).map(\.character))
        #expect(upperChars == Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ"))
        #expect(lowerChars == Array("abcdefghijklmnopqrstuvwxyz"))
    }

    @Test("fetchAll letters each have at least one stroke template")
    func fetchAllLettersHaveTemplates() throws {
        let letters = try repository.fetchAll().toBlocking().single()
        for letter in letters {
            #expect(!letter.strokeTemplates.isEmpty, "Letter \(letter.character) has no stroke templates")
        }
    }

    @Test("fetchAll assigns the correct difficulty tiers to uppercase letters")
    func fetchAllUppercaseDifficultyTiersAreCorrect() throws {
        let letters = try repository.fetchAll().toBlocking().single()
        let uppercase = letters.filter { $0.letterCase == .upper }
        for letter in uppercase.prefix(5) {
            #expect(letter.difficulty == .easy, "Expected easy for \(letter.character)")
        }
        for letter in uppercase[5..<15] {
            #expect(letter.difficulty == .medium, "Expected medium for \(letter.character)")
        }
        for letter in uppercase[15...] {
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

    @Test("fetch(by:) works for all 52 letters")
    func fetchByIdWorksForAllLetters() throws {
        let letters = try repository.fetchAll().toBlocking().single()
        for letter in letters {
            let fetched = try repository.fetch(by: letter.id).toBlocking().single()
            #expect(fetched?.character == letter.character)
        }
    }

    // MARK: - fetchNext

    @Test("fetchNext returns the next uppercase letter within the uppercase set")
    func fetchNextAdvancesWithinUppercase() throws {
        let a = Letter.alphabet[0]
        let b = Letter.alphabet[1]
        let next = try repository.fetchNext(after: a.id).toBlocking().single()
        #expect(next?.id == b.id)
    }

    @Test("fetchNext returns nil after the last uppercase letter (does not cross to lowercase)")
    func fetchNextReturnsNilAfterZ() throws {
        let z = Letter.alphabet[25]
        let next = try repository.fetchNext(after: z.id).toBlocking().single()
        #expect(next == nil)
    }

    @Test("fetchNext returns the next lowercase letter within the lowercase set")
    func fetchNextAdvancesWithinLowercase() throws {
        let a = Letter.lowercaseAlphabet[0]
        let b = Letter.lowercaseAlphabet[1]
        let next = try repository.fetchNext(after: a.id).toBlocking().single()
        #expect(next?.id == b.id)
    }

    @Test("fetchNext returns nil after the last lowercase letter")
    func fetchNextReturnsNilAfterZ_lower() throws {
        let z = Letter.lowercaseAlphabet[25]
        let next = try repository.fetchNext(after: z.id).toBlocking().single()
        #expect(next == nil)
    }

    @Test("fetchNext returns nil for an unknown id")
    func fetchNextReturnsNilForUnknownId() throws {
        let result = try repository.fetchNext(after: UUID()).toBlocking().single()
        #expect(result == nil)
    }

    // MARK: - templateImageName convention

    @Test("uppercase letters follow the template_<CHAR> convention")
    func uppercaseTemplateImageNamesFollowConvention() throws {
        let letters = try repository.fetchAll().toBlocking().single()
        for letter in letters.filter({ $0.letterCase == .upper }) {
            if let name = letter.templateImageName {
                #expect(
                    name == "template_\(letter.character)",
                    "Uppercase \(letter.character) has unexpected templateImageName: \(name)"
                )
            }
        }
    }

    @Test("lowercase letters follow the template_lc_<char> convention")
    func lowercaseTemplateImageNamesFollowConvention() throws {
        let letters = try repository.fetchAll().toBlocking().single()
        for letter in letters.filter({ $0.letterCase == .lower }) {
            if let name = letter.templateImageName {
                #expect(
                    name == "template_lc_\(letter.character)",
                    "Lowercase \(letter.character) has unexpected templateImageName: \(name)"
                )
            }
        }
    }
}

// MARK: - Multi-alphabet resolution

private struct MockAlphabetRepository: AlphabetRepositoryProtocol {
    let alphabets: [Alphabet]
    func fetchAvailable() -> Single<[Alphabet]> { .just(alphabets) }
    func fetchInstalled() -> Single<[Alphabet]> { .just(alphabets) }
}

struct LetterRepositoryMultiAlphabetTests {

    private let fakeAlphabetA = Alphabet(
        id: "fake-a",
        displayName: "Fake A",
        nativeName: "Fake A",
        scriptCode: "Zzzz",
        localeIdentifier: "und",
        isFree: true,
        letters: [
            Letter(
                id: DeterministicID.uuid(name: "letter.fake-a.upper.X"),
                character: "X",
                strokeTemplates: StrokeTemplate.templates(for: "X"),
                difficulty: .easy,
                templateImageName: nil,
                letterCase: .upper,
                alphabetId: "fake-a"
            )
        ]
    )

    private let fakeAlphabetB = Alphabet(
        id: "fake-b",
        displayName: "Fake B",
        nativeName: "Fake B",
        scriptCode: "Zzzz",
        localeIdentifier: "und",
        isFree: true,
        letters: [
            Letter(
                id: DeterministicID.uuid(name: "letter.fake-b.upper.X"),
                character: "X",
                strokeTemplates: StrokeTemplate.templates(for: "X"),
                difficulty: .easy,
                templateImageName: nil,
                letterCase: .upper,
                alphabetId: "fake-b"
            )
        ]
    )

    @Test("fetchAll merges letters from every installed alphabet")
    func fetchAllMergesInstalledAlphabets() throws {
        let repository = LetterRepository(alphabetRepository: MockAlphabetRepository(alphabets: [fakeAlphabetA, fakeAlphabetB]))
        let letters = try repository.fetchAll().toBlocking().single()
        #expect(letters.count == 2)
        #expect(Set(letters.map(\.alphabetId)) == ["fake-a", "fake-b"])
    }

    @Test("two alphabets' same character produces two distinct, non-colliding ids")
    func sameCharacterDifferentAlphabetsDoNotCollide() throws {
        let repository = LetterRepository(alphabetRepository: MockAlphabetRepository(alphabets: [fakeAlphabetA, fakeAlphabetB]))
        let letters = try repository.fetchAll().toBlocking().single()
        let ids = Set(letters.map(\.id))
        #expect(ids.count == 2, "both letters are the character 'X' but belong to different alphabets, so their ids must differ")
    }

    @Test("fetch(by:) resolves a letter belonging to a non-default installed alphabet")
    func fetchByIdResolvesAcrossAlphabets() throws {
        let repository = LetterRepository(alphabetRepository: MockAlphabetRepository(alphabets: [fakeAlphabetA, fakeAlphabetB]))
        let target = fakeAlphabetB.letters[0]
        let fetched = try repository.fetch(by: target.id).toBlocking().single()
        #expect(fetched?.alphabetId == "fake-b")
    }

    @Test("an alphabet the repository doesn't report as installed contributes no letters")
    func uninstalledAlphabetContributesNoLetters() throws {
        let repository = LetterRepository(alphabetRepository: MockAlphabetRepository(alphabets: [fakeAlphabetA]))
        let letters = try repository.fetchAll().toBlocking().single()
        #expect(letters.allSatisfy { $0.alphabetId == "fake-a" })
    }
}
