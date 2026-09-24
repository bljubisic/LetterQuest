import Foundation
import CoreGraphics

/// Stroke-path definitions for the letters of Gaj's Latin alphabet
/// (Croatian / Serbian Latin / Slovenian) with no plain-Latin equivalent:
/// Č Ć Đ Š Ž / č ć đ š ž and the digraphs Dž Lj Nj, stored as the single
/// Unicode code points Ǆ Ǉ Ǌ / ǆ ǉ ǌ so each fits one `Character`. The
/// uppercase digraphs are the all-caps forms (DŽ, LJ, NJ) — the titlecase
/// forms (ǅ ǈ ǋ) aren't `isUppercase` and would get the lowercase writing zone.
///
/// Every mark comes last: the caron/acute above Č Ć Š Ž (same rule as
/// German's umlauts and Spanish's accents) and the bar through Đ/đ (same as
/// crossing a t after its stem). Uppercase letters with a mark are compressed
/// into y 0.25…0.95 like German's Ä; lowercase ones drop their body to start
/// around y 0.22. Either way the mark clears the body by ~0.13, enough that it
/// doesn't fuse with the letter at the 64 px template-image size (a lesson
/// from Swedish's Å ring).
///
/// Digraphs place their two letters side by side at roughly half width.
enum CroatianStrokeDefinitions {

    typealias StrokeDef = StrokeTemplate.StrokeDef

    static func definitions(for character: Character) -> [StrokeDef]? {
        switch character {
        case "Č": return cCaronDefinition
        case "Ć": return cAcuteDefinition
        case "Đ": return dStrokeDefinition
        case "Š": return sCaronDefinition
        case "Ž": return zCaronDefinition
        case "Ǆ": return dzCaronDefinition
        case "Ǉ": return ljDefinition
        case "Ǌ": return njDefinition
        case "č": return cCaronLowerDefinition
        case "ć": return cAcuteLowerDefinition
        case "đ": return dStrokeLowerDefinition
        case "š": return sCaronLowerDefinition
        case "ž": return zCaronLowerDefinition
        case "ǆ": return dzCaronLowerDefinition
        case "ǉ": return ljLowerDefinition
        case "ǌ": return njLowerDefinition
        default: return nil
        }
    }

    // MARK: - Shared mark strokes

    private static func p(_ x: Double, _ y: Double) -> CGPoint { StrokeTemplate.p(x, y) }

    /// A caron (háček): one V-shaped stroke, down to the point then back up,
    /// spanning y `top`…`top + 0.12`.
    private static func caron(centerX x: Double, top y: Double, halfWidth: Double = 0.12) -> StrokeDef {
        StrokeDef(points: StrokeTemplate.line(from: p(x - halfWidth, y), to: p(x, y + 0.12), steps: 4)
                        + StrokeTemplate.line(from: p(x, y + 0.12), to: p(x + halfWidth, y), steps: 4).dropFirst(),
                  direction: .curved)
    }

    /// An acute accent — same tick as `SpanishStrokeDefinitions.acute`:
    /// bottom-left to top-right, spanning y `top`…`top + 0.10`.
    private static func acute(x: Double, top y: Double) -> StrokeDef {
        StrokeDef(points: StrokeTemplate.line(from: p(x, y + 0.10), to: p(x + 0.12, y), steps: 3),
                  direction: .diagonal(angle: -45))
    }

    // MARK: - Uppercase letter bodies (compressed into y 0.25…0.95)

    private static let compressedC = StrokeDef(
        points: StrokeTemplate.circleArc(center: p(0.5, 0.6), radius: 0.35, from: -.pi / 3, to: -5 * .pi / 3),
        direction: .curved)

    /// S's two-bezier spine with every y remapped from 0…1 to 0.25…0.95.
    private static let compressedS = StrokeDef(
        points: StrokeTemplate.bezier(p(0.85, 0.32), p(0.05, 0.25), p(0.5, 0.60))
              + StrokeTemplate.bezier(p(0.5, 0.60), p(0.95, 0.95), p(0.15, 0.88)).dropFirst(),
        direction: .curved)

