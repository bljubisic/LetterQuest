import Foundation
import CoreGraphics

/// Stroke-path definitions for the 30-letter Serbian Cyrillic alphabet,
/// authored the same way as `StrokeTemplate`'s Latin definitions — each
/// letter is a small script built from the same geometry primitives. Kept
/// in its own file so `StrokeTemplate.swift` doesn't grow past a reasonable
/// size with a second script's worth of letterforms.
///
/// Several letters (Б, Ђ, Ж, Л, Љ, Њ, Ћ, Ч, Џ, Ш and their lowercase forms)
/// have no Latin equivalent. Ђ/ђ, Љ/љ, Њ/њ, Ћ/ћ, and Ц/Ц-derived Џ/џ were
/// re-verified by rendering the actual glyphs from the system font
/// (SFNS.ttf) and tracing their real structure — see git history for the
/// first best-effort pass these replaced. The rest are still best-effort
/// from general script knowledge and worth a visual check.
enum CyrillicStrokeDefinitions {

    typealias StrokeDef = StrokeTemplate.StrokeDef

    static func definitions(for character: Character) -> [StrokeDef]? {
        switch character {
        // MARK: Uppercase
        case "А": return aDefinition
        case "Б": return beDefinition
        case "В": return veDefinition
        case "Г": return geDefinition
        case "Д": return deDefinition
        case "Ђ": return djeDefinition
        case "Е": return ieDefinition
        case "Ж": return zheDefinition
        case "З": return zeDefinition
        case "И": return iDefinition
        case "Ј": return jeDefinition
        case "К": return kaDefinition
        case "Л": return elDefinition
        case "Љ": return ljeDefinition
        case "М": return emDefinition
        case "Н": return enDefinition
        case "Њ": return njeDefinition
        case "О": return oDefinition
        case "П": return peDefinition
        case "Р": return erDefinition
        case "С": return esDefinition
        case "Т": return teDefinition
        case "Ћ": return tsheDefinition
        case "У": return uDefinition
        case "Ф": return efDefinition
        case "Х": return haDefinition
        case "Ц": return tseDefinition
        case "Ч": return cheDefinition
        case "Џ": return dzheDefinition
        case "Ш": return shaDefinition

        // MARK: Lowercase
        case "а": return aLowerDefinition
        case "б": return beLowerDefinition
        case "в": return veLowerDefinition
        case "г": return geLowerDefinition
        case "д": return deLowerDefinition
        case "ђ": return djeLowerDefinition
        case "е": return ieLowerDefinition
        case "ж": return zheLowerDefinition
        case "з": return zeLowerDefinition
        case "и": return iLowerDefinition
        case "ј": return jeLowerDefinition
        case "к": return kaLowerDefinition
        case "л": return elLowerDefinition
        case "љ": return ljeLowerDefinition
        case "м": return emLowerDefinition
        case "н": return enLowerDefinition
        case "њ": return njeLowerDefinition
        case "о": return oLowerDefinition
        case "п": return peLowerDefinition
        case "р": return erLowerDefinition
        case "с": return esLowerDefinition
        case "т": return teLowerDefinition
        case "ћ": return tsheLowerDefinition
        case "у": return uLowerDefinition
        case "ф": return efLowerDefinition
        case "х": return haLowerDefinition
        case "ц": return tseLowerDefinition
        case "ч": return cheLowerDefinition
        case "џ": return dzheLowerDefinition
        case "ш": return shaLowerDefinition

        default:
            return nil
        }
    }

    // MARK: - Uppercase definitions
    //
    // Cap box: x and y both 0.05…0.95, matching `StrokeTemplate`'s Latin
    // uppercase convention exactly.

    /// А — visually identical to Latin A: two diagonal legs + crossbar.
    private static let aDefinition: [StrokeDef] = [
        StrokeDef(points: line(from: p(0.5, 0.05), to: p(0.95, 0.95)), direction: .diagonal(angle: 45)),
        StrokeDef(points: line(from: p(0.5, 0.05), to: p(0.05, 0.95)), direction: .diagonal(angle: -45)),
        StrokeDef(points: line(from: p(0.2, 0.6),  to: p(0.8, 0.6)),  direction: .leftToRight)
    ]

    /// Б — spine, top bar, then a single right-bulging bottom bowl.
    private static let beDefinition: [StrokeDef] = [
        StrokeDef(points: line(from: p(0.15, 0.05), to: p(0.15, 0.95)), direction: .topToBottom),
        StrokeDef(points: line(from: p(0.15, 0.05), to: p(0.75, 0.05)), direction: .leftToRight),
        StrokeDef(points: ellipticalArc(center: p(0.15, 0.65), rx: 0.55, ry: 0.3, from: -.pi / 2, to: .pi / 2),
                  direction: .curved)
    ]

    /// В — visually identical to Latin B: spine + two stacked right-bulging bumps.
    private static let veDefinition: [StrokeDef] = [
        StrokeDef(points: line(from: p(0.15, 0.05), to: p(0.15, 0.95)), direction: .topToBottom),
        StrokeDef(points:
                    ellipticalArc(center: p(0.15, 0.275), rx: 0.55, ry: 0.225, from: -.pi / 2, to: .pi / 2)
                  + ellipticalArc(center: p(0.15, 0.725), rx: 0.65, ry: 0.225, from: -.pi / 2, to: .pi / 2).dropFirst(),
                  direction: .curved)
    ]

