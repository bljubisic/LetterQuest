import Foundation
import CoreGraphics

/// A single reference stroke that defines how one part of a letter should be drawn.
///
/// All properties are read-only. Use the static lenses to produce modified copies:
/// ```swift
/// let adjusted = StrokeTemplate.lensPoints.over(template) { normalise($0) }
/// ```
struct StrokeTemplate: StrokeTemplateProtocol, Equatable {

    let id: UUID
    let strokeIndex: Int
    let points: [CGPoint]
    let direction: StrokeDirection
}

// MARK: - Lenses

extension StrokeTemplate {

    /// Focuses on `points`. Use to update or normalise the reference path.
    static let lensPoints = Lens<StrokeTemplate, [CGPoint]>(
        get: { $0.points },
        set: { whole, value in
            StrokeTemplate(id: whole.id, strokeIndex: whole.strokeIndex, points: value, direction: whole.direction)
        }
    )

    /// Focuses on `direction`. Use to correct an incorrectly classified stroke direction.
    static let lensDirection = Lens<StrokeTemplate, StrokeDirection>(
        get: { $0.direction },
        set: { whole, value in
            StrokeTemplate(id: whole.id, strokeIndex: whole.strokeIndex, points: whole.points, direction: value)
        }
    )
}

// MARK: - Template factory

extension StrokeTemplate {

    /// Returns the ordered stroke templates for a given uppercase character.
    ///
    /// Letters that do not have a hand-authored template yet fall back to a single
    /// top-to-bottom vertical stroke so the scoring pipeline always has something to
    /// compare against.
    ///
    /// - Parameter character: An uppercase ASCII character.
    /// - Returns: An ordered array of reference strokes.
    static func templates(for character: Character) -> [StrokeTemplate] {
        switch character {
        case "A":
            return [
                StrokeTemplate(id: UUID(), strokeIndex: 0, points: diagonalDownRight, direction: .diagonal(angle: 45)),
                StrokeTemplate(id: UUID(), strokeIndex: 1, points: diagonalDownLeft,  direction: .diagonal(angle: -45)),
                StrokeTemplate(id: UUID(), strokeIndex: 2, points: crossbar,          direction: .leftToRight)
            ]
        case "B":
            return [
                StrokeTemplate(id: UUID(), strokeIndex: 0, points: verticalStroke, direction: .topToBottom),
                StrokeTemplate(id: UUID(), strokeIndex: 1, points: doubleBump,     direction: .curved)
            ]
        case "C":
            return [
                StrokeTemplate(id: UUID(), strokeIndex: 0, points: openCurveLeft, direction: .curved)
            ]
        case "D":
            return [
                StrokeTemplate(id: UUID(), strokeIndex: 0, points: verticalStroke, direction: .topToBottom),
                StrokeTemplate(id: UUID(), strokeIndex: 1, points: largeBumpRight, direction: .curved)
            ]
        case "E":
            return [
                StrokeTemplate(id: UUID(), strokeIndex: 0, points: verticalStroke,       direction: .topToBottom),
                StrokeTemplate(id: UUID(), strokeIndex: 1, points: shortHorizontalTop,   direction: .leftToRight),
                StrokeTemplate(id: UUID(), strokeIndex: 2, points: shortHorizontalMid,   direction: .leftToRight),
                StrokeTemplate(id: UUID(), strokeIndex: 3, points: shortHorizontalBottom, direction: .leftToRight)
            ]
        case "F":
            return [
                StrokeTemplate(id: UUID(), strokeIndex: 0, points: verticalStroke,     direction: .topToBottom),
                StrokeTemplate(id: UUID(), strokeIndex: 1, points: shortHorizontalTop, direction: .leftToRight),
                StrokeTemplate(id: UUID(), strokeIndex: 2, points: shortHorizontalMid, direction: .leftToRight)
            ]
        case "I":
            return [
                StrokeTemplate(id: UUID(), strokeIndex: 0, points: verticalStroke, direction: .topToBottom)
            ]
        case "L":
            return [
                StrokeTemplate(id: UUID(), strokeIndex: 0, points: verticalStroke,       direction: .topToBottom),
                StrokeTemplate(id: UUID(), strokeIndex: 1, points: shortHorizontalBottom, direction: .leftToRight)
            ]
        case "O":
            return [
                StrokeTemplate(id: UUID(), strokeIndex: 0, points: fullCircle, direction: .curved)
            ]
        case "T":
            return [
                StrokeTemplate(id: UUID(), strokeIndex: 0, points: horizontalStroke, direction: .leftToRight),
                StrokeTemplate(id: UUID(), strokeIndex: 1, points: verticalStroke,   direction: .topToBottom)
            ]
        case "V":
            return [
                StrokeTemplate(id: UUID(), strokeIndex: 0, points: diagonalDownRight, direction: .diagonal(angle: 45)),
                StrokeTemplate(id: UUID(), strokeIndex: 1, points: diagonalUpRight,   direction: .diagonal(angle: -45))
            ]
        default:
            return [
                StrokeTemplate(id: UUID(), strokeIndex: 0, points: verticalStroke, direction: .topToBottom)
            ]
        }
    }
}

