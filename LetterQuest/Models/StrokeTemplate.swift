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
    /// All stroke points live in the normalised **0…1** coordinate space, where
    /// `(0, 0)` is the top-left of the letter's bounding box and `(1, 1)` is
    /// the bottom-right. Stroke ordering matches the pedagogical print order
    /// taught to children.
    ///
    /// Unknown characters fall back to a single top-to-bottom vertical so the
    /// scoring pipeline always has something to compare against.
    static func templates(for character: Character) -> [StrokeTemplate] {
        definitions(for: character).enumerated().map { index, def in
            StrokeTemplate(id: UUID(), strokeIndex: index, points: def.points, direction: def.direction)
        }
    }

    // MARK: Internal definition type

    /// A pair of points + direction, used while building each letter's strokes.
    /// Kept private so `StrokeTemplate.init(...)` remains the only public way
    /// to construct a template with a fresh `id` and `strokeIndex`.
    private struct StrokeDef {
        let points: [CGPoint]
        let direction: StrokeDirection
    }

    private static func definitions(for character: Character) -> [StrokeDef] {
        switch character {
        case "A": return aDefinition
        case "B": return bDefinition
        case "C": return cDefinition
        case "D": return dDefinition
        case "E": return eDefinition
        case "F": return fDefinition
        case "G": return gDefinition
        case "H": return hDefinition
        case "I": return iDefinition
        case "J": return jDefinition
        case "K": return kDefinition
        case "L": return lDefinition
        case "M": return mDefinition
        case "N": return nDefinition
        case "O": return oDefinition
        case "P": return pDefinition
        case "Q": return qDefinition
        case "R": return rDefinition
        case "S": return sDefinition
        case "T": return tDefinition
        case "U": return uDefinition
        case "V": return vDefinition
        case "W": return wDefinition
        case "X": return xDefinition
        case "Y": return yDefinition
        case "Z": return zDefinition
        default:
            return [StrokeDef(points: line(from: p(0.5, 0.05), to: p(0.5, 0.95)),
                              direction: .topToBottom)]
        }
    }

    // MARK: - Per-letter definitions
    //
    // Each constant is a tiny script that builds the letter from the geometry
    // primitives below. Coordinates are normalised: x and y both run 0…1,
    // with y growing downward to match screen conventions.

    /// A — right leg, left leg, crossbar.
    private static let aDefinition: [StrokeDef] = [
        StrokeDef(points: line(from: p(0.5, 0.05), to: p(0.95, 0.95)),
                  direction: .diagonal(angle: 45)),
        StrokeDef(points: line(from: p(0.5, 0.05), to: p(0.05, 0.95)),
                  direction: .diagonal(angle: -45)),
        StrokeDef(points: line(from: p(0.2, 0.6),  to: p(0.8, 0.6)),
                  direction: .leftToRight)
    ]

    /// B — left spine, then two right-bulging bumps drawn as a single elliptical
    /// curve. Each bump is a half-ellipse hinged on the spine.
    private static let bDefinition: [StrokeDef] = [
        StrokeDef(points: line(from: p(0.15, 0.05), to: p(0.15, 0.95)),
                  direction: .topToBottom),
        StrokeDef(points:
                    ellipticalArc(center: p(0.15, 0.275), rx: 0.55, ry: 0.225,
                                  from: -.pi / 2, to: .pi / 2)
                  + ellipticalArc(center: p(0.15, 0.725), rx: 0.65, ry: 0.225,
                                  from: -.pi / 2, to: .pi / 2).dropFirst(),
                  direction: .curved)
    ]

    /// C — a ~240° open circular arc that hugs the left side of the letter box,
    /// leaving the right side open. Going from upper-right counter-clockwise
    /// through the leftmost point to lower-right.
    private static let cDefinition: [StrokeDef] = [
        StrokeDef(points: circleArc(center: p(0.5, 0.5), radius: 0.45,
                                    from: -.pi / 3, to: -5 * .pi / 3),
                  direction: .curved)
    ]

    /// D — left spine, then one big right-bulging half-ellipse hinged on the spine.
    private static let dDefinition: [StrokeDef] = [
        StrokeDef(points: line(from: p(0.15, 0.05), to: p(0.15, 0.95)),
                  direction: .topToBottom),
        StrokeDef(points: ellipticalArc(center: p(0.15, 0.5), rx: 0.75, ry: 0.45,
                                        from: -.pi / 2, to: .pi / 2),
                  direction: .curved)
    ]

    /// E — spine then three left-to-right horizontal bars.
    private static let eDefinition: [StrokeDef] = [
        StrokeDef(points: line(from: p(0.15, 0.05), to: p(0.15, 0.95)),
                  direction: .topToBottom),
        StrokeDef(points: line(from: p(0.15, 0.05), to: p(0.85, 0.05)),
                  direction: .leftToRight),
        StrokeDef(points: line(from: p(0.15, 0.5),  to: p(0.7,  0.5)),
                  direction: .leftToRight),
        StrokeDef(points: line(from: p(0.15, 0.95), to: p(0.85, 0.95)),
                  direction: .leftToRight)
    ]

    /// F — spine, top bar, mid bar (no bottom bar).
    private static let fDefinition: [StrokeDef] = [
        StrokeDef(points: line(from: p(0.15, 0.05), to: p(0.15, 0.95)),
                  direction: .topToBottom),
        StrokeDef(points: line(from: p(0.15, 0.05), to: p(0.85, 0.05)),
                  direction: .leftToRight),
        StrokeDef(points: line(from: p(0.15, 0.5),  to: p(0.7,  0.5)),
                  direction: .leftToRight)
    ]

    /// G — C-shaped arc, then a horizontal hook on the right, then a short vertical
    ///     dropping toward where the arc ended.
    private static let gDefinition: [StrokeDef] = [
        StrokeDef(points: circleArc(center: p(0.5, 0.5), radius: 0.45,
                                    from: -.pi / 3, to: -5 * .pi / 3),
                  direction: .curved),
        StrokeDef(points: line(from: p(0.45, 0.55), to: p(0.85, 0.55)),
                  direction: .leftToRight),
        StrokeDef(points: line(from: p(0.85, 0.55), to: p(0.85, 0.85)),
                  direction: .topToBottom)
    ]

    /// H — left vertical, right vertical, crossbar.
    private static let hDefinition: [StrokeDef] = [
        StrokeDef(points: line(from: p(0.15, 0.05), to: p(0.15, 0.95)),
                  direction: .topToBottom),
        StrokeDef(points: line(from: p(0.85, 0.05), to: p(0.85, 0.95)),
                  direction: .topToBottom),
        StrokeDef(points: line(from: p(0.15, 0.5),  to: p(0.85, 0.5)),
                  direction: .leftToRight)
    ]

    /// I — single vertical stroke (no serifs).
    private static let iDefinition: [StrokeDef] = [
        StrokeDef(points: line(from: p(0.5, 0.05), to: p(0.5, 0.95)),
                  direction: .topToBottom)
    ]

    /// J — vertical drop with a curved hook at the bottom-left.
    private static let jDefinition: [StrokeDef] = [
        StrokeDef(points: line(from: p(0.7, 0.05), to: p(0.7, 0.7)),
                  direction: .topToBottom),
        StrokeDef(points: curveThrough(from: p(0.7, 0.7), peak: p(0.45, 0.97), to: p(0.2, 0.85)),
                  direction: .curved)
    ]

    /// K — vertical spine, then upper diagonal in (top-right → mid-spine),
    ///     then lower diagonal out (mid-spine → bottom-right).
    private static let kDefinition: [StrokeDef] = [
        StrokeDef(points: line(from: p(0.15, 0.05), to: p(0.15, 0.95)),
                  direction: .topToBottom),
        StrokeDef(points: line(from: p(0.85, 0.05), to: p(0.15, 0.5)),
                  direction: .diagonal(angle: -45)),
        StrokeDef(points: line(from: p(0.15, 0.5),  to: p(0.85, 0.95)),
                  direction: .diagonal(angle: 45))
    ]

    /// L — spine, then bottom bar.
    private static let lDefinition: [StrokeDef] = [
        StrokeDef(points: line(from: p(0.15, 0.05), to: p(0.15, 0.95)),
                  direction: .topToBottom),
        StrokeDef(points: line(from: p(0.15, 0.95), to: p(0.85, 0.95)),
                  direction: .leftToRight)
    ]

    /// M — left vertical, down-right valley stroke, up-right peak stroke, right vertical.
    private static let mDefinition: [StrokeDef] = [
        StrokeDef(points: line(from: p(0.1, 0.05), to: p(0.1, 0.95)),
                  direction: .topToBottom),
        StrokeDef(points: line(from: p(0.1, 0.05), to: p(0.5, 0.7)),
                  direction: .diagonal(angle: 45)),
        StrokeDef(points: line(from: p(0.5, 0.7),  to: p(0.9, 0.05)),
                  direction: .diagonal(angle: -45)),
        StrokeDef(points: line(from: p(0.9, 0.05), to: p(0.9, 0.95)),
                  direction: .topToBottom)
    ]

    /// N — left vertical, diagonal top-left to bottom-right, right vertical.
    private static let nDefinition: [StrokeDef] = [
        StrokeDef(points: line(from: p(0.15, 0.05), to: p(0.15, 0.95)),
                  direction: .topToBottom),
        StrokeDef(points: line(from: p(0.15, 0.05), to: p(0.85, 0.95)),
                  direction: .diagonal(angle: 45)),
        StrokeDef(points: line(from: p(0.85, 0.05), to: p(0.85, 0.95)),
                  direction: .topToBottom)
    ]

    /// O — full circle, starting at the top and going clockwise.
    private static let oDefinition: [StrokeDef] = [
        StrokeDef(points: circleArc(center: p(0.5, 0.5),
                                    radius: 0.45,
                                    from: -.pi / 2,
                                    to: 3 * .pi / 2),
                  direction: .curved)
    ]

    /// P — spine, then a single top-half loop drawn as a right-bulging
    /// half-ellipse hinged on the upper spine.
    private static let pDefinition: [StrokeDef] = [
        StrokeDef(points: line(from: p(0.15, 0.05), to: p(0.15, 0.95)),
                  direction: .topToBottom),
        StrokeDef(points: ellipticalArc(center: p(0.15, 0.3), rx: 0.6, ry: 0.25,
                                        from: -.pi / 2, to: .pi / 2),
                  direction: .curved)
    ]

    /// Q — circle plus a short diagonal tail at the lower-right.
    private static let qDefinition: [StrokeDef] = [
        StrokeDef(points: circleArc(center: p(0.5, 0.5),
                                    radius: 0.4,
                                    from: -.pi / 2,
                                    to: 3 * .pi / 2),
                  direction: .curved),
        StrokeDef(points: line(from: p(0.6, 0.7), to: p(0.95, 0.98)),
                  direction: .diagonal(angle: 45))
    ]

    /// R — spine, top-loop (right-bulging half-ellipse), then a leg slanting
    /// down-right from where the loop closes back onto the spine.
    private static let rDefinition: [StrokeDef] = [
        StrokeDef(points: line(from: p(0.15, 0.05), to: p(0.15, 0.95)),
                  direction: .topToBottom),
        StrokeDef(points: ellipticalArc(center: p(0.15, 0.3), rx: 0.6, ry: 0.25,
                                        from: -.pi / 2, to: .pi / 2),
                  direction: .curved),
        StrokeDef(points: line(from: p(0.15, 0.55), to: p(0.85, 0.95)),
                  direction: .diagonal(angle: 45))
    ]

    /// S — single S-shaped curve, formed by two bézier halves joined at the middle.
    private static let sDefinition: [StrokeDef] = [
        StrokeDef(points:
                    bezier(p(0.85, 0.1), p(0.05, 0.0), p(0.5, 0.5))
                  + bezier(p(0.5, 0.5),  p(0.95, 1.0), p(0.15, 0.9)).dropFirst(),
                  direction: .curved)
    ]

    /// T — top bar then vertical down from the bar's centre.
    private static let tDefinition: [StrokeDef] = [
        StrokeDef(points: line(from: p(0.1, 0.05), to: p(0.9, 0.05)),
                  direction: .leftToRight),
        StrokeDef(points: line(from: p(0.5, 0.05), to: p(0.5, 0.95)),
                  direction: .topToBottom)
    ]

    /// U — single U-shaped stroke: down the left side, around the bottom, back up.
    private static let uDefinition: [StrokeDef] = [
        StrokeDef(points:
                    line(from: p(0.1, 0.05), to: p(0.1, 0.7), steps: 6)
                  + curveThrough(from: p(0.1, 0.7), peak: p(0.5, 0.97), to: p(0.9, 0.7)).dropFirst()
                  + line(from: p(0.9, 0.7), to: p(0.9, 0.05), steps: 6).dropFirst(),
                  direction: .curved)
    ]

    /// V — two diagonals meeting at the bottom-centre.
    private static let vDefinition: [StrokeDef] = [
        StrokeDef(points: line(from: p(0.1, 0.05), to: p(0.5, 0.95)),
                  direction: .diagonal(angle: 45)),
        StrokeDef(points: line(from: p(0.5, 0.95), to: p(0.9, 0.05)),
                  direction: .diagonal(angle: -45))
    ]

    /// W — four diagonals forming two V-shapes side by side.
    private static let wDefinition: [StrokeDef] = [
        StrokeDef(points: line(from: p(0.05, 0.05), to: p(0.3, 0.95)),
                  direction: .diagonal(angle: 45)),
        StrokeDef(points: line(from: p(0.3, 0.95),  to: p(0.5, 0.4)),
                  direction: .diagonal(angle: -45)),
        StrokeDef(points: line(from: p(0.5, 0.4),   to: p(0.7, 0.95)),
                  direction: .diagonal(angle: 45)),
        StrokeDef(points: line(from: p(0.7, 0.95),  to: p(0.95, 0.05)),
                  direction: .diagonal(angle: -45))
    ]

    /// X — two crossing diagonals.
    private static let xDefinition: [StrokeDef] = [
        StrokeDef(points: line(from: p(0.1, 0.05), to: p(0.9, 0.95)),
                  direction: .diagonal(angle: 45)),
        StrokeDef(points: line(from: p(0.9, 0.05), to: p(0.1, 0.95)),
                  direction: .diagonal(angle: -45))
    ]

    /// Y — left diagonal in, right diagonal back out, vertical drop from the middle.
    private static let yDefinition: [StrokeDef] = [
        StrokeDef(points: line(from: p(0.1, 0.05), to: p(0.5, 0.5)),
                  direction: .diagonal(angle: 45)),
        StrokeDef(points: line(from: p(0.5, 0.5),  to: p(0.9, 0.05)),
                  direction: .diagonal(angle: -45)),
        StrokeDef(points: line(from: p(0.5, 0.5),  to: p(0.5, 0.95)),
                  direction: .topToBottom)
    ]

    /// Z — top bar, diagonal top-right to bottom-left, bottom bar.
    private static let zDefinition: [StrokeDef] = [
        StrokeDef(points: line(from: p(0.1, 0.05), to: p(0.9, 0.05)),
                  direction: .leftToRight),
        StrokeDef(points: line(from: p(0.9, 0.05), to: p(0.1, 0.95)),
                  direction: .diagonal(angle: -45)),
        StrokeDef(points: line(from: p(0.1, 0.95), to: p(0.9, 0.95)),
                  direction: .leftToRight)
    ]
}