    /// Г — top bar then spine, meeting at the top-left corner (right-angle hook).
    private static let geDefinition: [StrokeDef] = [
        StrokeDef(points: line(from: p(0.15, 0.05), to: p(0.85, 0.05)), direction: .leftToRight),
        StrokeDef(points: line(from: p(0.15, 0.05), to: p(0.15, 0.95)), direction: .topToBottom)
    ]

    /// Д — top bar, left/right sides each ending in a small outward foot, bottom bar
    /// between the sides (feet extend slightly past it, like a table's legs).
    private static let deDefinition: [StrokeDef] = [
        StrokeDef(points: line(from: p(0.15, 0.05), to: p(0.85, 0.05)), direction: .leftToRight),
        StrokeDef(points: line(from: p(0.15, 0.05), to: p(0.15, 0.85)) + line(from: p(0.15, 0.85), to: p(0.05, 0.95)).dropFirst(),
                  direction: .topToBottom),
        StrokeDef(points: line(from: p(0.85, 0.05), to: p(0.85, 0.85)) + line(from: p(0.85, 0.85), to: p(0.95, 0.95)).dropFirst(),
                  direction: .topToBottom),
        StrokeDef(points: line(from: p(0.15, 0.85), to: p(0.85, 0.85)), direction: .leftToRight)
    ]

    /// Ђ — same Т top bar and full-height stem as Ћ. The arch is shaped like
    /// the lower bump of Б/В (a quarter-ellipse off the stem) but left open
    /// at the bottom instead of curving back to close — then curls back at
    /// the very end, distinguishing it from Ћ's plain straight leg.
    private static let djeDefinition: [StrokeDef] = [
        StrokeDef(points: line(from: p(0.1, 0.05), to: p(0.7, 0.05)), direction: .leftToRight),
        StrokeDef(points: line(from: p(0.4, 0.05), to: p(0.4, 0.95)), direction: .topToBottom),
        StrokeDef(points: ellipticalArc(center: p(0.4, 0.75), rx: 0.45, ry: 0.2, from: -.pi / 2, to: 0)
                  + line(from: p(0.85, 0.75), to: p(0.85, 0.8), steps: 2).dropFirst()
                  + curveThrough(from: p(0.85, 0.8), peak: p(0.75, 0.98), to: p(0.6, 0.9)).dropFirst(),
                  direction: .curved)
    ]

    /// Е — visually identical to Latin E: spine + three horizontal bars.
    private static let ieDefinition: [StrokeDef] = [
        StrokeDef(points: line(from: p(0.15, 0.05), to: p(0.15, 0.95)), direction: .topToBottom),
        StrokeDef(points: line(from: p(0.15, 0.05), to: p(0.85, 0.05)), direction: .leftToRight),
        StrokeDef(points: line(from: p(0.15, 0.5),  to: p(0.7,  0.5)), direction: .leftToRight),
        StrokeDef(points: line(from: p(0.15, 0.95), to: p(0.85, 0.95)), direction: .leftToRight)
    ]

    /// Ж — central spine with four symmetric diagonal "wings" meeting at the centre.
    private static let zheDefinition: [StrokeDef] = [
        StrokeDef(points: line(from: p(0.5, 0.05), to: p(0.5, 0.95)), direction: .topToBottom),
        StrokeDef(points: line(from: p(0.08, 0.05), to: p(0.5, 0.5)), direction: .diagonal(angle: 45)),
        StrokeDef(points: line(from: p(0.5, 0.5),  to: p(0.08, 0.95)), direction: .diagonal(angle: -45)),
        StrokeDef(points: line(from: p(0.92, 0.05), to: p(0.5, 0.5)), direction: .diagonal(angle: -45)),
        StrokeDef(points: line(from: p(0.5, 0.5),  to: p(0.92, 0.95)), direction: .diagonal(angle: 45))
    ]

    /// З — two stacked right-bulging bumps with no spine (like the digit 3).
    private static let zeDefinition: [StrokeDef] = [
        StrokeDef(points:
                    ellipticalArc(center: p(0.4, 0.28), rx: 0.45, ry: 0.23, from: -.pi / 2, to: .pi / 2)
                  + ellipticalArc(center: p(0.4, 0.72), rx: 0.5, ry: 0.23, from: -.pi / 2, to: .pi / 2).dropFirst(),
                  direction: .curved)
    ]

    /// И — left vertical, diagonal rising to the right (opposite slope from Latin N), right vertical.
    private static let iDefinition: [StrokeDef] = [
        StrokeDef(points: line(from: p(0.15, 0.05), to: p(0.15, 0.95)), direction: .topToBottom),
        StrokeDef(points: line(from: p(0.15, 0.95), to: p(0.85, 0.05)), direction: .diagonal(angle: -45)),
        StrokeDef(points: line(from: p(0.85, 0.05), to: p(0.85, 0.95)), direction: .topToBottom)
    ]

