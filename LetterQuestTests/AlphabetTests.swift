import Testing
import Foundation
@testable import LetterQuest

struct AlphabetLatinTests {

    @Test("Alphabet.latin has 52 letters (26 upper + 26 lower)")
    func latinHas52Letters() {
        #expect(Alphabet.latin.letters.count == 52)
    }

    @Test("Alphabet.latin is free and correctly identified")
    func latinMetadataIsCorrect() {
        let alphabet = Alphabet.latin
        #expect(alphabet.id == "latin")
        #expect(alphabet.isFree == true)
        #expect(alphabet.scriptCode == "Latn")
        #expect(alphabet.localeIdentifier == "en")
    }

    @Test("every letter in Alphabet.latin is stamped with alphabetId \"latin\"")
    func everyLetterHasLatinAlphabetId() {
        for letter in Alphabet.latin.letters {
            #expect(letter.alphabetId == "latin")
        }
    }

    @Test("every letter's id is unique")
    func everyLetterHasUniqueId() {
        let ids = Alphabet.latin.letters.map(\.id)
        #expect(Set(ids).count == ids.count)
    }

    @Test("a letter's id is a pure, deterministic function of its identity")
    func letterIdIsDeterministic() {
        // Regression test for the bug this issue's architecture fixes: `Letter.id`
        // used to be `UUID()`, regenerated randomly every app launch, so a
        // `ChildProgress` saved in one session could never match a `Letter` in
        // the next. Re-deriving the expected id via `DeterministicID` directly
        // (rather than reading it off `Alphabet.latin`, which is only built once
        // per process) proves the id would be identical across separate launches.
        guard let a = Alphabet.latin.letters.first(where: { $0.character == "A" && $0.letterCase == .upper }) else {
            Issue.record("expected an uppercase 'A' in Alphabet.latin")
            return
        }
        let expected = DeterministicID.uuid(name: "letter.latin.upper.A")
        #expect(a.id == expected)
    }
}
