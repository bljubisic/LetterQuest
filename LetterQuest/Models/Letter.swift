import Foundation
import UIKit

/// A single letter in the learning alphabet.
///
/// All properties are read-only. To produce a modified copy, use the static
/// `Lens` values defined in the extension below:
/// ```swift
/// let updated = Letter.lensStrokeTemplates.over(letter) { $0 + [newTemplate] }
/// ```
struct Letter: LetterProtocol, Equatable, Identifiable {

    let id: UUID
    let character: Character
    let strokeTemplates: [StrokeTemplate]
    let difficulty: LetterDifficulty
    let templateImageName: String?
    let letterCase: LetterCase
    let alphabetId: String

    /// Decodes the reference bitmap from the asset catalogue on demand.
    /// Returns `nil` when no asset has been added yet.
    var templateImage: CGImage? {
        guard let name = templateImageName else { return nil }
        return UIImage(named: name)?.cgImage
    }

    static func == (lhs: Letter, rhs: Letter) -> Bool { lhs.id == rhs.id }
}

// MARK: - Alphabet seed data

extension Letter {
    /// The built-in Latin uppercase alphabet. Kept for convenience and to
    /// avoid touching every existing call site — equivalent to
    /// `Alphabet.latin.letters.filter { $0.letterCase == .upper }`. See
    /// `Alphabets/LatinAlphabet.swift` for how it's actually built.
    static let alphabet: [Letter] = Alphabet.latin.letters.filter { $0.letterCase == .upper }

    /// The built-in Latin lowercase alphabet. Unlocked as a group when the
    /// child passes all 26 uppercase letters. See `Alphabets/LatinAlphabet.swift`.
    static let lowercaseAlphabet: [Letter] = Alphabet.latin.letters.filter { $0.letterCase == .lower }
}

// MARK: - Lenses

extension Letter {

    /// Focuses on `strokeTemplates`. Use to add or replace reference strokes.
    static let lensStrokeTemplates = Lens<Letter, [StrokeTemplate]>(
        get: { $0.strokeTemplates },
        set: { whole, value in
            Letter(
                id: whole.id,
                character: whole.character,
                strokeTemplates: value,
                difficulty: whole.difficulty,
                templateImageName: whole.templateImageName,
                letterCase: whole.letterCase,
                alphabetId: whole.alphabetId
            )
        }
    )

    /// Focuses on `templateImageName`. Use to swap the reference asset.
    static let lensTemplateImageName = Lens<Letter, String?>(
        get: { $0.templateImageName },
        set: { whole, value in
            Letter(
                id: whole.id,
                character: whole.character,
                strokeTemplates: whole.strokeTemplates,
                difficulty: whole.difficulty,
                templateImageName: value,
                letterCase: whole.letterCase,
                alphabetId: whole.alphabetId
            )
        }
    )

    /// Focuses on `difficulty`. Use to adjust unlock ordering.
    static let lensDifficulty = Lens<Letter, LetterDifficulty>(
        get: { $0.difficulty },
        set: { whole, value in
            Letter(
                id: whole.id,
                character: whole.character,
                strokeTemplates: whole.strokeTemplates,
                difficulty: value,
                templateImageName: whole.templateImageName,
                letterCase: whole.letterCase,
                alphabetId: whole.alphabetId
            )
        }
    )

    /// Focuses on `letterCase`. Use to move a letter between the uppercase and lowercase sets.
    static let lensLetterCase = Lens<Letter, LetterCase>(
        get: { $0.letterCase },
        set: { whole, value in
            Letter(
                id: whole.id,
                character: whole.character,
                strokeTemplates: whole.strokeTemplates,
                difficulty: whole.difficulty,
                templateImageName: whole.templateImageName,
                letterCase: value,
                alphabetId: whole.alphabetId
            )
        }
    )
}