    /// Ј — visually identical to Latin J: vertical drop with a curved hook.
    private static let jeDefinition: [StrokeDef] = [
        StrokeDef(points: line(from: p(0.7, 0.05), to: p(0.7, 0.7)), direction: .topToBottom),
        StrokeDef(points: curveThrough(from: p(0.7, 0.7), peak: p(0.45, 0.97), to: p(0.2, 0.85)), direction: .curved)
    ]

    /// К — visually identical to Latin K: spine + two diagonals meeting mid-spine.
    private static let kaDefinition: [StrokeDef] = [
        StrokeDef(points: line(from: p(0.15, 0.05), to: p(0.15, 0.95)), direction: .topToBottom),
        StrokeDef(points: line(from: p(0.85, 0.05), to: p(0.15, 0.5)), direction: .diagonal(angle: -45)),
        StrokeDef(points: line(from: p(0.15, 0.5),  to: p(0.85, 0.95)), direction: .diagonal(angle: 45))
    ]

    /// Л — simplified as a tent/triangle shape (two legs meeting at a peak).
    private static let elDefinition: [StrokeDef] = [
        StrokeDef(points: line(from: p(0.15, 0.95), to: p(0.5, 0.05)), direction: .diagonal(angle: -45)),
        StrokeDef(points: line(from: p(0.5, 0.05),  to: p(0.85, 0.95)), direction: .diagonal(angle: 45))
    ]

    /// Љ — an arch (top bar + left leg with a curved outward foot, matching
    /// Л's own foot treatment) with a right-bulging "b"-style bowl hinged
    /// on the right leg.
    private static let ljeDefinition: [StrokeDef] = [
        StrokeDef(points: line(from: p(0.25, 0.05), to: p(0.6, 0.05)), direction: .leftToRight),
        StrokeDef(points: line(from: p(0.25, 0.05), to: p(0.25, 0.75), steps: 6)
                  + curveThrough(from: p(0.25, 0.75), peak: p(0.15, 0.93), to: p(0.05, 0.85)).dropFirst(),
                  direction: .topToBottom),
        StrokeDef(points: line(from: p(0.6, 0.05), to: p(0.6, 0.95)), direction: .topToBottom),
        StrokeDef(points: ellipticalArc(center: p(0.6, 0.72), rx: 0.4, ry: 0.23, from: -.pi / 2, to: .pi / 2),
                  direction: .curved)
    ]

    /// М — visually identical to Latin M.
    private static let emDefinition: [StrokeDef] = [
        StrokeDef(points: line(from: p(0.1, 0.05), to: p(0.1, 0.95)), direction: .topToBottom),
        StrokeDef(points: line(from: p(0.1, 0.05), to: p(0.5, 0.7)), direction: .diagonal(angle: 45)),
        StrokeDef(points: line(from: p(0.5, 0.7),  to: p(0.9, 0.05)), direction: .diagonal(angle: -45)),
        StrokeDef(points: line(from: p(0.9, 0.05), to: p(0.9, 0.95)), direction: .topToBottom)
    ]

    /// Н — visually identical to Latin H (not Latin N): two verticals + crossbar.
    private static let enDefinition: [StrokeDef] = [
        StrokeDef(points: line(from: p(0.15, 0.05), to: p(0.15, 0.95)), direction: .topToBottom),
        StrokeDef(points: line(from: p(0.85, 0.05), to: p(0.85, 0.95)), direction: .topToBottom),
        StrokeDef(points: line(from: p(0.15, 0.5),  to: p(0.85, 0.5)), direction: .leftToRight)
    ]

    /// Њ — Н's H-shape, but the right vertical stops partway down into a
    /// right-bulging "b"-style bowl instead of continuing to the baseline.
    private static let njeDefinition: [StrokeDef] = [
        StrokeDef(points: line(from: p(0.1, 0.05), to: p(0.1, 0.95)), direction: .topToBottom),
        StrokeDef(points: line(from: p(0.45, 0.05), to: p(0.45, 0.95)), direction: .topToBottom),
        StrokeDef(points: line(from: p(0.1, 0.5), to: p(0.45, 0.5)), direction: .leftToRight),
        StrokeDef(points: ellipticalArc(center: p(0.45, 0.72), rx: 0.45, ry: 0.23, from: -.pi / 2, to: .pi / 2),
                  direction: .curved)
    ]

    /// О — visually identical to Latin O.
    private static let oDefinition: [StrokeDef] = [
        StrokeDef(points: circleArc(center: p(0.5, 0.5), radius: 0.45, from: -.pi / 2, to: 3 * .pi / 2),
                  direction: .curved)
    ]

    /// П — an arch: top bar with a leg dropping from each end.
    private static let peDefinition: [StrokeDef] = [
        StrokeDef(points: line(from: p(0.1, 0.05), to: p(0.9, 0.05)), direction: .leftToRight),
        StrokeDef(points: line(from: p(0.1, 0.05), to: p(0.1, 0.95)), direction: .topToBottom),
        StrokeDef(points: line(from: p(0.9, 0.05), to: p(0.9, 0.95)), direction: .topToBottom)
    ]

