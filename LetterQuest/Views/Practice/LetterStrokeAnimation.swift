import SwiftUI

/// An animated demonstration of how to draw the target letter, displayed
/// above the canvas as the child's first introduction to the strokes.
///
/// Behaviour:
/// - Plays automatically when a new letter appears (`.id(letter.id)` triggers
///   a fresh `onAppear`).
/// - Tap the glyph to replay.
///
/// The animation drives each stroke's `Shape` through `.trim(from: 0, to:)`,
/// so each polyline draws progressively from start to finish in the same
/// order as the underlying `StrokeTemplate` array. Because the on-canvas
/// `StrokeGuideOverlay` consumes the same data, the demo and the guide
/// stay perfectly in sync.
struct LetterStrokeAnimation: View {

    let letter: Letter

    /// One progress value (0…1) per stroke, animated independently.
    @State private var progresses: [CGFloat] = []

    /// Guards against overlapping replays when the user taps mid-animation.
    @State private var isPlaying = false

    // MARK: - Tuning

    private static let glyphSide: CGFloat       = 110     // outer header size
    private static let strokeAreaSide: CGFloat  = 90      // strokes' square
    private static let strokeWidth: CGFloat     = 7
    private static let strokeDuration: Double   = 0.9     // per-stroke draw
    private static let interStrokePause: Double = 0.30    // gap between strokes

    var body: some View {
        ZStack {
            // Both the ghost background and the animated foreground are
            // rendered from the same `StrokeTemplate` data so the destination
            // shape and the demonstration always trace the same path.
            ForEach(Array(letter.strokeTemplates.enumerated()), id: \.offset) { index, template in
                // Faint full-shape ghost — shows the destination at all times.
                StrokePathShape(points: template.points)
                    .stroke(
                        Color.blue.opacity(0.15),
                        style: StrokeStyle(
                            lineWidth: Self.strokeWidth,
                            lineCap: .round,
                            lineJoin: .round
                        )
                    )

                // Vivid animated stroke — trims from 0 to 1 to "draw" the path.
                StrokePathShape(points: template.points)
                    .trim(from: 0, to: progress(for: index))
                    .stroke(
                        Color.blue,
                        style: StrokeStyle(
                            lineWidth: Self.strokeWidth,
                            lineCap: .round,
                            lineJoin: .round
                        )
                    )
            }
        }
        .frame(width: Self.strokeAreaSide, height: Self.strokeAreaSide)
        .padding(.vertical, (Self.glyphSide - Self.strokeAreaSide) / 2)
        .contentShape(Rectangle())
        .onTapGesture { Task { await play() } }
        .onAppear { Task { await play() } }
    }

    // MARK: - Helpers

    private func progress(for index: Int) -> CGFloat {
        index < progresses.count ? progresses[index] : 0
    }

    /// Runs the full stroke-by-stroke replay.
    ///
    /// All progress values are reset to 0 inside a non-animated transaction so
    /// the previous run vanishes instantly; each stroke then animates from
    /// 0 → 1 with a short pause between strokes.
    private func play() async {
        guard !isPlaying else { return }
        isPlaying = true
        defer { isPlaying = false }

        var resetTransaction = Transaction()
        resetTransaction.disablesAnimations = true
        withTransaction(resetTransaction) {
            progresses = Array(repeating: 0, count: letter.strokeTemplates.count)
        }

        for i in 0..<letter.strokeTemplates.count {
            withAnimation(.easeInOut(duration: Self.strokeDuration)) {
                progresses[i] = 1.0
            }
            try? await Task.sleep(nanoseconds: UInt64(Self.strokeDuration * 1_000_000_000))
            try? await Task.sleep(nanoseconds: UInt64(Self.interStrokePause * 1_000_000_000))
        }
    }
}

// MARK: - Stroke Shape

/// A `Shape` that maps a normalised `[CGPoint]` array (each component in 0…1)
/// onto the supplied rectangle, producing a polyline path.
///
/// Implementing this as a `Shape` (rather than rendering directly into a
/// `Canvas`) is what lets `.trim(from:to:)` animate the path's draw progress.
private struct StrokePathShape: Shape {

    let points: [CGPoint]

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard let first = points.first else { return path }

        path.move(to: CGPoint(
            x: rect.minX + first.x * rect.width,
            y: rect.minY + first.y * rect.height
        ))
        for pt in points.dropFirst() {
            path.addLine(to: CGPoint(
                x: rect.minX + pt.x * rect.width,
                y: rect.minY + pt.y * rect.height
            ))
        }
        return path
    }
}

// MARK: - Preview

#Preview {
    let letter = Letter.alphabet.first { $0.character == "A" }!
    return LetterStrokeAnimation(letter: letter)
        .padding()
}
