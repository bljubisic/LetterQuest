import Foundation
import CoreGraphics

/// Stroke-path definitions for French's letters with no existing equivalent:
/// the grave, circumflex and diaeresis vowels, Ç (cedilla) and the ligatures
/// Æ Œ — À Â Ç È Ê Ë Î Ï Ô Ù Û Ÿ Æ Œ and their lowercase forms. Every other
/// French letter reuses an existing definition: A–Z/a–z come from
/// `StrokeTemplate`'s Latin definitions, Ü/ü from `GermanStrokeDefinitions`
/// and É/é from `SpanishStrokeDefinitions` (visually identical glyphs), both
/// of which `StrokeTemplate.definitions(for:)` tries first.
///
/// Marks above come last and follow the established layout: uppercase bodies
/// are compressed into y 0.25…0.95 like German's Ä, lowercase bodies are
/// unchanged, and every mark clears its body by at least 0.1 so it doesn't
/// fuse with the letter in the 64 px template images. On î/ï the mark
/// replaces i's dot, as Spanish's í does.
///
/// The cedilla hangs *below* the letter, so Ç/ç instead compress their C
/// upward and draw the hook underneath — keeping the whole glyph inside the
/// writing zone (and the template image) rather than dropping below baseline.
///
/// Æ/Œ have no Latin analogue and are best-effort approximations — worth a
/// visual check, same as German's ß.
enum FrenchStrokeDefinitions {

    typealias StrokeDef = StrokeTemplate.StrokeDef

    static func definitions(for character: Character) -> [StrokeDef]? {
        uppercaseDefinitions[character] ?? lowercaseDefinitions[character]
    }

    private static let uppercaseDefinitions: [Character: [StrokeDef]] = [
        "À": compressedA + [grave(x: 0.44, top: 0.02)],
        "Â": compressedA + [circumflex(centerX: 0.5, top: 0.02)],
        "Æ": aeLigatureDefinition,
        "Ç": cCedillaDefinition,
        "È": compressedE + [grave(x: 0.44, top: 0.02)],
        "Ê": compressedE + [circumflex(centerX: 0.5, top: 0.02)],
        "Ë": compressedE + upperDiaeresis,
        "Î": [compressedI, circumflex(centerX: 0.5, top: 0.02)],
        "Ï": [compressedI] + upperDiaeresis,
        "Ô": [compressedO, circumflex(centerX: 0.5, top: 0.02)],
        "Œ": oeLigatureDefinition,
        "Ù": [compressedU, grave(x: 0.44, top: 0.02)],
        "Û": [compressedU, circumflex(centerX: 0.5, top: 0.02)],
        "Ÿ": compressedY + upperDiaeresis
    ]

    private static let lowercaseDefinitions: [Character: [StrokeDef]] = [
        "à": lowerA + [grave(x: 0.36, top: -0.02)],
        "â": lowerA + [circumflex(centerX: 0.42, top: -0.02)],
        "æ": aeLigatureLowerDefinition,
        "ç": cCedillaLowerDefinition,
        "è": lowerE + [grave(x: 0.44, top: -0.08)],
        "ê": lowerE + [circumflex(centerX: 0.5, top: -0.08)],
        "ë": lowerE + [dot(x: 0.34, y: 0.02), dot(x: 0.59, y: 0.02)],
        "î": [lowerIStem, circumflex(centerX: 0.5, top: -0.02)],
        "ï": [lowerIStem, dot(x: 0.34, y: 0.08), dot(x: 0.59, y: 0.08)],
        "ô": [lowerO, circumflex(centerX: 0.5, top: -0.08)],
        "œ": oeLigatureLowerDefinition,
        "ù": [lowerU, grave(x: 0.44, top: -0.05)],
        "û": [lowerU, circumflex(centerX: 0.5, top: -0.05)],
        "ÿ": lowerY + [dot(x: 0.30, y: 0.06), dot(x: 0.58, y: 0.06)]
    ]

    // MARK: - Shared mark strokes

    private static func p(_ x: Double, _ y: Double) -> CGPoint { StrokeTemplate.p(x, y) }