    /// Р — visually identical to Latin P: spine + top bowl.
    private static let erDefinition: [StrokeDef] = [
        StrokeDef(points: line(from: p(0.15, 0.05), to: p(0.15, 0.95)), direction: .topToBottom),
        StrokeDef(points: ellipticalArc(center: p(0.15, 0.3), rx: 0.6, ry: 0.25, from: -.pi / 2, to: .pi / 2),
                  direction: .curved)
    ]

    /// С — visually identical to Latin C.
    private static let esDefinition: [StrokeDef] = [
        StrokeDef(points: circleArc(center: p(0.5, 0.5), radius: 0.45, from: -.pi / 3, to: -5 * .pi / 3),
                  direction: .curved)
    ]

    /// Т — visually identical to Latin T.
    private static let teDefinition: [StrokeDef] = [
        StrokeDef(points: line(from: p(0.1, 0.05), to: p(0.9, 0.05)), direction: .leftToRight),
        StrokeDef(points: line(from: p(0.5, 0.05), to: p(0.5, 0.95)), direction: .topToBottom)
    ]

    /// Ћ — Т's top bar + full-height stem. The arch is shaped like the lower
    /// bump of Б/В (a quarter-ellipse off the stem) but left open at the
    /// bottom — a plain, straight leg to the baseline instead of curving
    /// back to close, and no curl at the foot (that's what distinguishes it
    /// from Ђ).
    private static let tsheDefinition: [StrokeDef] = [
        StrokeDef(points: line(from: p(0.1, 0.05), to: p(0.7, 0.05)), direction: .leftToRight),
        StrokeDef(points: line(from: p(0.4, 0.05), to: p(0.4, 0.95)), direction: .topToBottom),
        StrokeDef(points: ellipticalArc(center: p(0.4, 0.75), rx: 0.45, ry: 0.2, from: -.pi / 2, to: 0)
                  + line(from: p(0.85, 0.75), to: p(0.85, 0.95)).dropFirst(),
                  direction: .curved)
    ]

    /// У — visually identical to Latin Y.
    private static let uDefinition: [StrokeDef] = [
        StrokeDef(points: line(from: p(0.1, 0.05), to: p(0.5, 0.5)), direction: .diagonal(angle: 45)),
        StrokeDef(points: line(from: p(0.9, 0.05), to: p(0.5, 0.5)), direction: .diagonal(angle: -45)),
        StrokeDef(points: line(from: p(0.5, 0.5),  to: p(0.5, 0.95)), direction: .topToBottom)
    ]

    /// Ф — full-height spine through a circle (like the Greek phi it descends from).
    private static let efDefinition: [StrokeDef] = [
        StrokeDef(points: line(from: p(0.5, 0.05), to: p(0.5, 0.95)), direction: .topToBottom),
        StrokeDef(points: circleArc(center: p(0.5, 0.5), radius: 0.35, from: -.pi / 2, to: 3 * .pi / 2),
                  direction: .curved)
    ]

    /// Х — visually identical to Latin X.
    private static let haDefinition: [StrokeDef] = [
        StrokeDef(points: line(from: p(0.1, 0.05), to: p(0.9, 0.95)), direction: .diagonal(angle: 45)),
        StrokeDef(points: line(from: p(0.9, 0.05), to: p(0.1, 0.95)), direction: .diagonal(angle: -45))
    ]

    /// Ц — traced from the system font: a U-shaped curve with a small
    /// descending foot near the bottom-*right* (close to the right stroke) —
    /// this is the feature that distinguishes it from Џ's centred foot.
    private static let tseDefinition: [StrokeDef] = [
        StrokeDef(points:
                    line(from: p(0.1, 0.05), to: p(0.1, 0.7), steps: 6)
                  + curveThrough(from: p(0.1, 0.7), peak: p(0.5, 0.9), to: p(0.85, 0.7)).dropFirst()
                  + line(from: p(0.85, 0.7), to: p(0.85, 0.05), steps: 6).dropFirst(),
                  direction: .curved),
        StrokeDef(points: line(from: p(0.75, 0.85), to: p(0.75, 0.98)), direction: .topToBottom)
    ]

    /// Ч — full-height right spine with a hooked arch curving in from the upper-left
    /// (a mirror image of Latin lowercase h).
    private static let cheDefinition: [StrokeDef] = [
        StrokeDef(points: line(from: p(0.75, 0.05), to: p(0.75, 0.95)), direction: .topToBottom),
        StrokeDef(points: curveThrough(from: p(0.15, 0.05), peak: p(0.15, 0.35), to: p(0.75, 0.5)), direction: .curved)
    ]

    /// Џ — traced from the system font: the same U-shaped curve as Ц, but
    /// with the descending foot centred (not near the right stroke) — that
    /// centred position is what distinguishes it from Ц.
    private static let dzheDefinition: [StrokeDef] = [
        StrokeDef(points:
                    line(from: p(0.1, 0.05), to: p(0.1, 0.7), steps: 6)
                  + curveThrough(from: p(0.1, 0.7), peak: p(0.5, 0.9), to: p(0.85, 0.7)).dropFirst()
                  + line(from: p(0.85, 0.7), to: p(0.85, 0.05), steps: 6).dropFirst(),
                  direction: .curved),
        StrokeDef(points: line(from: p(0.47, 0.85), to: p(0.47, 0.98)), direction: .topToBottom)
    ]

