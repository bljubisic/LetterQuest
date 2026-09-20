import Foundation
import CoreGraphics

/// Stroke-path definitions for Spanish's letters with no plain-Latin
/// equivalent: Ñ/ñ (tilde) and the five acute-accented vowels
/// Á É Í Ó Ú / á é í ó ú. Every other Spanish letter (A–Z, a–z) reuses
/// `StrokeTemplate`'s existing Latin definitions as-is.
///
/// Ü/ü (diaeresis) is *not* defined here — it's visually identical to
/// German's Ü/ü (same mark, same base letter), so `StrokeTemplate`'s
/// fallback chain resolves it via `GermanStrokeDefinitions` before it would
/// ever reach this file. `SpanishAlphabet.swift`'s Ü/ü letters likewise
/// reuse German's `template_de_ue`/`template_de_lc_ue` template images
/// rather than generating duplicates.
///
/// Á/É/Ó/Ú and Í are built the same way German's umlauts are: the base
/// letter's shape, compressed to leave room above for the accent mark —
/// here a single diagonal tick instead of two dots. Lowercase í drops its
/// usual tittle dot in favor of the accent, matching real Spanish
/// orthography (the accent replaces the dot, it doesn't sit beside it).
enum SpanishStrokeDefinitions {

    typealias StrokeDef = StrokeTemplate.StrokeDef

    static func definitions(for character: Character) -> [StrokeDef]? {
        switch character {
        case "Ñ": return enyeDefinition
        case "Á": return aAcuteDefinition
        case "É": return eAcuteDefinition
        case "Í": return iAcuteDefinition
        case "Ó": return oAcuteDefinition
        case "Ú": return uAcuteDefinition
        case "ñ": return enyeLowerDefinition
        case "á": return aAcuteLowerDefinition
        case "é": return eAcuteLowerDefinition
        case "í": return iAcuteLowerDefinition
        case "ó": return oAcuteLowerDefinition
        case "ú": return uAcuteLowerDefinition
        default: return nil
        }
    }

    // MARK: - Shared accent strokes

    /// A single diagonal tick standing in for an acute accent, drawn
    /// bottom-left to top-right like a real pen stroke would.
    private static func acute(x: Double, y: Double) -> StrokeDef {
        StrokeDef(points: StrokeTemplate.line(from: StrokeTemplate.p(x, y + 0.10), to: StrokeTemplate.p(x + 0.12, y), steps: 3),
                  direction: .diagonal(angle: -45))
    }

    // MARK: - Uppercase (compressed into y 0.25…0.95, same technique as GermanStrokeDefinitions' umlauts)

    /// Á — A's diagonals + crossbar, compressed, plus one accent tick.
    private static let aAcuteDefinition: [StrokeDef] = [
        StrokeDef(points: StrokeTemplate.line(from: StrokeTemplate.p(0.5, 0.25), to: StrokeTemplate.p(0.95, 0.95)),
                  direction: .diagonal(angle: 45)),
        StrokeDef(points: StrokeTemplate.line(from: StrokeTemplate.p(0.5, 0.25), to: StrokeTemplate.p(0.05, 0.95)),
                  direction: .diagonal(angle: -45)),
        StrokeDef(points: StrokeTemplate.line(from: StrokeTemplate.p(0.2, 0.68), to: StrokeTemplate.p(0.8, 0.68)),
                  direction: .leftToRight),
        acute(x: 0.42, y: 0.06)
    ]

    /// É — E's spine + three bars, compressed, plus one accent tick.
    private static let eAcuteDefinition: [StrokeDef] = [
        StrokeDef(points: StrokeTemplate.line(from: StrokeTemplate.p(0.15, 0.25), to: StrokeTemplate.p(0.15, 0.95)),
                  direction: .topToBottom),
        StrokeDef(points: StrokeTemplate.line(from: StrokeTemplate.p(0.15, 0.25), to: StrokeTemplate.p(0.85, 0.25)),
                  direction: .leftToRight),
        StrokeDef(points: StrokeTemplate.line(from: StrokeTemplate.p(0.15, 0.60), to: StrokeTemplate.p(0.7, 0.60)),
                  direction: .leftToRight),
        StrokeDef(points: StrokeTemplate.line(from: StrokeTemplate.p(0.15, 0.95), to: StrokeTemplate.p(0.85, 0.95)),
                  direction: .leftToRight),
        acute(x: 0.42, y: 0.06)
    ]

