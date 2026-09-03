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
    /// The full Latin uppercase alphabet, seeded with stroke templates and
    /// difficulty tiers. Letters A–E are easy, F–O medium, P–Z hard.
    static let alphabet: [Letter] = "ABCDEFGHIJKLMNOPQRSTUVWXYZ".enumerated().map { index, char in
        Letter(
            id: UUID(),
            character: char,
            strokeTemplates: StrokeTemplate.templates(for: char),
            difficulty: index < 5 ? .easy : index < 15 ? .medium : .hard,
            templateImageName: "template_\(char)",
            letterCase: .upper
        )
    }

    /// The full Latin lowercase alphabet. Letters a–e are easy, f–o medium, p–z hard.
    /// Unlocked as a group when the child passes all 26 uppercase letters.
    static let lowercaseAlphabet: [Letter] = "abcdefghijklmnopqrstuvwxyz".enumerated().map { index, char in
        Letter(
            id: UUID(),
            character: char,
            strokeTemplates: StrokeTemplate.templates(for: char),
            difficulty: index < 5 ? .easy : index < 15 ? .medium : .hard,
            templateImageName: "template_lc_\(char)",  // prefix avoids case-collision with uppercase assets on macOS HFS+/APFS
            letterCase: .lower
        )
    }
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
                letterCase: whole.letterCase
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
                letterCase: whole.letterCase
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
                letterCase: whole.letterCase
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
                letterCase: value
            )
        }
    )
}