    /// Ш — a three-tine comb: three verticals joined by a bottom bar.
    private static let shaDefinition: [StrokeDef] = [
        StrokeDef(points: line(from: p(0.1, 0.05), to: p(0.1, 0.95)), direction: .topToBottom),
        StrokeDef(points: line(from: p(0.5, 0.05), to: p(0.5, 0.95)), direction: .topToBottom),
        StrokeDef(points: line(from: p(0.9, 0.05), to: p(0.9, 0.95)), direction: .topToBottom),
        StrokeDef(points: line(from: p(0.1, 0.95), to: p(0.9, 0.95)), direction: .leftToRight)
    ]

    // MARK: - Lowercase definitions
    //
    // Body zone: y 0.20–0.85, same physical scale as uppercase letters,
    // mirroring `StrokeTemplate`'s Latin lowercase convention. Ascenders
    // (б, ђ, ј [descender+ascender via hook start], ф) extend to y: 0.05;
    // descenders (ђ, р, у, ф, ц, џ, ћ) reach to y: ~0.95. Most letters here
    // are simply the uppercase shape scaled into the body zone, since
    // upright-print Serbian Cyrillic lowercase mirrors uppercase far more
    // often than Latin does.

    /// а — visually identical to Latin a (round bowl + right stem), unlike
    /// most other lowercase letters in this file: Cyrillic standardized on
    /// the Latin-style round form for а rather than a scaled-down А.
    private static let aLowerDefinition: [StrokeDef] = [
        StrokeDef(points: circleArc(center: p(0.42, 0.52), radius: 0.30, from: -.pi / 2, to: 3 * .pi / 2),
                  direction: .curved),
        StrokeDef(points: line(from: p(0.72, 0.22), to: p(0.72, 0.85)), direction: .topToBottom)
    ]

    /// б — ascender spine, small top bar, bottom bowl (like a taller Б).
    private static let beLowerDefinition: [StrokeDef] = [
        StrokeDef(points: line(from: p(0.2, 0.05), to: p(0.2, 0.85)), direction: .topToBottom),
        StrokeDef(points: line(from: p(0.2, 0.05), to: p(0.55, 0.05)), direction: .leftToRight),
        StrokeDef(points: ellipticalArc(center: p(0.2, 0.6), rx: 0.55, ry: 0.25, from: -.pi / 2, to: .pi / 2),
                  direction: .curved)
    ]

    /// в — scaled-down В.
    private static let veLowerDefinition: [StrokeDef] = [
        StrokeDef(points: line(from: p(0.15, 0.2), to: p(0.15, 0.85)), direction: .topToBottom),
        StrokeDef(points:
                    ellipticalArc(center: p(0.15, 0.36), rx: 0.5, ry: 0.16, from: -.pi / 2, to: .pi / 2)
                  + ellipticalArc(center: p(0.15, 0.69), rx: 0.55, ry: 0.16, from: -.pi / 2, to: .pi / 2).dropFirst(),
                  direction: .curved)
    ]

    /// г — scaled-down Г.
    private static let geLowerDefinition: [StrokeDef] = [
        StrokeDef(points: line(from: p(0.15, 0.2), to: p(0.75, 0.2)), direction: .leftToRight),
        StrokeDef(points: line(from: p(0.15, 0.2), to: p(0.15, 0.85)), direction: .topToBottom)
    ]

    /// д — scaled-down Д (top bar, two feet, bottom bar).
    private static let deLowerDefinition: [StrokeDef] = [
        StrokeDef(points: line(from: p(0.15, 0.2), to: p(0.85, 0.2)), direction: .leftToRight),
        StrokeDef(points: line(from: p(0.15, 0.2), to: p(0.15, 0.75)) + line(from: p(0.15, 0.75), to: p(0.05, 0.85)).dropFirst(),
                  direction: .topToBottom),
        StrokeDef(points: line(from: p(0.85, 0.2), to: p(0.85, 0.75)) + line(from: p(0.85, 0.75), to: p(0.95, 0.85)).dropFirst(),
                  direction: .topToBottom),
        StrokeDef(points: line(from: p(0.15, 0.75), to: p(0.85, 0.75)), direction: .leftToRight)
    ]

    /// ђ — same т-style crossbar and full-height stem as ћ. The arch is
    /// shaped like б's bowl (a quarter-ellipse off the stem) but left open
    /// at the bottom, then curls back near the very end, matching Ђ and
    /// distinguishing it from ћ's plain straight leg.
    private static let djeLowerDefinition: [StrokeDef] = [
        StrokeDef(points: line(from: p(0.1, 0.18), to: p(0.4, 0.18)), direction: .leftToRight),
        StrokeDef(points: line(from: p(0.25, 0.05), to: p(0.25, 0.85), steps: 8), direction: .topToBottom),
        StrokeDef(points: ellipticalArc(center: p(0.25, 0.68), rx: 0.4, ry: 0.17, from: -.pi / 2, to: 0)
                  + line(from: p(0.65, 0.68), to: p(0.65, 0.72), steps: 2).dropFirst()
                  + curveThrough(from: p(0.65, 0.72), peak: p(0.55, 0.88), to: p(0.4, 0.8)).dropFirst(),
                  direction: .curved)
    ]