    private static func compressedZ(left: Double, right: Double) -> [StrokeDef] {
        [
            StrokeDef(points: StrokeTemplate.line(from: p(left, 0.25), to: p(right, 0.25)), direction: .leftToRight),
            StrokeDef(points: StrokeTemplate.line(from: p(right, 0.25), to: p(left, 0.95)), direction: .diagonal(angle: -45)),
            StrokeDef(points: StrokeTemplate.line(from: p(left, 0.95), to: p(right, 0.95)), direction: .leftToRight)
        ]
    }

    // MARK: - Uppercase

    private static let cCaronDefinition: [StrokeDef] = [compressedC, caron(centerX: 0.5, top: -0.02)]

    private static let cAcuteDefinition: [StrokeDef] = [compressedC, acute(x: 0.44, top: -0.02)]

    /// Đ — D at full height, then a short bar across the spine at mid-height.
    private static let dStrokeDefinition: [StrokeDef] = [
        StrokeDef(points: StrokeTemplate.line(from: p(0.15, 0.05), to: p(0.15, 0.95)), direction: .topToBottom),
        StrokeDef(points: StrokeTemplate.ellipticalArc(center: p(0.15, 0.5), rx: 0.75, ry: 0.45,
                                                        from: -.pi / 2, to: .pi / 2),
                  direction: .curved),
        StrokeDef(points: StrokeTemplate.line(from: p(0.02, 0.5), to: p(0.38, 0.5)), direction: .leftToRight)
    ]

    private static let sCaronDefinition: [StrokeDef] = [compressedS, caron(centerX: 0.5, top: -0.02)]

    private static let zCaronDefinition: [StrokeDef] =
        compressedZ(left: 0.1, right: 0.9) + [caron(centerX: 0.5, top: -0.02)]

    /// DŽ — a compressed D in the left half, Ž in the right half.
    private static let dzCaronDefinition: [StrokeDef] = [
        StrokeDef(points: StrokeTemplate.line(from: p(0.05, 0.25), to: p(0.05, 0.95)), direction: .topToBottom),
        StrokeDef(points: StrokeTemplate.ellipticalArc(center: p(0.05, 0.6), rx: 0.38, ry: 0.35,
                                                        from: -.pi / 2, to: .pi / 2),
                  direction: .curved)
    ] + compressedZ(left: 0.55, right: 0.95) + [caron(centerX: 0.75, top: -0.02, halfWidth: 0.09)]

    /// LJ — L in the left half, J in the right half.
    private static let ljDefinition: [StrokeDef] = [
        StrokeDef(points: StrokeTemplate.line(from: p(0.08, 0.05), to: p(0.08, 0.95)), direction: .topToBottom),
        StrokeDef(points: StrokeTemplate.line(from: p(0.08, 0.95), to: p(0.44, 0.95)), direction: .leftToRight),
        StrokeDef(points: StrokeTemplate.line(from: p(0.86, 0.05), to: p(0.86, 0.7)), direction: .topToBottom),
        StrokeDef(points: StrokeTemplate.curveThrough(from: p(0.86, 0.7), peak: p(0.72, 0.97), to: p(0.58, 0.85)),
                  direction: .curved)
    ]

    /// NJ — N in the left half, J in the right half.
    private static let njDefinition: [StrokeDef] = [
        StrokeDef(points: StrokeTemplate.line(from: p(0.05, 0.05), to: p(0.05, 0.95)), direction: .topToBottom),
        StrokeDef(points: StrokeTemplate.line(from: p(0.05, 0.05), to: p(0.45, 0.95)), direction: .diagonal(angle: 45)),
        StrokeDef(points: StrokeTemplate.line(from: p(0.45, 0.05), to: p(0.45, 0.95)), direction: .topToBottom),
        StrokeDef(points: StrokeTemplate.line(from: p(0.88, 0.05), to: p(0.88, 0.7)), direction: .topToBottom),
        StrokeDef(points: StrokeTemplate.curveThrough(from: p(0.88, 0.7), peak: p(0.75, 0.97), to: p(0.62, 0.85)),
                  direction: .curved)
    ]

    // MARK: - Lowercase letter bodies (lowered to start around y 0.22)

    private static let loweredC = StrokeDef(
        points: StrokeTemplate.circleArc(center: p(0.5, 0.54), radius: 0.32, from: -.pi / 3, to: -5 * .pi / 3),
        direction: .curved)

