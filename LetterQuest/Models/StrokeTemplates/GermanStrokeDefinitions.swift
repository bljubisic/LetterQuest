import Foundation
import CoreGraphics

/// Stroke-path definitions for the 7 German letters with no Latin
/// equivalent: Ä Ö Ü / ä ö ü ß. Every other German letter (A–Z, a–z) reuses
/// `StrokeTemplate`'s existing Latin definitions as-is — German uses the
/// same 26 base letterforms as English.
///
/// Ä/Ö/Ü and ä/ö/ü are built by shrinking the corresponding A/O/U (or
/// a/o/u) shape to make room for two short "dot" strokes above — the same
/// technique `StrokeTemplate`'s lowercase `i`/`j` already use for their own
/// dot. ß (Eszett) has no Latin analogue and is a best-effort approximation
/// (spine + upper bowl + lower hook) — worth a visual check, same as the
/// trickier letters in `CyrillicStrokeDefinitions.swift`.
enum GermanStrokeDefinitions {

    typealias StrokeDef = StrokeTemplate.StrokeDef

    static func definitions(for character: Character) -> [StrokeDef]? {
        switch character {
        case "Ä": return aUmlautDefinition
        case "Ö": return oUmlautDefinition
        case "Ü": return uUmlautDefinition
        case "ä": return aUmlautLowerDefinition
        case "ö": return oUmlautLowerDefinition
        case "ü": return uUmlautLowerDefinition
        case "ß": return eszettDefinition
        default: return nil
        }
    }

    // MARK: - Shared dot strokes
    //
    // A short near-horizontal line stands in for a dot, exactly like
    // `StrokeTemplate.iLowerDefinition`'s own dot stroke.

    private static func dot(x: Double, y: Double) -> StrokeDef {
        StrokeDef(points: StrokeTemplate.line(from: StrokeTemplate.p(x, y), to: StrokeTemplate.p(x + 0.07, y), steps: 3),
                  direction: .leftToRight)
    }

    // MARK: - Uppercase

    /// Ä — A's diagonals + crossbar, compressed into y 0.25…0.95 to leave
    /// room for two dots above, mirroring how a lowercase ascender letter
    /// reserves y 0.05…0.20 for its own dot.
    private static let aUmlautDefinition: [StrokeDef] = [
        StrokeDef(points: StrokeTemplate.line(from: StrokeTemplate.p(0.5, 0.25), to: StrokeTemplate.p(0.95, 0.95)),
                  direction: .diagonal(angle: 45)),
        StrokeDef(points: StrokeTemplate.line(from: StrokeTemplate.p(0.5, 0.25), to: StrokeTemplate.p(0.05, 0.95)),
                  direction: .diagonal(angle: -45)),
        StrokeDef(points: StrokeTemplate.line(from: StrokeTemplate.p(0.2, 0.68), to: StrokeTemplate.p(0.8, 0.68)),
                  direction: .leftToRight),
        dot(x: 0.35, y: 0.08),
        dot(x: 0.58, y: 0.08)
    ]

    /// Ö — O's circle, shrunk to fit y 0.25…0.95, plus two dots above.
    private static let oUmlautDefinition: [StrokeDef] = [
        StrokeDef(points: StrokeTemplate.circleArc(center: StrokeTemplate.p(0.5, 0.6), radius: 0.35,
                                                    from: -.pi / 2, to: 3 * .pi / 2),
                  direction: .curved),
        dot(x: 0.35, y: 0.08),
        dot(x: 0.58, y: 0.08)
    ]