    /// е — visually identical to Latin e: crossbar + reverse-C arc.
    private static let ieLowerDefinition: [StrokeDef] = [
        StrokeDef(points: line(from: p(0.12, 0.5), to: p(0.88, 0.5)), direction: .leftToRight),
        StrokeDef(points: circleArc(center: p(0.5, 0.5), radius: 0.38, from: 0, to: -5 * .pi / 3), direction: .curved)
    ]

    /// ж — scaled-down Ж.
    private static let zheLowerDefinition: [StrokeDef] = [
        StrokeDef(points: line(from: p(0.5, 0.2), to: p(0.5, 0.85)), direction: .topToBottom),
        StrokeDef(points: line(from: p(0.1, 0.2), to: p(0.5, 0.52)), direction: .diagonal(angle: 45)),
        StrokeDef(points: line(from: p(0.5, 0.52), to: p(0.1, 0.85)), direction: .diagonal(angle: -45)),
        StrokeDef(points: line(from: p(0.9, 0.2), to: p(0.5, 0.52)), direction: .diagonal(angle: -45)),
        StrokeDef(points: line(from: p(0.5, 0.52), to: p(0.9, 0.85)), direction: .diagonal(angle: 45))
    ]

    /// з — scaled-down З.
    private static let zeLowerDefinition: [StrokeDef] = [
        StrokeDef(points:
                    ellipticalArc(center: p(0.4, 0.36), rx: 0.38, ry: 0.16, from: -.pi / 2, to: .pi / 2)
                  + ellipticalArc(center: p(0.4, 0.69), rx: 0.42, ry: 0.16, from: -.pi / 2, to: .pi / 2).dropFirst(),
                  direction: .curved)
    ]

    /// и — scaled-down И.
    private static let iLowerDefinition: [StrokeDef] = [
        StrokeDef(points: line(from: p(0.15, 0.2), to: p(0.15, 0.85)), direction: .topToBottom),
        StrokeDef(points: line(from: p(0.15, 0.85), to: p(0.85, 0.2)), direction: .diagonal(angle: -45)),
        StrokeDef(points: line(from: p(0.85, 0.2), to: p(0.85, 0.85)), direction: .topToBottom)
    ]

    /// ј — stem with a descending hooked tail. Unlike Latin j, print Serbian ј has no dot.
    private static let jeLowerDefinition: [StrokeDef] = [
        StrokeDef(points: line(from: p(0.5, 0.2), to: p(0.5, 0.8), steps: 5)
                  + curveThrough(from: p(0.5, 0.8), peak: p(0.33, 0.95), to: p(0.17, 0.88)).dropFirst(),
                  direction: .topToBottom)
    ]

    /// к — scaled-down К.
    private static let kaLowerDefinition: [StrokeDef] = [
        StrokeDef(points: line(from: p(0.15, 0.2), to: p(0.15, 0.85)), direction: .topToBottom),
        StrokeDef(points: line(from: p(0.85, 0.2), to: p(0.15, 0.53)), direction: .diagonal(angle: -45)),
        StrokeDef(points: line(from: p(0.15, 0.53), to: p(0.85, 0.85)), direction: .diagonal(angle: 45))
    ]

    /// л — scaled-down Л.
    private static let elLowerDefinition: [StrokeDef] = [
        StrokeDef(points: line(from: p(0.15, 0.85), to: p(0.5, 0.2)), direction: .diagonal(angle: -45)),
        StrokeDef(points: line(from: p(0.5, 0.2),  to: p(0.85, 0.85)), direction: .diagonal(angle: 45))
    ]

    /// љ — an arch (top bar + left leg with a curved outward foot) with a
    /// right-bulging bowl hinged on the right leg.
    private static let ljeLowerDefinition: [StrokeDef] = [
        StrokeDef(points: line(from: p(0.2, 0.2), to: p(0.55, 0.2)), direction: .leftToRight),
        StrokeDef(points: line(from: p(0.2, 0.2), to: p(0.2, 0.7), steps: 5)
                  + curveThrough(from: p(0.2, 0.7), peak: p(0.12, 0.87), to: p(0.05, 0.8)).dropFirst(),
                  direction: .topToBottom),
        StrokeDef(points: line(from: p(0.55, 0.2), to: p(0.55, 0.85)), direction: .topToBottom),
        StrokeDef(points: ellipticalArc(center: p(0.55, 0.68), rx: 0.35, ry: 0.18, from: -.pi / 2, to: .pi / 2),
                  direction: .curved)
    ]