    /// A grave accent: one tick drawn top-left to bottom-right ("\"),
    /// spanning y `top`…`top + 0.10` — the mirror of Spanish's acute.
    private static func grave(x: Double, top y: Double) -> StrokeDef {
        StrokeDef(points: StrokeTemplate.line(from: p(x, y), to: p(x + 0.12, y + 0.10), steps: 3),
                  direction: .diagonal(angle: 45))
    }

    /// A circumflex: one Λ-shaped stroke, up to the point then back down,
    /// spanning y `top`…`top + 0.10` — Croatian's caron turned upside down.
    ///
    /// Labelled `.leftToRight` (its overall travel), not `.curved` like the
    /// caron: `DTWMatcher` gives every curve a flat direction score below a
    /// matched straight direction, so a curved label let î's own Λ score
    /// lower than i's left-to-right dot and a correct î was rejected as "i".
    private static func circumflex(centerX x: Double, top y: Double, halfWidth: Double = 0.12) -> StrokeDef {
        StrokeDef(points: StrokeTemplate.line(from: p(x - halfWidth, y + 0.10), to: p(x, y), steps: 4)
                        + StrokeTemplate.line(from: p(x, y), to: p(x + halfWidth, y + 0.10), steps: 4).dropFirst(),
                  direction: .leftToRight)
    }

    /// One diaeresis dot — a short near-horizontal line, like German's umlaut dots.
    private static func dot(x: Double, y: Double) -> StrokeDef {
        StrokeDef(points: StrokeTemplate.line(from: p(x, y), to: p(x + 0.07, y), steps: 3),
                  direction: .leftToRight)
    }

    /// Two diaeresis dots above a compressed uppercase body, placed like German's Ä/Ö/Ü dots.
    private static let upperDiaeresis: [StrokeDef] = [dot(x: 0.35, y: 0.08), dot(x: 0.58, y: 0.08)]

    /// A cedilla: a short drop from the letter's base, then a hook curling
    /// right and back under it, starting at y `top`.
    private static func cedilla(centerX x: Double, top y: Double) -> StrokeDef {
        StrokeDef(points: StrokeTemplate.line(from: p(x, y), to: p(x, y + 0.05), steps: 3)
                        + StrokeTemplate.curveThrough(from: p(x, y + 0.05), peak: p(x + 0.13, y + 0.11),
                                                      to: p(x - 0.08, y + 0.17)).dropFirst(),
                  direction: .curved)
    }

    // MARK: - Uppercase letter bodies (compressed into y 0.25…0.95)

    private static let compressedA: [StrokeDef] = [
        StrokeDef(points: StrokeTemplate.line(from: p(0.5, 0.25), to: p(0.95, 0.95)), direction: .diagonal(angle: 45)),
        StrokeDef(points: StrokeTemplate.line(from: p(0.5, 0.25), to: p(0.05, 0.95)), direction: .diagonal(angle: -45)),
        StrokeDef(points: StrokeTemplate.line(from: p(0.2, 0.68), to: p(0.8, 0.68)), direction: .leftToRight)
    ]

    private static let compressedE: [StrokeDef] = [
        StrokeDef(points: StrokeTemplate.line(from: p(0.15, 0.25), to: p(0.15, 0.95)), direction: .topToBottom),
        StrokeDef(points: StrokeTemplate.line(from: p(0.15, 0.25), to: p(0.85, 0.25)), direction: .leftToRight),
        StrokeDef(points: StrokeTemplate.line(from: p(0.15, 0.60), to: p(0.7, 0.60)), direction: .leftToRight),
        StrokeDef(points: StrokeTemplate.line(from: p(0.15, 0.95), to: p(0.85, 0.95)), direction: .leftToRight)
    ]

    private static let compressedI = StrokeDef(
        points: StrokeTemplate.line(from: p(0.5, 0.25), to: p(0.5, 0.95)), direction: .topToBottom)

    private static let compressedO = StrokeDef(
        points: StrokeTemplate.circleArc(center: p(0.5, 0.6), radius: 0.35, from: -.pi / 2, to: 3 * .pi / 2),
        direction: .curved)

