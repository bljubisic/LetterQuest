import SwiftUI

/// Draws dotted stroke-path guides and numbered start-point indicators for a letter.
///
/// Placed directly beneath the transparent `PKCanvasView` so the child can
/// see exactly where each stroke should go while drawing on top.
///
/// Visual layers per stroke (bottom → top):
/// 1. Wide, very faint band  — the approximate region to stay inside
/// 2. Dotted centreline      — the exact path to follow
/// 3. Numbered start circle  — shows which stroke to draw first, second, etc.
struct StrokeGuideOverlay: View {

    let templates: [StrokeTemplate]
    let canvasSize: CGSize
    let character: Character

    private static let palette: [Color] = [
        Color(red: 0.20, green: 0.55, blue: 1.00),   // blue
        Color(red: 1.00, green: 0.55, blue: 0.10),   // orange
        Color(red: 0.18, green: 0.72, blue: 0.40),   // green
        Color(red: 0.68, green: 0.28, blue: 0.92),   // purple
    ]

    var body: some View {
        Canvas { ctx, size in
            let zone = writingZone(in: size)
            for (index, template) in templates.enumerated() {
                let color = Self.palette[index % Self.palette.count]
                draw(template: template, color: color, in: ctx, zone: zone)
            }
        }
    }

    // MARK: - Writing zone

    /// The rectangle inside the canvas where the rendered letter should sit,
    /// matching the region `ProportionChecker` expects for this character class.
    ///
    /// Uppercase letters fill the cap-height band (ascender → baseline).
    /// Lowercase ascenders/descenders/regular each get their own band.
    /// The zone is square (width = height) and centred horizontally so traced
    /// letters land within the scorer's "ideal width" range.
    private func writingZone(in size: CGSize) -> CGRect {
        let ascenderY  = size.height * 0.20
        let xHeightY   = size.height * 0.45
        let baselineY  = size.height * 0.70
        let descenderY = size.height * 0.85

        let top: CGFloat
        let bottom: CGFloat
        switch character {
        case "b", "d", "f", "h", "k", "l", "t":
            top = ascenderY;  bottom = baselineY
        case "g", "j", "p", "q", "y":
            top = ascenderY;  bottom = descenderY
        default:
            if character.isUppercase {
                top = ascenderY; bottom = baselineY
            } else {
                top = xHeightY;  bottom = baselineY
            }
        }

        let height = bottom - top
        let width  = height                              // square zone
        let x      = (size.width - width) / 2
        return CGRect(x: x, y: top, width: width, height: height)
    }

    // MARK: - Per-stroke drawing

    private func draw(
        template: StrokeTemplate,
        color: Color,
        in ctx: GraphicsContext,
        zone: CGRect
    ) {
        let pts = template.points.map {
            CGPoint(x: zone.minX + $0.x * zone.width,
                    y: zone.minY + $0.y * zone.height)
        }
        guard pts.count >= 2 else { return }

        let path = makePath(from: pts)

        // Layer 1: wide faint halo showing the region to draw in.
        ctx.stroke(path, with: .color(color.opacity(0.10)),
                   style: StrokeStyle(lineWidth: 30, lineCap: .round, lineJoin: .round))

        // Layer 2: dotted centreline — the ideal path.
        // Round caps with a near-zero dash length produce circular dots.
        ctx.stroke(path, with: .color(color.opacity(0.45)),
                   style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round,
                                      dash: [0.1, 11]))

        // Layer 3: start indicator circle with stroke number.
        drawStartIndicator(at: pts[0], number: template.strokeIndex + 1,
                           color: color, ctx: ctx)
    }

    private func makePath(from pts: [CGPoint]) -> Path {
        var path = Path()
        path.move(to: pts[0])
        for pt in pts.dropFirst() {
            path.addLine(to: pt)
        }
        return path
    }

    private func drawStartIndicator(
        at point: CGPoint,
        number: Int,
        color: Color,
        ctx: GraphicsContext
    ) {
        let r: CGFloat = 13
        let rect = CGRect(x: point.x - r, y: point.y - r, width: r * 2, height: r * 2)

        // White halo so the circle reads clearly on the dotted line.
        ctx.fill(Path(ellipseIn: rect.insetBy(dx: -2, dy: -2)), with: .color(.white.opacity(0.85)))
        ctx.fill(Path(ellipseIn: rect), with: .color(color.opacity(0.9)))

        // Stroke number — only shown for multi-stroke letters.
        if number > 0 {
            let label = Text("\(number)")
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .foregroundColor(.white)
            ctx.draw(label, at: point)
        }
    }
}

// MARK: - Preview

#Preview {
    let letter = Letter.alphabet.first { $0.character == "A" }!
    StrokeGuideOverlay(
        templates: letter.strokeTemplates,
        canvasSize: CGSize(width: 380, height: 380),
        character: letter.character
    )
    .frame(width: 380, height: 380)
    .background(Color.white)
    .clipShape(RoundedRectangle(cornerRadius: 20))
    .padding()
}
