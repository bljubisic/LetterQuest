import Foundation
import CoreGraphics

/// The expected movement direction of a single stroke.
///
/// Used by `DTWMatcher` to award a bonus when the child draws in the correct direction,
/// independently of how well the path shape matches.
enum StrokeDirection: Equatable {
    case leftToRight
    case rightToLeft
    case topToBottom
    case bottomToTop
    /// A straight diagonal stroke at the given angle (degrees from horizontal).
    case diagonal(angle: Double)
    /// Any curved or arc stroke where direction is not axis-aligned.
    case curved
}

/// Describes a single reference stroke inside a letter template.
///
/// Conforming types are immutable; modify them through `StrokeTemplate`'s lenses.
protocol StrokeTemplateProtocol {
    /// Stable identifier.
    var id: UUID { get }

    /// Zero-based position of this stroke within the letter (defines stroke order).
    var strokeIndex: Int { get }

    /// Reference control points in a normalised **0–1** coordinate space.
    /// The DTW matcher normalises the child's actual stroke to the same space before comparing.
    var points: [CGPoint] { get }

    /// The expected overall direction of this stroke.
    var direction: StrokeDirection { get }
}