    /// Ü — U's curve, shrunk to fit y 0.25…0.95, plus two dots above.
    private static let uUmlautDefinition: [StrokeDef] = [
        StrokeDef(points:
                    StrokeTemplate.line(from: StrokeTemplate.p(0.1, 0.25), to: StrokeTemplate.p(0.1, 0.745), steps: 6)
                  + StrokeTemplate.curveThrough(from: StrokeTemplate.p(0.1, 0.745), peak: StrokeTemplate.p(0.5, 0.95), to: StrokeTemplate.p(0.9, 0.745)).dropFirst()
                  + StrokeTemplate.line(from: StrokeTemplate.p(0.9, 0.745), to: StrokeTemplate.p(0.9, 0.25), steps: 6).dropFirst(),
                  direction: .curved),
        dot(x: 0.35, y: 0.08),
        dot(x: 0.58, y: 0.08)
    ]

    // MARK: - Lowercase

    /// ä — a's circle + stem, unchanged (already clears the ascender zone), plus two dots above.
    private static let aUmlautLowerDefinition: [StrokeDef] = [
        StrokeDef(points: StrokeTemplate.circleArc(center: StrokeTemplate.p(0.42, 0.52), radius: 0.30,
                                                    from: -.pi / 2, to: 3 * .pi / 2),
                  direction: .curved),
        StrokeDef(points: StrokeTemplate.line(from: StrokeTemplate.p(0.72, 0.22), to: StrokeTemplate.p(0.72, 0.85)),
                  direction: .topToBottom),
        dot(x: 0.30, y: 0.06),
        dot(x: 0.55, y: 0.06)
    ]

    /// ö — o's circle, unchanged, plus two dots above.
    private static let oUmlautLowerDefinition: [StrokeDef] = [
        StrokeDef(points: StrokeTemplate.circleArc(center: StrokeTemplate.p(0.5, 0.50), radius: 0.38,
                                                    from: -.pi / 2, to: 3 * .pi / 2),
                  direction: .curved),
        dot(x: 0.34, y: 0.06),
        dot(x: 0.59, y: 0.06)
    ]

    /// ü — u's curve, unchanged, plus two dots above.
    private static let uUmlautLowerDefinition: [StrokeDef] = [
        StrokeDef(points:
                    StrokeTemplate.line(from: StrokeTemplate.p(0.12, 0.15), to: StrokeTemplate.p(0.12, 0.65), steps: 4)
                  + StrokeTemplate.curveThrough(from: StrokeTemplate.p(0.12, 0.65), peak: StrokeTemplate.p(0.5, 0.92), to: StrokeTemplate.p(0.88, 0.65)).dropFirst()
                  + StrokeTemplate.line(from: StrokeTemplate.p(0.88, 0.65), to: StrokeTemplate.p(0.88, 0.15), steps: 4).dropFirst(),
                  direction: .curved),
        dot(x: 0.30, y: 0.06),
        dot(x: 0.58, y: 0.06)
    ]

    /// ß (Eszett) — no Latin analogue. Best-effort: an ascender spine, a
    /// upper bump and larger lower bump — the same spine-hinged-ellipse
    /// technique `bDefinition`/`bLowerDefinition` use for "B"/"b" — but
    /// unlike a normal B, the bumps don't sweep the full -90°...+90° range:
    /// the upper bump stops short of the stem at the waist, and the lower
    /// bump starts short of the stem at the waist and stops short again at
    /// the bottom, leaving it open rather than closing into a full loop.
    private static let eszettDefinition: [StrokeDef] = [
        StrokeDef(points: StrokeTemplate.line(from: StrokeTemplate.p(0.35, 0.05), to: StrokeTemplate.p(0.35, 0.85)),
                  direction: .topToBottom),
        StrokeDef(points: StrokeTemplate.ellipticalArc(center: StrokeTemplate.p(0.35, 0.27), rx: 0.32, ry: 0.20,
                                                        from: -.pi / 2, to: .pi / 2 * 0.6),
                  direction: .curved),
        StrokeDef(points: StrokeTemplate.ellipticalArc(center: StrokeTemplate.p(0.35, 0.65), rx: 0.42, ry: 0.20,
                                                        from: -.pi / 2 * 0.6, to: .pi / 2 * 0.75),
                  direction: .curved)
    ]
}