    /// м — scaled-down М.
    private static let emLowerDefinition: [StrokeDef] = [
        StrokeDef(points: line(from: p(0.1, 0.2), to: p(0.1, 0.85)), direction: .topToBottom),
        StrokeDef(points: line(from: p(0.1, 0.2), to: p(0.5, 0.68)), direction: .diagonal(angle: 45)),
        StrokeDef(points: line(from: p(0.5, 0.68), to: p(0.9, 0.2)), direction: .diagonal(angle: -45)),
        StrokeDef(points: line(from: p(0.9, 0.2), to: p(0.9, 0.85)), direction: .topToBottom)
    ]

    /// н — scaled-down Н (H-shape).
    private static let enLowerDefinition: [StrokeDef] = [
        StrokeDef(points: line(from: p(0.15, 0.2), to: p(0.15, 0.85)), direction: .topToBottom),
        StrokeDef(points: line(from: p(0.85, 0.2), to: p(0.85, 0.85)), direction: .topToBottom),
        StrokeDef(points: line(from: p(0.15, 0.52), to: p(0.85, 0.52)), direction: .leftToRight)
    ]

    /// њ — н's H-shape, but the right vertical stops partway down into a
    /// right-bulging bowl instead of continuing to the baseline.
    private static let njeLowerDefinition: [StrokeDef] = [
        StrokeDef(points: line(from: p(0.15, 0.2), to: p(0.15, 0.85)), direction: .topToBottom),
        StrokeDef(points: line(from: p(0.5, 0.2), to: p(0.5, 0.85)), direction: .topToBottom),
        StrokeDef(points: line(from: p(0.15, 0.5), to: p(0.5, 0.5)), direction: .leftToRight),
        StrokeDef(points: ellipticalArc(center: p(0.5, 0.68), rx: 0.4, ry: 0.18, from: -.pi / 2, to: .pi / 2),
                  direction: .curved)
    ]

    /// о — visually identical to Latin o.
    private static let oLowerDefinition: [StrokeDef] = [
        StrokeDef(points: circleArc(center: p(0.5, 0.5), radius: 0.38, from: -.pi / 2, to: 3 * .pi / 2),
                  direction: .curved)
    ]

    /// п — scaled-down П (arch).
    private static let peLowerDefinition: [StrokeDef] = [
        StrokeDef(points: line(from: p(0.12, 0.2), to: p(0.88, 0.2)), direction: .leftToRight),
        StrokeDef(points: line(from: p(0.12, 0.2), to: p(0.12, 0.85)), direction: .topToBottom),
        StrokeDef(points: line(from: p(0.88, 0.2), to: p(0.88, 0.85)), direction: .topToBottom)
    ]

    /// р — visually identical to Latin p: stem into the descender zone + top bowl.
    private static let erLowerDefinition: [StrokeDef] = [
        StrokeDef(points: line(from: p(0.2, 0.2), to: p(0.2, 0.95)), direction: .topToBottom),
        StrokeDef(points: ellipticalArc(center: p(0.2, 0.38), rx: 0.55, ry: 0.2, from: -.pi / 2, to: .pi / 2),
                  direction: .curved)
    ]

    /// с — visually identical to Latin c.
    private static let esLowerDefinition: [StrokeDef] = [
        StrokeDef(points: circleArc(center: p(0.5, 0.5), radius: 0.38, from: -.pi / 3, to: -5 * .pi / 3),
                  direction: .curved)
    ]

    /// т — scaled-down Т.
    private static let teLowerDefinition: [StrokeDef] = [
        StrokeDef(points: line(from: p(0.15, 0.2), to: p(0.85, 0.2)), direction: .leftToRight),
        StrokeDef(points: line(from: p(0.5, 0.2), to: p(0.5, 0.85)), direction: .topToBottom)
    ]

    /// ћ — a plain flat crossbar near the ascender top, a full-height stem.
    /// The arch is shaped like б's bowl (a quarter-ellipse off the stem)
    /// but left open at the bottom — a plain, straight leg to the baseline
    /// instead of curving back to close, and no curl at the foot (that's
    /// what distinguishes it from ђ).
    private static let tsheLowerDefinition: [StrokeDef] = [
        StrokeDef(points: line(from: p(0.1, 0.18), to: p(0.4, 0.18)), direction: .leftToRight),
        StrokeDef(points: line(from: p(0.25, 0.05), to: p(0.25, 0.85), steps: 8), direction: .topToBottom),
        StrokeDef(points: ellipticalArc(center: p(0.25, 0.68), rx: 0.4, ry: 0.17, from: -.pi / 2, to: 0)
                  + line(from: p(0.65, 0.68), to: p(0.65, 0.85)).dropFirst(),
                  direction: .curved)
    ]

    /// у — visually similar to Latin y: two diagonals meeting, descending into a hooked tail.
    private static let uLowerDefinition: [StrokeDef] = [
        StrokeDef(points: line(from: p(0.15, 0.2), to: p(0.5, 0.55)), direction: .diagonal(angle: 45)),
        StrokeDef(points: line(from: p(0.85, 0.2), to: p(0.5, 0.55), steps: 4)
                  + line(from: p(0.5, 0.55), to: p(0.5, 0.8), steps: 3).dropFirst()
                  + curveThrough(from: p(0.5, 0.8), peak: p(0.35, 0.95), to: p(0.2, 0.88)).dropFirst(),
                  direction: .topToBottom)
    ]