    /// Í — I's single vertical, shortened at the top, plus one accent tick.
    /// (No separate dot: unlike lowercase í, uppercase I has none to begin with.)
    private static let iAcuteDefinition: [StrokeDef] = [
        StrokeDef(points: StrokeTemplate.line(from: StrokeTemplate.p(0.5, 0.25), to: StrokeTemplate.p(0.5, 0.95)),
                  direction: .topToBottom),
        acute(x: 0.42, y: 0.06)
    ]

    /// Ó — O's circle, shrunk to fit y 0.25…0.95, plus one accent tick.
    private static let oAcuteDefinition: [StrokeDef] = [
        StrokeDef(points: StrokeTemplate.circleArc(center: StrokeTemplate.p(0.5, 0.6), radius: 0.35,
                                                    from: -.pi / 2, to: 3 * .pi / 2),
                  direction: .curved),
        acute(x: 0.42, y: 0.06)
    ]

    /// Ú — U's curve, shrunk to fit y 0.25…0.95, plus one accent tick.
    private static let uAcuteDefinition: [StrokeDef] = [
        StrokeDef(points:
                    StrokeTemplate.line(from: StrokeTemplate.p(0.1, 0.25), to: StrokeTemplate.p(0.1, 0.745), steps: 6)
                  + StrokeTemplate.curveThrough(from: StrokeTemplate.p(0.1, 0.745), peak: StrokeTemplate.p(0.5, 0.95), to: StrokeTemplate.p(0.9, 0.745)).dropFirst()
                  + StrokeTemplate.line(from: StrokeTemplate.p(0.9, 0.745), to: StrokeTemplate.p(0.9, 0.25), steps: 6).dropFirst(),
                  direction: .curved),
        acute(x: 0.42, y: 0.06)
    ]

    /// Ñ — N's spine, diagonal, and right vertical, compressed, plus a
    /// wavy tilde (two joined curves) above.
    private static let enyeDefinition: [StrokeDef] = [
        StrokeDef(points: StrokeTemplate.line(from: StrokeTemplate.p(0.15, 0.25), to: StrokeTemplate.p(0.15, 0.95)),
                  direction: .topToBottom),
        StrokeDef(points: StrokeTemplate.line(from: StrokeTemplate.p(0.15, 0.25), to: StrokeTemplate.p(0.85, 0.95)),
                  direction: .diagonal(angle: 45)),
        StrokeDef(points: StrokeTemplate.line(from: StrokeTemplate.p(0.85, 0.25), to: StrokeTemplate.p(0.85, 0.95)),
                  direction: .topToBottom),
        StrokeDef(points:
                    StrokeTemplate.curveThrough(from: StrokeTemplate.p(0.15, 0.13), peak: StrokeTemplate.p(0.32, 0.03), to: StrokeTemplate.p(0.5, 0.09))
                  + StrokeTemplate.curveThrough(from: StrokeTemplate.p(0.5, 0.09), peak: StrokeTemplate.p(0.68, 0.15), to: StrokeTemplate.p(0.85, 0.05)).dropFirst(),
                  direction: .curved)
    ]

    // MARK: - Lowercase (base letters already clear the ascender zone, matching GermanStrokeDefinitions' umlauts)

