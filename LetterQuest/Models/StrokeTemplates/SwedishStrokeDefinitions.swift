import Foundation
import CoreGraphics

/// Stroke-path definitions for Swedish's only new glyphs: Å / å. Every other
/// Swedish letter reuses an existing definition — A–Z/a–z come from
/// `StrokeTemplate`'s Latin definitions, and Ä Ö / ä ö come from
/// `GermanStrokeDefinitions` (visually identical glyphs), which
/// `StrokeTemplate.definitions(for:)` tries first.
///
/// Å/å follow the same layout as German's Ä/ä: the base letter keeps the
/// compressed shape that leaves the top zone free, and the ring is drawn
/// last as its own stroke — marks above the letter always come last, like
/// umlaut dots, accents and i/j dots. The rings sit higher than the
/// umlaut dots (dipping slightly above y 0, like Spanish's lowercase
/// accents) so a ~0.13 gap survives the stroke width of the 64 px
/// template images — any lower and the ring fuses with the letter.
enum SwedishStrokeDefinitions {

    typealias StrokeDef = StrokeTemplate.StrokeDef

    static func definitions(for character: Character) -> [StrokeDef]? {
        switch character {
        case "Å": return aRingDefinition
        case "å": return aRingLowerDefinition
        default: return nil
        }
    }

    // MARK: - Shared ring stroke

    /// A full circle starting (and ending) at its top, like O's own stroke.
    private static func ring(x: Double, y: Double, radius: Double) -> StrokeDef {
        StrokeDef(points: StrokeTemplate.circleArc(center: StrokeTemplate.p(x, y), radius: radius,
                                                    from: -.pi / 2, to: 3 * .pi / 2),
                  direction: .curved)
    }

    // MARK: - Uppercase

    /// Å — German's Ä diagonals + crossbar (apex at y 0.25), with a ring
    /// spanning y -0.02…0.12 above the apex instead of two dots.
    private static let aRingDefinition: [StrokeDef] = [
        StrokeDef(points: StrokeTemplate.line(from: StrokeTemplate.p(0.5, 0.25), to: StrokeTemplate.p(0.95, 0.95)),
                  direction: .diagonal(angle: 45)),
        StrokeDef(points: StrokeTemplate.line(from: StrokeTemplate.p(0.5, 0.25), to: StrokeTemplate.p(0.05, 0.95)),
                  direction: .diagonal(angle: -45)),
        StrokeDef(points: StrokeTemplate.line(from: StrokeTemplate.p(0.2, 0.68), to: StrokeTemplate.p(0.8, 0.68)),
                  direction: .leftToRight),
        ring(x: 0.5, y: 0.05, radius: 0.07)
    ]

    // MARK: - Lowercase

    /// å — a's circle + stem (top at y 0.22), with a small ring spanning
    /// y -0.045…0.085 above.
    private static let aRingLowerDefinition: [StrokeDef] = [
        StrokeDef(points: StrokeTemplate.circleArc(center: StrokeTemplate.p(0.42, 0.52), radius: 0.30,
                                                    from: -.pi / 2, to: 3 * .pi / 2),
                  direction: .curved),
        StrokeDef(points: StrokeTemplate.line(from: StrokeTemplate.p(0.72, 0.22), to: StrokeTemplate.p(0.72, 0.85)),
                  direction: .topToBottom),
        ring(x: 0.5, y: 0.02, radius: 0.065)
    ]
}
