import Foundation

/// A simple three-letter word the child traces letter by letter in word-practice mode.
///
/// Word mode unlocks once the child has completed both the uppercase and lowercase
/// forms of `alphabetId`'s alphabet, so every character in `text` is guaranteed to
/// exist in that alphabet's lowercase letters.
struct Word: WordProtocol, Equatable, Identifiable {

    let id: UUID
    let text: String
    let alphabetId: String

    /// The word's letters in order, used to drive the per-letter practice sequence.
    var characters: [Character] { Array(text) }
}

// MARK: - Curated word lists

extension Word {
    /// A curated list of simple consonant-vowel-consonant (CVC) English words, seeded
    /// with stable ids at compile time. Every character is covered by
    /// `Letter.lowercaseAlphabet`.
    static let curatedLatin: [Word] = [
        "cat", "dog", "sun", "hat", "pig", "run", "bed", "cup", "box", "red",
        "big", "hot", "wet", "top", "mop", "bag", "log", "mud", "net", "pen",
        "van", "zip", "jam", "fox"
    ].map { Word(id: DeterministicID.uuid(name: "word.\($0)"), text: $0, alphabetId: Alphabet.latinId) }

    /// A curated list of simple three-letter Serbian nouns, seeded with stable ids
    /// at compile time. Every character is covered by `Alphabet.cyrillicSr`'s
    /// lowercase letters.
    static let curatedCyrillicSr: [Word] = [
        "пас", "мак", "сат", "нос", "лав", "рак", "сир", "зец", "јеж", "кит",
        "вук", "миш", "дан", "сто", "под", "зуб", "бор", "рог", "лук", "дим",
        "зид", "пут", "мед", "лед", "сок", "око"
    ].map { Word(id: DeterministicID.uuid(name: "word.\($0)"), text: $0, alphabetId: Alphabet.cyrillicSrId) }

    /// Every curated word across every alphabet. `WordRepository` serves this
    /// combined list; per-alphabet filtering happens in the ViewModel layer,
    /// mirroring how `LetterRepository.fetchAll()` combines every installed
    /// alphabet's letters.
    static let curated: [Word] = curatedLatin + curatedCyrillicSr
}