// MARK: - Path-building primitives

private extension StrokeTemplate {

    /// Shorthand for constructing a `CGPoint` in the normalised letter space.
    static func p(_ x: Double, _ y: Double) -> CGPoint {
        CGPoint(x: x, y: y)
    }

    /// Sampled straight line from `a` to `b`, inclusive at both ends.
    static func line(from a: CGPoint, to b: CGPoint, steps: Int = 10) -> [CGPoint] {
        (0...steps).map { i in
            let t = Double(i) / Double(steps)
            return CGPoint(x: a.x + (b.x - a.x) * t,
                           y: a.y + (b.y - a.y) * t)
        }
    }

    /// Quadratic Bézier curve from `p0` to `p1` whose midpoint (`t = 0.5`)
    /// lands exactly on `peak`. Lets each letter's curves be authored by
    /// the highest point of the bulge rather than a control point.
    static func curveThrough(from p0: CGPoint, peak: CGPoint, to p1: CGPoint, steps: Int = 16) -> [CGPoint] {
        // Midpoint of a quadratic Bézier is (p0 + 2c + p1) / 4. Solve for c.
        let c = CGPoint(x: 2 * peak.x - 0.5 * (p0.x + p1.x),
                        y: 2 * peak.y - 0.5 * (p0.y + p1.y))
        return bezier(p0, c, p1, steps: steps)
    }

