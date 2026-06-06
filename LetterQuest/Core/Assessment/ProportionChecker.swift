import Foundation
import CoreGraphics
import PencilKit

final class ProportionChecker {

    struct Guidelines {
        let baselineY: CGFloat
        let xHeightY: CGFloat
        let ascenderY: CGFloat
        let descenderY: CGFloat
        let canvasBounds: CGRect

        static func forCanvas(size: CGSize) -> Guidelines {
            Guidelines(
                baselineY:  size.height * 0.70,
                xHeightY:   size.height * 0.45,
                ascenderY:  size.height * 0.20,
                descenderY: size.height * 0.85,
                canvasBounds: CGRect(origin: .zero, size: size)
            )
        }
    }

    func score(strokes: [PKStroke], letter: Letter, guidelines: Guidelines) -> Int {
        let bounds = computeBoundingBox(strokes)
        guard !bounds.isEmpty else { return 0 }

        let baseline    = scoreBaseline(bounds, guidelines: guidelines)
        let heightScore = scoreHeight(bounds, character: letter.character, guidelines: guidelines)
        let widthScore  = scoreWidth(bounds, guidelines: guidelines)

        return Int(baseline * 0.4 + heightScore * 0.4 + widthScore * 0.2)
    }

    // MARK: - Individual checks

    private func scoreBaseline(_ bounds: CGRect, guidelines: Guidelines) -> Double {
        let tolerance = (guidelines.baselineY - guidelines.xHeightY) * 0.2
        let deviation = abs(bounds.maxY - guidelines.baselineY)
        return max(0, 100 - (deviation / max(tolerance, 1)) * 30)
    }

    private func scoreHeight(_ bounds: CGRect, character: Character, guidelines: Guidelines) -> Double {
        let expectedHeight: CGFloat
        switch character {
        case "b", "d", "f", "h", "k", "l", "t":
            expectedHeight = guidelines.baselineY - guidelines.ascenderY
        case "g", "j", "p", "q", "y":
            expectedHeight = guidelines.descenderY - guidelines.ascenderY
        default:
            expectedHeight = guidelines.baselineY - guidelines.xHeightY
        }

        guard expectedHeight > 0 else { return 100 }
        let ratio = bounds.height / expectedHeight
        return max(0, 100 - abs(ratio - 1.0) * 80)
    }

    private func scoreWidth(_ bounds: CGRect, guidelines: Guidelines) -> Double {
        let widthRatio = bounds.width / guidelines.canvasBounds.width
        if widthRatio < 0.05 { return 20 }
        if widthRatio > 0.80 { return 40 }
        return 100
    }

    // MARK: - Helpers

    private func computeBoundingBox(_ strokes: [PKStroke]) -> CGRect {
        strokes.reduce(.null) { $0.union($1.renderBounds) }
    }
}