// MARK: - Reference paths (normalised 0–1 coordinate space)

private extension StrokeTemplate {

    /// A straight vertical line from top-centre to bottom-centre.
    static let verticalStroke: [CGPoint] = stride(from: 0.0, through: 1.0, by: 0.1)
        .map { CGPoint(x: 0.5, y: $0) }

    /// A straight horizontal line from left-centre to right-centre.
    static let horizontalStroke: [CGPoint] = stride(from: 0.0, through: 1.0, by: 0.1)
        .map { CGPoint(x: $0, y: 0.5) }

    /// Short horizontal bar spanning the top of the letter area.
    static let shortHorizontalTop: [CGPoint] = stride(from: 0.0, through: 0.8, by: 0.1)
        .map { CGPoint(x: $0, y: 0.05) }

    /// Short horizontal bar at mid-height (x-height).
    static let shortHorizontalMid: [CGPoint] = stride(from: 0.0, through: 0.7, by: 0.1)
        .map { CGPoint(x: $0, y: 0.5) }

    /// Short horizontal bar spanning the baseline area.
    static let shortHorizontalBottom: [CGPoint] = stride(from: 0.0, through: 0.8, by: 0.1)
        .map { CGPoint(x: $0, y: 0.95) }

    /// Horizontal crossbar used in "A", spanning the middle of the letter.
    static let crossbar: [CGPoint] = stride(from: 0.2, through: 0.8, by: 0.1)
        .map { CGPoint(x: $0, y: 0.5) }

    /// Diagonal from top-centre down to bottom-right (used for left leg of "A", right leg of "V").
    static let diagonalDownRight: [CGPoint] = stride(from: 0.0, through: 1.0, by: 0.1)
        .map { t in CGPoint(x: 0.5 + t * 0.5, y: t) }

    /// Diagonal from top-centre down to bottom-left (used for right leg of "A").
    static let diagonalDownLeft: [CGPoint] = stride(from: 0.0, through: 1.0, by: 0.1)
        .map { t in CGPoint(x: 0.5 - t * 0.5, y: t) }

    /// Diagonal from bottom-left up to top-right (used for left leg of "V").
    static let diagonalUpRight: [CGPoint] = stride(from: 0.0, through: 1.0, by: 0.1)
        .map { t in CGPoint(x: 0.5 + t * 0.5, y: 1.0 - t) }

    /// A full circular arc (360°) used for "O".
    static let fullCircle: [CGPoint] = stride(from: 0.0, through: 2.0 * .pi, by: .pi / 10)
        .map { angle in CGPoint(x: 0.5 + 0.45 * cos(angle), y: 0.5 + 0.45 * sin(angle)) }

    /// An open arc (≈ 216°) opening to the right, used for "C".
    static let openCurveLeft: [CGPoint] = stride(from: -0.6 * .pi, through: 0.6 * .pi, by: .pi / 10)
        .map { angle in CGPoint(x: 0.5 + 0.45 * cos(angle + .pi), y: 0.5 + 0.45 * sin(angle)) }

    /// Two bumps stacked vertically, used for the curved stroke of "B".
    static let doubleBump: [CGPoint] = stride(from: 0.0, through: 1.0, by: 0.05)
        .map { t -> CGPoint in
            let localT: Double = t < 0.5 ? t : t - 0.5
            let centreY: Double = t < 0.5 ? 0.25 : 0.75
            let x: Double = localT * 2.0
            let y: Double = centreY - 0.25 * sin(localT * 2.0 * .pi)
            return CGPoint(x: x, y: y)
        }

    /// A right-facing semicircle used for "D".
    static let largeBumpRight: [CGPoint] = stride(from: -.pi / 2, through: .pi / 2, by: .pi / 10)
        .map { angle in CGPoint(x: 0.5 + 0.45 * cos(angle), y: 0.5 + 0.45 * sin(angle)) }
}