    /// Raw quadratic Bézier sampler, given explicit endpoints and control.
    static func bezier(_ p0: CGPoint, _ c: CGPoint, _ p1: CGPoint, steps: Int = 16) -> [CGPoint] {
        (0...steps).map { i in
            let t = Double(i) / Double(steps)
            let omt = 1 - t
            return CGPoint(
                x: omt * omt * p0.x + 2 * omt * t * c.x + t * t * p1.x,
                y: omt * omt * p0.y + 2 * omt * t * c.y + t * t * p1.y
            )
        }
    }

    /// Circular arc around `center` from `startAngle` to `endAngle` (radians).
    /// In the screen-y-down convention, `-π/2` is the top of the circle.
    static func circleArc(center: CGPoint,
                          radius: Double,
                          from startAngle: Double,
                          to endAngle: Double,
                          steps: Int = 20) -> [CGPoint] {
        ellipticalArc(center: center, rx: radius, ry: radius,
                      from: startAngle, to: endAngle, steps: steps)
    }

    /// Elliptical arc with independent horizontal and vertical radii.
    /// Used for letter parts whose natural shape is a stretched arc
    /// (e.g. D's bulge is wider than it is tall).
    static func ellipticalArc(center: CGPoint,
                              rx: Double,
                              ry: Double,
                              from startAngle: Double,
                              to endAngle: Double,
                              steps: Int = 20) -> [CGPoint] {
        (0...steps).map { i in
            let t = Double(i) / Double(steps)
            let angle = startAngle + (endAngle - startAngle) * t
            return CGPoint(x: center.x + rx * cos(angle),
                           y: center.y + ry * sin(angle))
        }
    }
}