    private static let compressedU = StrokeDef(
        points: StrokeTemplate.line(from: p(0.1, 0.25), to: p(0.1, 0.745), steps: 6)
              + StrokeTemplate.curveThrough(from: p(0.1, 0.745), peak: p(0.5, 0.95), to: p(0.9, 0.745)).dropFirst()
              + StrokeTemplate.line(from: p(0.9, 0.745), to: p(0.9, 0.25), steps: 6).dropFirst(),
        direction: .curved)

    /// Y's two arms and stem with every y remapped from 0.05…0.95 to 0.25…0.95.
    private static let compressedY: [StrokeDef] = [
        StrokeDef(points: StrokeTemplate.line(from: p(0.1, 0.25), to: p(0.5, 0.6)), direction: .diagonal(angle: 45)),
        StrokeDef(points: StrokeTemplate.line(from: p(0.5, 0.6), to: p(0.9, 0.25)), direction: .diagonal(angle: -45)),
        StrokeDef(points: StrokeTemplate.line(from: p(0.5, 0.6), to: p(0.5, 0.95)), direction: .topToBottom)
    ]

    // MARK: - Uppercase

    /// Ç — C's arc compressed upward into y 0.05…0.75, with the cedilla below.
    private static let cCedillaDefinition: [StrokeDef] = [
        StrokeDef(points: StrokeTemplate.circleArc(center: p(0.5, 0.40), radius: 0.35,
                                                    from: -.pi / 3, to: -5 * .pi / 3),
                  direction: .curved),
        cedilla(centerX: 0.5, top: 0.80)
    ]

    /// Æ — A's left diagonal meeting E at the apex: E's spine and three bars,
    /// then A's crossbar last.
    private static let aeLigatureDefinition: [StrokeDef] = [
        StrokeDef(points: StrokeTemplate.line(from: p(0.5, 0.05), to: p(0.05, 0.95)), direction: .diagonal(angle: -45)),
        StrokeDef(points: StrokeTemplate.line(from: p(0.5, 0.05), to: p(0.5, 0.95)), direction: .topToBottom),
        StrokeDef(points: StrokeTemplate.line(from: p(0.5, 0.05), to: p(0.95, 0.05)), direction: .leftToRight),
        StrokeDef(points: StrokeTemplate.line(from: p(0.5, 0.5), to: p(0.85, 0.5)), direction: .leftToRight),
        StrokeDef(points: StrokeTemplate.line(from: p(0.5, 0.95), to: p(0.95, 0.95)), direction: .leftToRight),
        StrokeDef(points: StrokeTemplate.line(from: p(0.22, 0.62), to: p(0.5, 0.62)), direction: .leftToRight)
    ]

    /// Œ — O's left half (top, round the left, to the bottom) closed by E's
    /// spine, then E's three bars.
    private static let oeLigatureDefinition: [StrokeDef] = [
        StrokeDef(points: StrokeTemplate.ellipticalArc(center: p(0.5, 0.5), rx: 0.42, ry: 0.45,
                                                        from: -.pi / 2, to: -3 * .pi / 2),
                  direction: .curved),
        StrokeDef(points: StrokeTemplate.line(from: p(0.5, 0.05), to: p(0.5, 0.95)), direction: .topToBottom),
        StrokeDef(points: StrokeTemplate.line(from: p(0.5, 0.05), to: p(0.95, 0.05)), direction: .leftToRight),
        StrokeDef(points: StrokeTemplate.line(from: p(0.5, 0.5), to: p(0.85, 0.5)), direction: .leftToRight),
        StrokeDef(points: StrokeTemplate.line(from: p(0.5, 0.95), to: p(0.95, 0.95)), direction: .leftToRight)
    ]

    // MARK: - Lowercase letter bodies (unchanged from the Latin definitions)

    private static let lowerA: [StrokeDef] = [
        StrokeDef(points: StrokeTemplate.circleArc(center: p(0.42, 0.52), radius: 0.30,
                                                    from: -.pi / 2, to: 3 * .pi / 2),
                  direction: .curved),
        StrokeDef(points: StrokeTemplate.line(from: p(0.72, 0.22), to: p(0.72, 0.85)), direction: .topToBottom)
    ]

