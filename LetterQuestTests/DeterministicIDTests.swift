import Testing
import Foundation
@testable import LetterQuest

struct DeterministicIDTests {

    @Test("the same name always produces the same UUID")
    func sameNameProducesSameUUID() {
        let first  = DeterministicID.uuid(name: "letter.latin.upper.A")
        let second = DeterministicID.uuid(name: "letter.latin.upper.A")
        #expect(first == second)
    }

    @Test("different names produce different UUIDs")
    func differentNamesProduceDifferentUUIDs() {
        let a = DeterministicID.uuid(name: "letter.latin.upper.A")
        let b = DeterministicID.uuid(name: "letter.latin.upper.B")
        #expect(a != b)
    }

    @Test("the same character in different alphabets produces different UUIDs")
    func sameCharacterDifferentAlphabetProducesDifferentUUIDs() {
        let latin    = DeterministicID.uuid(name: "letter.latin.upper.A")
        let fictional = DeterministicID.uuid(name: "letter.other.upper.A")
        #expect(latin != fictional)
    }

    @Test("the generated UUID has RFC 4122 version 3 and variant bits set")
    func generatedUUIDHasCorrectVersionAndVariant() {
        let uuid = DeterministicID.uuid(name: "letter.latin.upper.A")
        let bytes = uuid.uuid
        #expect((bytes.6 & 0xF0) == 0x30, "version nibble should be 3")
        #expect((bytes.8 & 0xC0) == 0x80, "variant bits should be RFC 4122")
    }
}
