import Testing
import Foundation
import RxSwift
import RxBlocking
@testable import LetterQuest

struct CyrillicAlphabetTests {

    @Test("Alphabet.cyrillicSr has 60 letters (30 upper + 30 lower)")
    func cyrillicSrHas60Letters() {
        #expect(Alphabet.cyrillicSr.letters.count == 60)
    }

    @Test("Alphabet.cyrillicSr is a paid pack, correctly identified")
    func cyrillicSrMetadataIsCorrect() {
        let alphabet = Alphabet.cyrillicSr
        #expect(alphabet.id == "cyrillic-sr")
        #expect(alphabet.isFree == false)
        #expect(alphabet.scriptCode == "Cyrl")
        #expect(alphabet.localeIdentifier == "sr")
    }

    @Test("Alphabet.cyrillicSr is wired to the StoreKit product from issue #37")
    func cyrillicSrHasCorrectProductId() {
        #expect(Alphabet.cyrillicSr.productId == "com.persukibo.letterquest.alphabet.cyrillic_sr")
    }

    @Test("every letter in Alphabet.cyrillicSr is stamped with alphabetId \"cyrillic-sr\"")
    func everyLetterHasCyrillicAlphabetId() {
        for letter in Alphabet.cyrillicSr.letters {
            #expect(letter.alphabetId == "cyrillic-sr")
        }
    }

    @Test("every letter's id is unique")
    func everyLetterHasUniqueId() {
        let ids = Alphabet.cyrillicSr.letters.map(\.id)
        #expect(Set(ids).count == ids.count)
    }

    @Test("no id collides with a Latin letter's id")
    func noIdCollisionWithLatin() {
        let cyrillicIds = Set(Alphabet.cyrillicSr.letters.map(\.id))
        let latinIds = Set(Alphabet.latin.letters.map(\.id))
        #expect(cyrillicIds.isDisjoint(with: latinIds))
    }

    @Test("a letter's id is a pure, deterministic function of its identity")
    func letterIdIsDeterministic() {
        guard let a = Alphabet.cyrillicSr.letters.first(where: { $0.character == "А" && $0.letterCase == .upper }) else {
            Issue.record("expected an uppercase 'А' in Alphabet.cyrillicSr")
            return
        }
        let expected = DeterministicID.uuid(name: "letter.cyrillic-sr.upper.А")
        #expect(a.id == expected)
    }

    @Test("difficulty tiers follow the same positional banding as LatinAlphabet")
    func difficultyTiersArePositional() {
        let upper = Alphabet.cyrillicSr.letters.filter { $0.letterCase == .upper }
        #expect(upper.count == 30)
        for letter in upper.prefix(5) {
            #expect(letter.difficulty == .easy)
        }
        for letter in upper[5..<15] {
            #expect(letter.difficulty == .medium)
        }
        for letter in upper[15...] {
            #expect(letter.difficulty == .hard)
        }
    }

    @Test("Alphabet.cyrillicSr is included in AlphabetRepository's default catalogue")
    func repositoryIncludesCyrillicSr() throws {
        let repository = AlphabetRepository()
        let available = try repository.fetchAvailable().toBlocking().single()
        #expect(available.contains { $0.id == "cyrillic-sr" })
    }
}
