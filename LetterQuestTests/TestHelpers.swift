import Foundation
import CoreGraphics
import PencilKit
@testable import LetterQuest

// MARK: - PKStroke construction
//
// These helpers expose `PKDrawing`'s programmatic API to test code so each
// scoring component can be exercised with deterministic input. They live in a
// separate file (rather than being copied into each test file) because both
// `ShapeAnalyzerTests` and `SmoothnessAnalyzerTests` need to vary point counts
// and timing independently.

/// Builds a `PKStroke` from a list of `CGPoint`s with evenly-spaced timestamps.
///
/// - Parameters:
///   - points: Raw control points in canvas coordinates.
///   - dt: Time gap between consecutive samples. Default `0.01s` makes
///     `SmoothnessAnalyzer`'s speed calculations finite without saturating.
@inlinable
func makeStroke(points: [CGPoint], dt: TimeInterval = 0.01) -> PKStroke {
    let strokePoints = points.enumerated().map { i, pt in
        PKStrokePoint(
            location: pt,
            timeOffset: TimeInterval(i) * dt,
            size: CGSize(width: 5, height: 5),
            opacity: 1,
            force: 1,
            azimuth: 0,
            altitude: .pi / 2
        )
    }
    let path = PKStrokePath(controlPoints: strokePoints, creationDate: Date())
    return PKStroke(ink: PKInk(.pen), path: path)
}

/// Builds a single straight-line `PKStroke` sampled at `samples + 1` points
/// between `start` and `end`. Useful for shape and proportion tests where you
/// want a known bounding box and direction.
func makeLineStroke(
    from start: CGPoint,
    to end: CGPoint,
    samples: Int = 20,
    dt: TimeInterval = 0.01
) -> PKStroke {
    let points = (0...samples).map { i -> CGPoint in
        let t = Double(i) / Double(samples)
        return CGPoint(
            x: start.x + (end.x - start.x) * t,
            y: start.y + (end.y - start.y) * t
        )
    }
    return makeStroke(points: points, dt: dt)
}

/// Rasterises every `StrokeTemplate` polyline into `PKStroke`s scaled to fill
/// `canvasSize`. Used by DTW and smoothness tests that are not position-sensitive.
func makeStrokes(matching templates: [StrokeTemplate], in canvasSize: CGSize) -> [PKStroke] {
    templates.map { template in
        let scaled = template.points.map {
            CGPoint(x: $0.x * canvasSize.width, y: $0.y * canvasSize.height)
        }
        return makeStroke(points: scaled)
    }
}

/// Rasterises every `StrokeTemplate` polyline into `PKStroke`s placed inside
/// the writing zone for `character`, matching exactly where `StrokeGuideOverlay`
/// and `ShapeAnalyzer` expect the ink to land.
///
/// Use this instead of `makeStrokes(matching:in:)` for `ShapeAnalyzerTests`
/// so that "perfect" test drawings match the template's canvas-space position.
func makeStrokesInZone(matching templates: [StrokeTemplate],
                       for character: Character,
                       in canvasSize: CGSize) -> [PKStroke] {
    let zone = testWritingZone(canvasSize: canvasSize, character: character)
    return templates.map { template in
        let pts = template.points.map {
            CGPoint(x: zone.minX + $0.x * zone.width,
                    y: zone.minY + $0.y * zone.height)
        }
        return makeStroke(points: pts)
    }
}

/// Writing zone calculation — mirrors `ShapeAnalyzer.writingZone` and
/// `StrokeGuideOverlay.writingZone` exactly.
func testWritingZone(canvasSize: CGSize, character: Character) -> CGRect {
    let ascenderY  = canvasSize.height * 0.20
    let xHeightY   = canvasSize.height * 0.45
    let baselineY  = canvasSize.height * 0.70
    let descenderY = canvasSize.height * 0.85

    let top: CGFloat
    let bottom: CGFloat
    switch character {
    case "b", "d", "f", "h", "k", "l", "t":
        top = ascenderY;  bottom = baselineY
    case "g", "j", "p", "q", "y":
        top = ascenderY;  bottom = descenderY
    default:
        if character.isUppercase || character.isNumber {
            top = ascenderY; bottom = baselineY
        } else {
            top = xHeightY; bottom = baselineY
        }
    }

    let height = bottom - top
    let width  = height
    let x      = (canvasSize.width - width) / 2
    return CGRect(x: x, y: top, width: width, height: height)
}
