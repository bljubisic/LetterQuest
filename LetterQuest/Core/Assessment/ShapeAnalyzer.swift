import Foundation
import CoreGraphics
import UIKit
import PencilKit

/// Compares the overall shape of a drawn letter against a reference bitmap.
///
/// **Algorithm**
/// 1. Render the drawn strokes onto a 64 × 64 grayscale canvas, normalised to fit.
/// 2. Compare the result pixel-by-pixel with a reference template image (also 64 × 64)
///    using **Intersection over Union (IoU)** — the standard object-detection metric.
///
/// An IoU of 1.0 (all ink pixels overlap perfectly) maps to a score of 100.
/// An IoU of 0 (no overlap at all) maps to a score of 0.
///
/// When no template image asset is available, the assessor falls back to a neutral
/// score of 50 rather than zero-penalising the child.
final class ShapeAnalyzer {

    /// Side length of the normalised bitmap, in points.
    private let targetSize = CGSize(width: 64, height: 64)

    // MARK: - Public interface

    /// Scores the shape of the drawn strokes against a reference bitmap (0–100).
    ///
    /// - Parameters:
    ///   - strokes: The strokes drawn on the canvas.
    ///   - templateImage: The reference `CGImage` from the asset catalogue.
    /// - Returns: An IoU-based score in **0–100**.
    func score(strokes: [PKStroke], templateImage: CGImage) -> Int {
        guard let drawn = renderStrokes(strokes) else { return 0 }
        return iouScore(drawn: drawn, template: templateImage)
    }

    // MARK: - Rendering

    /// Renders all strokes into a 64 × 64 grayscale bitmap, scaled and centred.
    ///
    /// Returns `nil` when `strokes` is empty or produces a degenerate bounding box.
    private func renderStrokes(_ strokes: [PKStroke]) -> CGImage? {
        let allPoints = strokes.flatMap { stroke in
            (0..<stroke.path.count).map { stroke.path[$0].location }
        }
        guard !allPoints.isEmpty else { return nil }

        let bounds = allPoints.reduce(CGRect.null) { $0.union(CGRect(origin: $1, size: .zero)) }
        guard !bounds.isEmpty else { return nil }

        // Scale to fill the target size while preserving aspect ratio, with 15 % padding.
        let scale   = min(targetSize.width / bounds.width, targetSize.height / bounds.height) * 0.85
        let offsetX = (targetSize.width  - bounds.width  * scale) / 2 - bounds.minX * scale
        let offsetY = (targetSize.height - bounds.height * scale) / 2 - bounds.minY * scale

        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let image = renderer.image { ctx in
            UIColor.white.setFill()
            ctx.fill(CGRect(origin: .zero, size: targetSize))

            ctx.cgContext.setStrokeColor(UIColor.black.cgColor)
            ctx.cgContext.setLineWidth(3)
            ctx.cgContext.setLineCap(.round)
            ctx.cgContext.setLineJoin(.round)

            for stroke in strokes where stroke.path.count > 1 {
                let first = stroke.path[0].location
                ctx.cgContext.beginPath()
                ctx.cgContext.move(to: CGPoint(x: first.x * scale + offsetX,
                                               y: first.y * scale + offsetY))
                for i in 1..<stroke.path.count {
                    let pt = stroke.path[i].location
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
        return Int(Double(intersection) / Double(union) * 100)
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
