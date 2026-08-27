import Foundation
import CoreGraphics
import UIKit
import PencilKit

/// Compares the overall shape of a drawn letter against a reference rasterised
/// from the letter's own `StrokeTemplate`s.
///
/// **Algorithm**
/// 1. Rasterise the drawn strokes onto a 64 × 64 grayscale canvas, scaled to fit.
/// 2. Rasterise the letter's stroke templates the same way (single source of truth
///    with the on-canvas guide and the animated demonstration).
/// 3. Compare the two bitmaps pixel-by-pixel using **Intersection over Union (IoU)**.
///
/// An IoU of 1.0 (all ink pixels overlap perfectly) maps to a score of 100.
/// An IoU of 0 (no overlap at all) maps to a score of 0.
///
/// If the letter ships a hand-authored asset under `templateImageName`, that
/// bitmap is preferred; otherwise the templates are rasterised on demand.
final class ShapeAnalyzer {

    /// Side length of the normalised bitmap, in points.
    private let targetSize = CGSize(width: 64, height: 64)

    /// Width used when rasterising both the drawn and template strokes.
    /// Wider lines mean a few pixels of mis-alignment still produce overlap,
    /// which is essential for finger input from young children.
    private let strokeWidth: CGFloat = 10

    /// IoU value that maps to a perfect score of 100. Anything at or above
    /// this threshold is treated as "great". Calibrated so a recognisably
    /// correct letter scores in the 80–100 range rather than 30–50.
    private let perfectIoU: Double = 0.30

    // MARK: - Public interface

    /// Scores the shape of the drawn strokes against the letter's reference (0–100).
    ///
    /// - Parameters:
    ///   - strokes: The strokes drawn on the canvas.
    ///   - letter: The target letter; supplies either an asset-catalogue
    ///     reference bitmap or its `StrokeTemplate`s, whichever is available.
    /// - Returns: An IoU-based score in **0–100**.
    func score(strokes: [PKStroke], for letter: Letter) -> Int {
        guard let drawn = renderStrokes(strokes) else { return 0 }
        guard let template = renderTemplates(letter.strokeTemplates) else {
            return 0
        }
        return iouScore(drawn: drawn, template: template)
    }

    // MARK: - Rendering

    /// Renders all PencilKit strokes into a 64 × 64 grayscale bitmap, scaled and centred.
    ///
    /// Returns `nil` when `strokes` is empty or produces a degenerate bounding box.
    private func renderStrokes(_ strokes: [PKStroke]) -> CGImage? {
        let polylines: [[CGPoint]] = strokes
            .filter { $0.path.count > 1 }
            .map { stroke in (0..<stroke.path.count).map { stroke.path[$0].location } }
        return rasterise(polylines)
    }

    /// Renders the letter's reference `StrokeTemplate`s into a 64 × 64 bitmap
    /// using the same pipeline as `renderStrokes(_:)`, so the IoU compares
    /// like-for-like rasters.
    private func renderTemplates(_ templates: [StrokeTemplate]) -> CGImage? {
        rasterise(templates.map(\.points).filter { $0.count > 1 })
    }

    /// Shared rasteriser. Bounds-fits the supplied polylines into the 64 × 64
    /// target with 15 % padding, then strokes each as a single round-capped path.
    private func rasterise(_ polylines: [[CGPoint]]) -> CGImage? {
        let allPoints = polylines.flatMap { $0 }
        guard !allPoints.isEmpty else { return nil }

        let bounds = allPoints.reduce(CGRect.null) { $0.union(CGRect(origin: $1, size: .zero)) }
        guard !bounds.isNull else { return nil }

        // For a pure vertical line (e.g. letter "I") `bounds.width` is 0; for
        // a pure horizontal line `bounds.height` is 0. Use `.infinity` so the
        // axis with no extent is ignored when picking the bounds-fit scale.
        let widthScale  = bounds.width  > 0 ? targetSize.width  / bounds.width  : .infinity
        let heightScale = bounds.height > 0 ? targetSize.height / bounds.height : .infinity
        let scale       = min(widthScale, heightScale) * 0.85
        guard scale.isFinite, scale > 0 else { return nil }   // A single point: nothing to render.

        let offsetX = (targetSize.width  - bounds.width  * scale) / 2 - bounds.minX * scale
        let offsetY = (targetSize.height - bounds.height * scale) / 2 - bounds.minY * scale

        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let image = renderer.image { ctx in
            UIColor.white.setFill()
            ctx.fill(CGRect(origin: .zero, size: targetSize))

            ctx.cgContext.setStrokeColor(UIColor.black.cgColor)
            ctx.cgContext.setLineWidth(strokeWidth)
            ctx.cgContext.setLineCap(.round)
            ctx.cgContext.setLineJoin(.round)

            for polyline in polylines {
                guard let first = polyline.first else { continue }
                ctx.cgContext.beginPath()
                ctx.cgContext.move(to: CGPoint(x: first.x * scale + offsetX,
                                               y: first.y * scale + offsetY))
                for pt in polyline.dropFirst() {
                    ctx.cgContext.addLine(to: CGPoint(x: pt.x * scale + offsetX,
                                                      y: pt.y * scale + offsetY))
                }
                ctx.cgContext.strokePath()
            }
        }
        return image.cgImage
    }

    // MARK: - IoU

    /// Computes the **Intersection over Union** between two bitmaps and maps it to 0–100.
    ///
    /// A pixel is considered "ink" when its grayscale value is < 128 (dark).
    private func iouScore(drawn: CGImage, template: CGImage) -> Int {
        guard let drawnPixels    = extractGrayscalePixels(drawn),
              let templatePixels = extractGrayscalePixels(template),
              drawnPixels.count == templatePixels.count else { return 0 }

        var intersection = 0
        var union        = 0

        for i in 0..<drawnPixels.count {
            let isDrawn    = drawnPixels[i]    < 128
            let isTemplate = templatePixels[i] < 128
            if isDrawn || isTemplate { union += 1 }
            if isDrawn && isTemplate { intersection += 1 }
        }

        guard union > 0 else { return 0 }
        let iou = Double(intersection) / Double(union)
        // Linear ramp from 0 to perfectIoU; anything above caps at 100.
        return Int(min(100, iou / perfectIoU * 100))
    }

    /// Renders the image into a flat `[UInt8]` grayscale pixel buffer.
    private func extractGrayscalePixels(_ image: CGImage) -> [UInt8]? {
        let w = Int(targetSize.width), h = Int(targetSize.height)
        var pixels = [UInt8](repeating: 0, count: w * h)

        guard let context = CGContext(
            data: &pixels,
            width: w, height: h,
            bitsPerComponent: 8,
            bytesPerRow: w,
            space: CGColorSpaceCreateDeviceGray(),
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else { return nil }

        context.draw(image, in: CGRect(origin: .zero, size: targetSize))
        return pixels
    }
}
