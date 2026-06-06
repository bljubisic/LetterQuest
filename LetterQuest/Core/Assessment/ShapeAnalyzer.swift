import Foundation
import CoreGraphics
import UIKit
import PencilKit

final class ShapeAnalyzer {

    private let targetSize = CGSize(width: 64, height: 64)

    func score(strokes: [PKStroke], templateImage: CGImage) -> Int {
        guard let drawn = renderStrokes(strokes) else { return 0 }
        return iouScore(drawn: drawn, template: templateImage)
    }

    // MARK: - Rendering

    private func renderStrokes(_ strokes: [PKStroke]) -> CGImage? {
        let allPoints = strokes.flatMap { stroke in
            (0..<stroke.path.count).map { stroke.path[$0].location }
        }
        guard !allPoints.isEmpty else { return nil }

        let bounds = allPoints.reduce(CGRect.null) { $0.union(CGRect(origin: $1, size: .zero)) }
        guard !bounds.isEmpty else { return nil }

        let scale = min(targetSize.width / bounds.width, targetSize.height / bounds.height) * 0.85
        let offsetX = (targetSize.width  - bounds.width  * scale) / 2 - bounds.minX * scale
        let offsetY = (targetSize.height - bounds.height * scale) / 2 - bounds.minY * scale

        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let image = renderer.image { ctx in
            UIColor.white.setFill()
            ctx.fill(CGRect(origin: .zero, size: targetSize))
            UIColor.black.setStroke()
            ctx.cgContext.setLineWidth(3)
            ctx.cgContext.setLineCap(.round)
            ctx.cgContext.setLineJoin(.round)

            for stroke in strokes where stroke.path.count > 1 {
                let first = stroke.path[0].location
                ctx.cgContext.beginPath()
                ctx.cgContext.move(to: CGPoint(
                    x: first.x * scale + offsetX,
                    y: first.y * scale + offsetY
                ))
                for i in 1..<stroke.path.count {
                    let pt = stroke.path[i].location
                    ctx.cgContext.addLine(to: CGPoint(
                        x: pt.x * scale + offsetX,
                        y: pt.y * scale + offsetY
                    ))
                }
                ctx.cgContext.strokePath()
            }
        }
        return image.cgImage
    }

    // MARK: - IoU comparison

    private func iouScore(drawn: CGImage, template: CGImage) -> Int {
        guard let drawnPixels = extractGrayscalePixels(drawn),
              let templatePixels = extractGrayscalePixels(template),
              drawnPixels.count == templatePixels.count else { return 0 }

        var intersection = 0
        var union = 0

        for i in 0..<drawnPixels.count {
            let isDrawnInk    = drawnPixels[i] < 128
            let isTemplateInk = templatePixels[i] < 128
            if isDrawnInk || isTemplateInk { union += 1 }
            if isDrawnInk && isTemplateInk { intersection += 1 }
        }

        guard union > 0 else { return 0 }
        return Int(Double(intersection) / Double(union) * 100)
    }

    private func extractGrayscalePixels(_ image: CGImage) -> [UInt8]? {
        let w = Int(targetSize.width)
        let h = Int(targetSize.height)
        var pixels = [UInt8](repeating: 0, count: w * h)

        guard let context = CGContext(
            data: &pixels,
            width: w,
            height: h,
            bitsPerComponent: 8,
            bytesPerRow: w,
            space: CGColorSpaceCreateDeviceGray(),
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else { return nil }

        context.draw(image, in: CGRect(origin: .zero, size: targetSize))
        return pixels
    }
}