    private static let lowerE: [StrokeDef] = [
        StrokeDef(points: StrokeTemplate.line(from: p(0.12, 0.50), to: p(0.88, 0.50)), direction: .leftToRight),
        StrokeDef(points: StrokeTemplate.circleArc(center: p(0.5, 0.50), radius: 0.38, from: 0, to: -5 * .pi / 3),
                  direction: .curved)
    ]

    /// i's stem without its dot — the mark above replaces it.
    private static let lowerIStem = StrokeDef(
        points: StrokeTemplate.line(from: p(0.5, 0.22), to: p(0.5, 0.85)), direction: .topToBottom)

    private static let lowerO = StrokeDef(
        points: StrokeTemplate.circleArc(center: p(0.5, 0.50), radius: 0.38, from: -.pi / 2, to: 3 * .pi / 2),
        direction: .curved)

    private static let lowerU = StrokeDef(
        points: StrokeTemplate.line(from: p(0.12, 0.15), to: p(0.12, 0.65), steps: 4)
              + StrokeTemplate.curveThrough(from: p(0.12, 0.65), peak: p(0.5, 0.92), to: p(0.88, 0.65)).dropFirst()
              + StrokeTemplate.line(from: p(0.88, 0.65), to: p(0.88, 0.15), steps: 4).dropFirst(),
        direction: .curved)

    private static let lowerY: [StrokeDef] = [
        StrokeDef(points: StrokeTemplate.line(from: p(0.12, 0.20), to: p(0.52, 0.62)), direction: .diagonal(angle: 45)),
        StrokeDef(points: StrokeTemplate.line(from: p(0.88, 0.20), to: p(0.52, 0.62), steps: 4)
                        + StrokeTemplate.line(from: p(0.52, 0.62), to: p(0.52, 0.88), steps: 3).dropFirst()
                        + StrokeTemplate.curveThrough(from: p(0.52, 0.88), peak: p(0.36, 0.97), to: p(0.20, 0.90)).dropFirst(),
                  direction: .topToBottom)
    ]

    // MARK: - Lowercase

    /// ç — c's arc lifted and shrunk into y 0.10…0.74, with the cedilla below.
    private static let cCedillaLowerDefinition: [StrokeDef] = [
        StrokeDef(points: StrokeTemplate.circleArc(center: p(0.5, 0.42), radius: 0.32,
                                                    from: -.pi / 3, to: -5 * .pi / 3),
                  direction: .curved),
        cedilla(centerX: 0.5, top: 0.79)
    ]

    /// æ — a narrow a (bowl + stem) on the left, joined to a narrow e on the right.
    private static let aeLigatureLowerDefinition: [StrokeDef] = [
        StrokeDef(points: StrokeTemplate.ellipticalArc(center: p(0.27, 0.52), rx: 0.20, ry: 0.30,
                                                        from: -.pi / 2, to: 3 * .pi / 2),
                  direction: .curved),
        StrokeDef(points: StrokeTemplate.line(from: p(0.47, 0.22), to: p(0.47, 0.85)), direction: .topToBottom),
        StrokeDef(points: StrokeTemplate.line(from: p(0.47, 0.52), to: p(0.94, 0.52)), direction: .leftToRight),
        StrokeDef(points: StrokeTemplate.ellipticalArc(center: p(0.71, 0.52), rx: 0.23, ry: 0.30,
                                                        from: 0, to: -5 * .pi / 3),
                  direction: .curved)
    ]

    /// œ — a narrow o on the left, joined to a narrow e on the right.
    private static let oeLigatureLowerDefinition: [StrokeDef] = [
        StrokeDef(points: StrokeTemplate.ellipticalArc(center: p(0.28, 0.50), rx: 0.22, ry: 0.38,
                                                        from: -.pi / 2, to: 3 * .pi / 2),
                  direction: .curved),
        StrokeDef(points: StrokeTemplate.line(from: p(0.50, 0.50), to: p(0.94, 0.50)), direction: .leftToRight),
        StrokeDef(points: StrokeTemplate.ellipticalArc(center: p(0.72, 0.50), rx: 0.22, ry: 0.38,
                                                        from: 0, to: -5 * .pi / 3),
                  direction: .curved)
    ]
}
