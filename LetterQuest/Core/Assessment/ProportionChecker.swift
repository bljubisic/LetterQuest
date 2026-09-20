import Foundation
import CoreGraphics
import PencilKit

/// Checks whether the drawn letter respects the four guide lines shown on the canvas.
///
/// The three sub-scores are:
/// - **Baseline** (40 %): Does the bottom of the letter sit near the red line?
/// - **Height** (40 %): Is the letter the correct height for its character class
///   (regular, ascender, or descender)?
/// - **Width** (20 %): Is the letter neither too tiny (< 5 % of canvas) nor too
///   sprawling (> 80 % of canvas)?
final class ProportionChecker {

    // MARK: - Guide line descriptor

    /// The Y-positions of the four guide lines, plus the canvas bounding box.
    ///
    /// All values are in the canvas's own coordinate space.
    /// Create with `forCanvas(size:)` once the canvas frame is known.
    struct Guidelines {

        /// Y position of the ascender line (top dashed blue line, 20 % down).
        let ascenderY: CGFloat

        /// Y position of the x-height line (solid blue line, 45 % down).
        let xHeightY: CGFloat

        /// Y position of the baseline (solid red line, 70 % down).
        let baselineY: CGFloat

        /// Y position of the descender line (bottom dashed blue line, 85 % down).
        let descenderY: CGFloat

        /// The full canvas frame in canvas coordinates.
        let canvasBounds: CGRect

        /// Creates guide lines for a canvas of the given `size`.
        ///
        /// - Parameter size: The actual pixel dimensions of the `PKCanvasView`.
        /// - Returns: A `Guidelines` value calibrated to that canvas.
        static func forCanvas(size: CGSize) -> Guidelines {
            Guidelines(
                ascenderY:   size.height * 0.20,
                xHeightY:    size.height * 0.45,
                baselineY:   size.height * 0.70,
                descenderY:  size.height * 0.85,
                canvasBounds: CGRect(origin: .zero, size: size)
            )
        }
    }

    // MARK: - Public interface

    /// Scores the geometric proportions of drawn strokes against the guide lines (0–100).
    ///
    /// - Parameters:
    ///   - strokes: The strokes drawn by the child.
    ///   - letter: The target letter; its character determines the expected height class.
    ///   - guidelines: The guide-line positions for the current canvas.
    /// - Returns: A weighted proportion score in **0–100**.
    func score(strokes: [PKStroke], letter: Letter, guidelines: Guidelines) -> Int {
        let bounds = computeBoundingBox(strokes)
        guard !bounds.isEmpty else { return 0 }

        let baselineScore = scoreBaseline(bounds, letter: letter, guidelines: guidelines)
        let heightScore   = scoreHeight(bounds, letter: letter, guidelines: guidelines)
        let widthScore    = scoreWidth(bounds, guidelines: guidelines)

        return Int(baselineScore * 0.4 + heightScore * 0.4 + widthScore * 0.2)
    }

    // MARK: - Sub-scores

    /// Penalises deviation of the letter's bottom edge from the expected bottom guide line.
    ///
    /// Uppercase and lowercase use different target lines because lowercase templates
    /// now span the full body zone (y 0.20–0.85), landing near the descender guide.
    private func scoreBaseline(_ bounds: CGRect, letter: Letter, guidelines: Guidelines) -> Double {
        let targetY   = guidelines.baselineY
        let band      = guidelines.baselineY - guidelines.xHeightY
        let tolerance = max(band * 0.20, 1)
        let deviation = abs(bounds.maxY - targetY)
        // Multiplier 50: one tolerance-band off → score 50; two bands off → score 0.
        return max(0, 100 - (deviation / tolerance) * 50)
    }

    private func scoreHeight(_ bounds: CGRect, letter: Letter, guidelines: Guidelines) -> Double {
        let expectedHeight: CGFloat = guidelines.baselineY - guidelines.ascenderY

        guard expectedHeight > 0 else { return 100 }
        // Multiplier 100: letter at 50 % expected height scores 50; near-correct scores well.
        return max(0, 100 - abs(bounds.height / expectedHeight - 1.0) * 100)
    }

    /// Penalises letters that are too narrow or too wide relative to the canvas.
    ///
    /// Continuous scoring: ideal zone is 20–75 % of canvas width.
    /// - Below 5 %: score 20 (inherently narrow letters like "I" still get a floor).
    /// - 5–20 %: linear ramp 20 → 100.
    /// - 20–75 %: score 100.
    /// - 75–90 %: linear decay 100 → 40.
    /// - Above 90 %: score 20 (sprawling across the full canvas).
    private func scoreWidth(_ bounds: CGRect, guidelines: Guidelines) -> Double {
        let ratio = bounds.width / guidelines.canvasBounds.width
        if ratio < 0.05 { return 20 }
        if ratio < 0.20 { return 20 + (ratio - 0.05) / 0.15 * 80 }
        if ratio <= 0.75 { return 100 }
        if ratio <= 0.90 { return 100 - (ratio - 0.75) / 0.15 * 60 }
        return 20
    }

    // MARK: - Helpers

    private func computeBoundingBox(_ strokes: [PKStroke]) -> CGRect {
        strokes.reduce(.null) { $0.union($1.renderBounds) }
    }
}