    /// s's two-curve spine with its y range remapped from 0.15…0.88 to 0.24…0.86.
    private static let loweredS = StrokeDef(
        points: StrokeTemplate.curveThrough(from: p(0.80, 0.24), peak: p(0.15, 0.41), to: p(0.50, 0.56))
              + StrokeTemplate.curveThrough(from: p(0.50, 0.56), peak: p(0.85, 0.71), to: p(0.20, 0.86)).dropFirst(),
        direction: .curved)

    private static func loweredZ(left: Double, right: Double) -> [StrokeDef] {
        [
            StrokeDef(points: StrokeTemplate.line(from: p(left, 0.24), to: p(right, 0.24)), direction: .leftToRight),
            StrokeDef(points: StrokeTemplate.line(from: p(right, 0.24), to: p(left, 0.86)), direction: .diagonal(angle: -45)),
            StrokeDef(points: StrokeTemplate.line(from: p(left, 0.86), to: p(right, 0.86)), direction: .leftToRight)
        ]
    }

    /// j's descending stem-with-hook and its dot, centred on `x`.
    private static func lowerJ(x: Double) -> [StrokeDef] {
        [
            StrokeDef(points: StrokeTemplate.line(from: p(x, 0.22), to: p(x, 0.90), steps: 5)
                            + StrokeTemplate.curveThrough(from: p(x, 0.90), peak: p(x - 0.12, 0.97), to: p(x - 0.24, 0.90)).dropFirst(),
                      direction: .topToBottom),
            StrokeDef(points: StrokeTemplate.line(from: p(x - 0.06, 0.10), to: p(x + 0.06, 0.14), steps: 3),
                      direction: .leftToRight)
        ]
    }

    // MARK: - Lowercase

    private static let cCaronLowerDefinition: [StrokeDef] = [loweredC, caron(centerX: 0.5, top: -0.04)]

    private static let cAcuteLowerDefinition: [StrokeDef] = [loweredC, acute(x: 0.44, top: -0.04)]

    /// đ — d unchanged, then a short bar across the ascender near its top.
    private static let dStrokeLowerDefinition: [StrokeDef] = [
        StrokeDef(points: StrokeTemplate.circleArc(center: p(0.42, 0.52), radius: 0.30,
                                                    from: -.pi / 2, to: 3 * .pi / 2),
                  direction: .curved),
        StrokeDef(points: StrokeTemplate.line(from: p(0.72, 0.05), to: p(0.72, 0.85)), direction: .topToBottom),
        StrokeDef(points: StrokeTemplate.line(from: p(0.56, 0.15), to: p(0.90, 0.15)), direction: .leftToRight)
    ]

    private static let sCaronLowerDefinition: [StrokeDef] = [loweredS, caron(centerX: 0.5, top: -0.04)]

    private static let zCaronLowerDefinition: [StrokeDef] =
        loweredZ(left: 0.10, right: 0.90) + [caron(centerX: 0.5, top: -0.04)]

    /// dž — a narrower d on the left, ž on the right.
    private static let dzCaronLowerDefinition: [StrokeDef] = [
        StrokeDef(points: StrokeTemplate.circleArc(center: p(0.24, 0.54), radius: 0.20,
                                                    from: -.pi / 2, to: 3 * .pi / 2),
                  direction: .curved),
        StrokeDef(points: StrokeTemplate.line(from: p(0.44, 0.05), to: p(0.44, 0.85)), direction: .topToBottom)
    ] + loweredZ(left: 0.56, right: 0.96) + [caron(centerX: 0.76, top: -0.04, halfWidth: 0.09)]

    /// lj — l's stem on the left, j on the right.
    private static let ljLowerDefinition: [StrokeDef] = [
        StrokeDef(points: StrokeTemplate.line(from: p(0.25, 0.05), to: p(0.25, 0.85)), direction: .topToBottom)
    ] + lowerJ(x: 0.70)

    /// nj — a narrower n on the left, j on the right.
    private static let njLowerDefinition: [StrokeDef] = [
        StrokeDef(points: StrokeTemplate.line(from: p(0.06, 0.22), to: p(0.06, 0.85)), direction: .topToBottom),
        StrokeDef(points: StrokeTemplate.curveThrough(from: p(0.06, 0.47), peak: p(0.27, 0.22), to: p(0.46, 0.47))
                        + StrokeTemplate.line(from: p(0.46, 0.47), to: p(0.46, 0.85), steps: 5).dropFirst(),
                  direction: .topToBottom)
    ] + lowerJ(x: 0.82)
}
