import Foundation

/// A simple three-letter word the child traces letter by letter in word-practice mode.
///
/// Word mode unlocks once the child has completed both the uppercase and lowercase
/// alphabets, so every character in `text` is guaranteed to exist in
/// `Letter.lowercaseAlphabet`.
struct Word: WordProtocol, Equatable, Identifiable {

    let id: UUID
    let text: String

    /// The word's letters in order, used to drive the per-letter practice sequence.
    var characters: [Character] { Array(text) }
}

// MARK: - Curated word list

extension Word {
    /// A curated list of simple consonant-vowel-consonant (CVC) words, seeded with
    /// stable ids at compile time. Every character is covered by `Letter.lowercaseAlphabet`.
    static let curated: [Word] = [
        "cat", "dog", "sun", "hat", "pig", "run", "bed", "cup", "box", "red",
        "big", "hot", "wet", "top", "mop", "bag", "log", "mud", "net", "pen",
        "van", "zip", "jam", "fox"
    ].map { Word(id: UUID(), text: $0) }
}