    /// ф — full ascender-to-descender stem through a circle.
    private static let efLowerDefinition: [StrokeDef] = [
        StrokeDef(points: line(from: p(0.5, 0.05), to: p(0.5, 0.95)), direction: .topToBottom),
        StrokeDef(points: circleArc(center: p(0.5, 0.5), radius: 0.32, from: -.pi / 2, to: 3 * .pi / 2),
                  direction: .curved)
    ]

    /// х — scaled-down Х.
    private static let haLowerDefinition: [StrokeDef] = [
        StrokeDef(points: line(from: p(0.15, 0.2), to: p(0.85, 0.85)), direction: .diagonal(angle: 45)),
        StrokeDef(points: line(from: p(0.85, 0.2), to: p(0.15, 0.85)), direction: .diagonal(angle: -45))
    ]

    /// ц — traced from the system font: a U-curve with a small descending
    /// foot near the bottom-*right* (close to the right stroke) — the
    /// feature distinguishing it from џ's centred foot.
    private static let tseLowerDefinition: [StrokeDef] = [
        StrokeDef(points:
                    line(from: p(0.15, 0.2), to: p(0.15, 0.7), steps: 5)
                  + curveThrough(from: p(0.15, 0.7), peak: p(0.5, 0.85), to: p(0.85, 0.7)).dropFirst()
                  + line(from: p(0.85, 0.7), to: p(0.85, 0.2), steps: 5).dropFirst(),
                  direction: .curved),
        StrokeDef(points: line(from: p(0.7, 0.8), to: p(0.7, 0.95)), direction: .topToBottom)
    ]

    /// ч — scaled-down Ч.
    private static let cheLowerDefinition: [StrokeDef] = [
        StrokeDef(points: line(from: p(0.75, 0.2), to: p(0.75, 0.85)), direction: .topToBottom),
        StrokeDef(points: curveThrough(from: p(0.2, 0.2), peak: p(0.2, 0.45), to: p(0.75, 0.55)), direction: .curved)
    ]

    /// џ — traced from the system font: the same U-curve as ц, but with the
    /// descending foot centred instead of near the right stroke.
    private static let dzheLowerDefinition: [StrokeDef] = [
        StrokeDef(points:
                    line(from: p(0.15, 0.2), to: p(0.15, 0.7), steps: 5)
                  + curveThrough(from: p(0.15, 0.7), peak: p(0.5, 0.85), to: p(0.85, 0.7)).dropFirst()
                  + line(from: p(0.85, 0.7), to: p(0.85, 0.2), steps: 5).dropFirst(),
                  direction: .curved),
        StrokeDef(points: line(from: p(0.47, 0.8), to: p(0.47, 0.95)), direction: .topToBottom)
    ]

    /// ш — scaled-down Ш.
    private static let shaLowerDefinition: [StrokeDef] = [
        StrokeDef(points: line(from: p(0.12, 0.2), to: p(0.12, 0.85)), direction: .topToBottom),
        StrokeDef(points: line(from: p(0.5, 0.2),  to: p(0.5, 0.85)), direction: .topToBottom),
        StrokeDef(points: line(from: p(0.88, 0.2), to: p(0.88, 0.85)), direction: .topToBottom),
        StrokeDef(points: line(from: p(0.12, 0.85), to: p(0.88, 0.85)), direction: .leftToRight)
    ]
}

// MARK: - Primitive forwarding
//
// Mirrors `StrokeTemplate`'s own primitive names so the letter definitions
// above read identically to the Latin definitions in `StrokeTemplate.swift`.
private extension CyrillicStrokeDefinitions {

    static func p(_ x: Double, _ y: Double) -> CGPoint {
        StrokeTemplate.p(x, y)
    }

    static func line(from a: CGPoint, to b: CGPoint, steps: Int = 10) -> [CGPoint] {
        StrokeTemplate.line(from: a, to: b, steps: steps)
    }

    static func curveThrough(from p0: CGPoint, peak: CGPoint, to p1: CGPoint, steps: Int = 16) -> [CGPoint] {
        StrokeTemplate.curveThrough(from: p0, peak: peak, to: p1, steps: steps)
    }

    static func bezier(_ p0: CGPoint, _ c: CGPoint, _ p1: CGPoint, steps: Int = 16) -> [CGPoint] {
        StrokeTemplate.bezier(p0, c, p1, steps: steps)
    }

    static func circleArc(center: CGPoint, radius: Double, from startAngle: Double, to endAngle: Double, steps: Int = 20) -> [CGPoint] {
        StrokeTemplate.circleArc(center: center, radius: radius, from: startAngle, to: endAngle, steps: steps)
    }

    static func ellipticalArc(center: CGPoint, rx: Double, ry: Double, from startAngle: Double, to endAngle: Double, steps: Int = 20) -> [CGPoint] {
        StrokeTemplate.ellipticalArc(center: center, rx: rx, ry: ry, from: startAngle, to: endAngle, steps: steps)
    }
}
