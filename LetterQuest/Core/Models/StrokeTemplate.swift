import Foundation
import CoreGraphics

struct StrokeTemplate: Identifiable, Equatable {
    let id: UUID
    let strokeIndex: Int
    let points: [CGPoint]
    let direction: StrokeDirection

    enum StrokeDirection: Equatable {
        case leftToRight
        case rightToLeft
        case topToBottom
        case bottomToTop
        case diagonal(angle: Double)
        case curved
    }
}

// MARK: - Template Factory

extension StrokeTemplate {
    static func templates(for character: Character) -> [StrokeTemplate] {
        switch character {
        case "A":
            return [
                StrokeTemplate(id: UUID(), strokeIndex: 0, points: diagonalDownRight, direction: .diagonal(angle: 45)),
                StrokeTemplate(id: UUID(), strokeIndex: 1, points: diagonalDownLeft, direction: .diagonal(angle: -45)),
                StrokeTemplate(id: UUID(), strokeIndex: 2, points: crossbar, direction: .leftToRight)
            ]
        case "B":
            return [
                StrokeTemplate(id: UUID(), strokeIndex: 0, points: verticalStroke, direction: .topToBottom),
                StrokeTemplate(id: UUID(), strokeIndex: 1, points: doubleBump, direction: .curved)
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
                StrokeTemplate(id: UUID(), strokeIndex: 0, points: verticalStroke, direction: .topToBottom),
                StrokeTemplate(id: UUID(), strokeIndex: 1, points: shortHorizontalTop, direction: .leftToRight),
                StrokeTemplate(id: UUID(), strokeIndex: 2, points: shortHorizontalMid, direction: .leftToRight),
                StrokeTemplate(id: UUID(), strokeIndex: 3, points: shortHorizontalBottom, direction: .leftToRight)
            ]
        case "F":
            return [
                StrokeTemplate(id: UUID(), strokeIndex: 0, points: verticalStroke, direction: .topToBottom),
                StrokeTemplate(id: UUID(), strokeIndex: 1, points: shortHorizontalTop, direction: .leftToRight),
                StrokeTemplate(id: UUID(), strokeIndex: 2, points: shortHorizontalMid, direction: .leftToRight)
            ]
        case "I":
            return [
                StrokeTemplate(id: UUID(), strokeIndex: 0, points: verticalStroke, direction: .topToBottom)
            ]
        case "L":
            return [
                StrokeTemplate(id: UUID(), strokeIndex: 0, points: verticalStroke, direction: .topToBottom),
                StrokeTemplate(id: UUID(), strokeIndex: 1, points: shortHorizontalBottom, direction: .leftToRight)
            ]
        case "O":
            return [
                StrokeTemplate(id: UUID(), strokeIndex: 0, points: fullCircle, direction: .curved)
            ]
        case "T":
            return [
                StrokeTemplate(id: UUID(), strokeIndex: 0, points: horizontalStroke, direction: .leftToRight),
                StrokeTemplate(id: UUID(), strokeIndex: 1, points: verticalStroke, direction: .topToBottom)
            ]
        case "V":
            return [
                StrokeTemplate(id: UUID(), strokeIndex: 0, points: diagonalDownRight, direction: .diagonal(angle: 45)),
                StrokeTemplate(id: UUID(), strokeIndex: 1, points: diagonalUpRight, direction: .diagonal(angle: -45))
            ]
        default:
            return [
                StrokeTemplate(id: UUID(), strokeIndex: 0, points: verticalStroke, direction: .topToBottom)
            ]
        }
    }
}

// MARK: - Reference Paths (normalized 0–1 coordinate space)

private extension StrokeTemplate {
    static let verticalStroke: [CGPoint] = stride(from: 0.0, through: 1.0, by: 0.1)
        .map { CGPoint(x: 0.5, y: $0) }

    static let horizontalStroke: [CGPoint] = stride(from: 0.0, through: 1.0, by: 0.1)
        .map { CGPoint(x: $0, y: 0.5) }

    static let crossbar: [CGPoint] = stride(from: 0.2, through: 0.8, by: 0.1)
        .map { CGPoint(x: $0, y: 0.5) }

    static let shortHorizontalTop: [CGPoint] = stride(from: 0.0, through: 0.8, by: 0.1)
        .map { CGPoint(x: $0, y: 0.0) }

    static let shortHorizontalMid: [CGPoint] = stride(from: 0.0, through: 0.7, by: 0.1)
        .map { CGPoint(x: $0, y: 0.5) }

    static let shortHorizontalBottom: [CGPoint] = stride(from: 0.0, through: 0.8, by: 0.1)
        .map { CGPoint(x: $0, y: 1.0) }

    static let diagonalDownRight: [CGPoint] = stride(from: 0.0, through: 1.0, by: 0.1)
        .map { t in CGPoint(x: 0.5 + t * 0.5, y: t) }

    static let diagonalDownLeft: [CGPoint] = stride(from: 0.0, through: 1.0, by: 0.1)
        .map { t in CGPoint(x: 0.5 - t * 0.5, y: t) }

    static let diagonalUpRight: [CGPoint] = stride(from: 0.0, through: 1.0, by: 0.1)
        .map { t in CGPoint(x: 0.5 + t * 0.5, y: 1.0 - t) }

    static let fullCircle: [CGPoint] = stride(from: 0.0, through: 2.0 * .pi, by: .pi / 10)
        .map { angle in CGPoint(x: 0.5 + 0.45 * cos(angle), y: 0.5 + 0.45 * sin(angle)) }

    static let openCurveLeft: [CGPoint] = stride(from: -0.6 * .pi, through: 0.6 * .pi, by: .pi / 10)
        .map { angle in CGPoint(x: 0.5 + 0.45 * cos(angle + .pi), y: 0.5 + 0.45 * sin(angle)) }

    static let doubleBump: [CGPoint] = stride(from: 0.0, through: 1.0, by: 0.05)
        .map { t in
            let bump = t < 0.5
                ? CGPoint(x: t * 2.0, y: 0.25 - 0.25 * sin(t * 2.0 * .pi))
                : CGPoint(x: (t - 0.5) * 2.0, y: 0.75 - 0.25 * sin((t - 0.5) * 2.0 * .pi))
            return bump
        }

    static let largeBumpRight: [CGPoint] = stride(from: -.pi / 2, through: .pi / 2, by: .pi / 10)
        .map { angle in CGPoint(x: 0.5 + 0.45 * cos(angle), y: 0.5 + 0.45 * sin(angle)) }
}
