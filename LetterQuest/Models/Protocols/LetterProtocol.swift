import Foundation
import CoreGraphics

/// The difficulty tier of a letter, used to gate progression.
enum LetterDifficulty: Int, CaseIterable, Codable {
    case easy   = 1
    case medium = 2
    case hard   = 3
}

/// Describes a single letter in the learning alphabet.
///
/// Conforming types are immutable value types; all mutations produce new instances
/// via the lenses defined in `Letter`.
protocol LetterProtocol {
    /// Stable identifier, used as the key in progress tracking.
    var id: UUID { get }

    /// The uppercase character this letter represents (e.g. `"A"`).
    var character: Character { get }

    /// Ordered list of stroke templates the child must reproduce.
    var strokeTemplates: [StrokeTemplate] { get }

    /// How difficult this letter is; controls unlock order.
    var difficulty: LetterDifficulty { get }

    /// Asset name for the reference bitmap used by `ShapeAnalyzer`.
    /// `nil` when no asset has been provided yet (shape scoring falls back to 50).
    var templateImageName: String? { get }

    /// The decoded reference bitmap, or `nil` when the asset is missing.
    var templateImage: CGImage? { get }
}