    /// á — a's circle + stem, unchanged, plus one accent tick.
    private static let aAcuteLowerDefinition: [StrokeDef] = [
        StrokeDef(points: StrokeTemplate.circleArc(center: StrokeTemplate.p(0.42, 0.52), radius: 0.30,
                                                    from: -.pi / 2, to: 3 * .pi / 2),
                  direction: .curved),
        StrokeDef(points: StrokeTemplate.line(from: StrokeTemplate.p(0.72, 0.22), to: StrokeTemplate.p(0.72, 0.85)),
                  direction: .topToBottom),
        acute(x: 0.36, y: -0.02)
    ]

    /// é — e's crossbar + arc, unchanged, plus one accent tick.
    private static let eAcuteLowerDefinition: [StrokeDef] = [
        StrokeDef(points: StrokeTemplate.line(from: StrokeTemplate.p(0.12, 0.50), to: StrokeTemplate.p(0.88, 0.50)),
                  direction: .leftToRight),
        StrokeDef(points: StrokeTemplate.circleArc(center: StrokeTemplate.p(0.5, 0.50), radius: 0.38,
                                                    from: 0, to: -5 * .pi / 3),
                  direction: .curved),
        acute(x: 0.44, y: -0.08)
    ]

    /// í — i's stem *without* its usual dot (the accent replaces it, matching real orthography).
    private static let iAcuteLowerDefinition: [StrokeDef] = [
        StrokeDef(points: StrokeTemplate.line(from: StrokeTemplate.p(0.5, 0.22), to: StrokeTemplate.p(0.5, 0.85)),
                  direction: .topToBottom),
        acute(x: 0.44, y: -0.02)
    ]

    /// ó — o's circle, unchanged, plus one accent tick.
    private static let oAcuteLowerDefinition: [StrokeDef] = [
        StrokeDef(points: StrokeTemplate.circleArc(center: StrokeTemplate.p(0.5, 0.50), radius: 0.38,
                                                    from: -.pi / 2, to: 3 * .pi / 2),
                  direction: .curved),
        acute(x: 0.44, y: -0.08)
    ]

    /// ú — u's curve, unchanged, plus one accent tick.
    private static let uAcuteLowerDefinition: [StrokeDef] = [
        StrokeDef(points:
                    StrokeTemplate.line(from: StrokeTemplate.p(0.12, 0.15), to: StrokeTemplate.p(0.12, 0.65), steps: 4)
                  + StrokeTemplate.curveThrough(from: StrokeTemplate.p(0.12, 0.65), peak: StrokeTemplate.p(0.5, 0.92), to: StrokeTemplate.p(0.88, 0.65)).dropFirst()
                  + StrokeTemplate.line(from: StrokeTemplate.p(0.88, 0.65), to: StrokeTemplate.p(0.88, 0.15), steps: 4).dropFirst(),
                  direction: .curved),
        acute(x: 0.44, y: -0.02)
    ]

    /// ñ — n's stem + arch, unchanged (already clears the ascender zone), plus a wavy tilde above.
    private static let enyeLowerDefinition: [StrokeDef] = [
        StrokeDef(points: StrokeTemplate.line(from: StrokeTemplate.p(0.18, 0.22), to: StrokeTemplate.p(0.18, 0.85)),
                  direction: .topToBottom),
        StrokeDef(points: StrokeTemplate.curveThrough(from: StrokeTemplate.p(0.18, 0.47), peak: StrokeTemplate.p(0.50, 0.22), to: StrokeTemplate.p(0.80, 0.47))
                  + StrokeTemplate.line(from: StrokeTemplate.p(0.80, 0.47), to: StrokeTemplate.p(0.80, 0.85), steps: 5).dropFirst(),
                  direction: .topToBottom),
        StrokeDef(points:
                    StrokeTemplate.curveThrough(from: StrokeTemplate.p(0.10, 0.09), peak: StrokeTemplate.p(0.27, -0.01), to: StrokeTemplate.p(0.45, 0.05))
                  + StrokeTemplate.curveThrough(from: StrokeTemplate.p(0.45, 0.05), peak: StrokeTemplate.p(0.62, 0.11), to: StrokeTemplate.p(0.80, 0.01)).dropFirst(),
                  direction: .curved)
    ]
}
