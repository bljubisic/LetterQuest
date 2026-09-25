import Foundation

/// A short word the child traces letter by letter in word-practice mode.
///
/// Word mode unlocks once the child has completed both the uppercase and lowercase
/// forms of `alphabetId`'s alphabet, so every character in `text` is guaranteed to
/// exist in that alphabet's letters. Most words are all lowercase; German nouns
/// keep their capital first letter, which is traced with the uppercase `Letter`.
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

    /// A curated list of simple German nouns (3–4 letters), seeded with stable ids
    /// at compile time. German capitalises every noun, so each word keeps its
    /// capital first letter — traced with `Alphabet.german`'s uppercase letter,
    /// the rest in lowercase. Ä/Ö/Ü/ß appear only where the word naturally has them.
    ///
    /// Ids are namespaced by alphabet (`word.german.<text>`), unlike the older
    /// Latin/Cyrillic lists whose ids are kept as-is so saved progress survives:
    /// Latin-script languages share letters, so a bare `word.<text>` id could
    /// collide with another list's word and share its progress.
    static let curatedGerman: [Word] = [
        "Bus", "Eis", "Hut", "Uhr", "Ohr", "Arm", "Bär", "Kuh", "Tür", "Fuß", "Zug", "Rad",
        "Hund", "Ball", "Maus", "Baum", "Haus", "Buch", "Mond", "Hase", "Nase", "Auto",
        "Igel", "Ente", "Käse", "Löwe"
    ].map {
        Word(id: DeterministicID.uuid(name: "word.\(Alphabet.germanId).\($0)"), text: $0, alphabetId: Alphabet.germanId)
    }

    /// A curated list of simple, concrete Spanish words (3–4 letters), seeded with
    /// stable ids at compile time. Spanish nouns are lowercase, so every letter is
    /// traced with `Alphabet.spanish`'s lowercase letters. Between them the words
    /// use ñ, á, é, í, ó and ú; ü is left out as short words with it are rare.
    /// Ids are namespaced by alphabet (`word.spanish.<text>`), as with German.
    static let curatedSpanish: [Word] = [
        "sol", "pan", "mar", "luz", "pez", "oso", "uva", "ojo",
        "casa", "gato", "pato", "sapo", "lobo", "vaca", "mano", "luna", "nube", "rana", "dedo",
        "niño", "piña", "león", "búho", "sofá", "maíz", "bebé"
    ].map {
        Word(id: DeterministicID.uuid(name: "word.\(Alphabet.spanishId).\($0)"), text: $0, alphabetId: Alphabet.spanishId)
    }

    /// A curated list of simple, concrete Swedish words (3–4 letters), seeded with
    /// stable ids at compile time. Swedish nouns are lowercase, so every letter is
    /// traced with `Alphabet.swedish`'s lowercase letters. Å/ä/ö appear only where
    /// the word naturally has them. Ids are namespaced by alphabet
    /// (`word.swedish.<text>`), so e.g. Swedish "sol" never shares Spanish "sol"'s progress.
    static let curatedSwedish: [Word] = [
        "sol", "hus", "bil", "mus", "bok", "sko", "ost", "apa",
        "katt", "hund", "fisk", "boll", "kaka", "gris", "anka", "bord",
        "båt", "tåg", "gås", "måne", "bär", "räv", "säng", "öga", "snö", "löv"
    ].map {
        Word(id: DeterministicID.uuid(name: "word.\(Alphabet.swedishId).\($0)"), text: $0, alphabetId: Alphabet.swedishId)
    }

    /// A curated list of simple, concrete Croatian/Serbian words (3–4 letters), seeded
    /// with stable ids at compile time. Nouns are lowercase, so every letter is traced
    /// with `Alphabet.croatian`'s lowercase letters; words are shared by Croatian and
    /// Serbian where possible. Č/ć/đ/š/ž appear only where the word naturally has them.
    ///
    /// Words with the digraphs lj/nj/dž are left out: the alphabet stores them as
    /// single code points (ǉ/ǌ/ǆ), so spelling them `l`+`j` would trace them as two
    /// letters, and spelling them `ǉ` would render an odd ligature in the word text.
    /// Ids are namespaced by alphabet (`word.croatian.<text>`), as with German.
    static let curatedCroatian: [Word] = [
        "pas", "sir", "nos", "vuk", "zec", "lav", "kit", "zub",
        "riba", "ruka", "noga", "sova", "koza", "voda", "kapa", "auto",
        "jež", "miš", "puž", "čaj", "noć", "ćuk", "đak", "kuća", "žaba", "šuma"
    ].map {
        Word(id: DeterministicID.uuid(name: "word.\(Alphabet.croatianId).\($0)"), text: $0, alphabetId: Alphabet.croatianId)
    }

    /// A curated list of simple, concrete French nouns (3–4 letters, no articles),
    /// seeded with stable ids at compile time. Nouns are lowercase, so every letter is
    /// traced with `Alphabet.french`'s lowercase letters. Accented letters appear only
    /// where the word naturally has them — à/ç/ù/ë/ÿ/æ don't occur in short concrete
    /// nouns, so they're left out. Œ is a single letter in the alphabet, so "œuf" and
    /// "cœur" trace it as one step. Ids are namespaced by alphabet (`word.french.<text>`),
    /// as with German.
    static let curatedFrench: [Word] = [
        "lit", "nez", "roi", "riz", "sac", "lac", "jus",
        "chat", "loup", "lune", "lion", "ours", "pain", "main",
        "clé", "bébé", "café", "père", "tête", "âne", "île", "maïs", "rôti", "mûre", "œuf", "cœur"
    ].map {
        Word(id: DeterministicID.uuid(name: "word.\(Alphabet.frenchId).\($0)"), text: $0, alphabetId: Alphabet.frenchId)
    }

    /// Every curated word across every alphabet. `WordRepository` serves this
    /// combined list; per-alphabet filtering happens in the ViewModel layer,
    /// mirroring how `LetterRepository.fetchAll()` combines every installed
    /// alphabet's letters.
    static let curated: [Word] = curatedLatin + curatedCyrillicSr + curatedGerman + curatedSpanish + curatedSwedish
        + curatedCroatian + curatedFrench
}
