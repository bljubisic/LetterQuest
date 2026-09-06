import Foundation
import CoreGraphics
import UIKit
import PencilKit

/// Compares each drawn stroke against its matching reference stroke using IoU,
/// then returns the **minimum** per-stroke score.
///
/// **Why minimum instead of average?**
/// Averaging lets one badly-placed stroke hide behind correct ones — a bottom bar
/// at the wrong height averages with three perfect strokes and still produces a
/// high score. Taking the minimum makes a single clearly-wrong stroke fail the
/// whole shape signal, which is the desired behaviour for a handwriting tutor.
///
/// **Algorithm per stroke pair**
/// 1. Normalise the child's canvas coordinates to 0–1 by dividing by canvas size.
/// 2. Map the template's 0–1 points through the writing zone (the same rectangle
///    `StrokeGuideOverlay` draws), then normalise to 0–1 canvas space.
/// 3. Both polylines are now in a common coordinate space — size and position
///    differences are visible to the scorer.
/// 4. Rasterise each polyline into a 64 × 64 bitmap and compute IoU.
final class ShapeAnalyzer {

    /// Side length of the bitmap used for each per-stroke comparison.
    private let targetSize = CGSize(width: 64, height: 64)

    /// Stroke width for rasterisation. Wide enough to tolerate normal child
    /// drawing variation (~5–10 px on a 400 px canvas) while still zeroing
    /// out strokes placed far from the expected position.
    private let strokeWidth: CGFloat = 10

    /// IoU value that maps to a score of 100. A correctly placed stroke
    /// typically achieves IoU 0.55–1.0 depending on drawing precision.
    private let perfectIoU: Double = 0.55

    /// Caches rendered template bitmaps across calls (and across candidates
    /// within the recognition gate's ~26-candidate scan). A template's
    /// rasterised bitmap is fully determined by its letter, stroke index, and
    /// canvas size — it never depends on what the child actually drew — but
    /// without this cache it was being re-rasterised on every single
    /// submission for every candidate, which measured as the majority of the
    /// recognition gate's cost in practice (see issue #17). At most a few
    /// hundred small bitmaps ever get cached (26 letters × ~2 strokes × the
    /// handful of canvas sizes a session actually uses), so this is
    /// negligible against the app's memory budget.
    ///
    /// Guarded by `templateCacheQueue` because `HandwritingAssessor.assess()`
    /// runs on a concurrent background queue and rapid double-submissions
    /// could otherwise mutate this dictionary from two threads at once.
    private var templateBitmapCache: [TemplateCacheKey: CGImage] = [:]
    private let templateCacheQueue = DispatchQueue(label: "com.letterquest.shapeAnalyzer.templateCache")

    private struct TemplateCacheKey: Hashable {
        let character: Character
        let strokeIndex: Int
        let canvasWidth: Int
        let canvasHeight: Int
    }

    // MARK: - Public interface

    /// Returns a weighted per-stroke shape score (0–100).
    ///
    /// Computes IoU for each child stroke N vs template stroke N, then combines
    /// them as `0.5 * average + 0.5 * minimum`.  Pure average would let a
    /// clearly misplaced stroke hide behind correct ones (e.g. a bottom bar of
    /// 'E' drawn at mid-height averages away).  Pure minimum would punish a
    /// correct G when one stroke has slightly imprecise positioning.  The 50/50
    /// split keeps sensitivity to a wrong stroke while tolerating small errors
    /// in individual strokes.
    ///
    /// A missing child stroke counts as 0, so skipping strokes always lowers
    /// the score.
    func score(strokes: [PKStroke], for letter: Letter, canvasSize: CGSize) -> Int {
        guard !strokes.isEmpty else { return 0 }
        let drawnBitmaps = strokes.map { renderSingleStroke($0, canvasSize: canvasSize) }
        return score(drawnBitmaps: drawnBitmaps, for: letter, canvasSize: canvasSize)
    }

    /// Scores the same drawn strokes against every letter in `candidates` in
    /// one pass, rendering each drawn stroke's bitmap only once instead of
    /// once per candidate.
    ///
    /// `HandwritingAssessor`'s recognition gate calls `score(strokes:for:canvasSize:)`
    /// once per letter in the alphabet (~26 times) to find the best-matching
    /// character — with the naive per-call rendering, that re-rasterises the
    /// *identical* drawn strokes ~26 times even though only the template side
    /// actually differs between candidates. This measured as the dominant cost
    /// of the recognition gate in practice (see issue #17). Returns scores in
    /// the same order as `candidates`.
    func scores(strokes: [PKStroke], against candidates: [Letter], canvasSize: CGSize) -> [Int] {
        guard !strokes.isEmpty else { return candidates.map { _ in 0 } }
        let drawnBitmaps = strokes.map { renderSingleStroke($0, canvasSize: canvasSize) }
        return candidates.map { score(drawnBitmaps: drawnBitmaps, for: $0, canvasSize: canvasSize) }
    }

    /// Shared scoring logic for both `score(strokes:for:canvasSize:)` and
    /// `scores(strokes:against:canvasSize:)` — takes already-rendered drawn
    /// stroke bitmaps so callers can reuse them across multiple candidates.
    private func score(drawnBitmaps: [CGImage?], for letter: Letter, canvasSize: CGSize) -> Int {
        let templates = letter.strokeTemplates
        guard !drawnBitmaps.isEmpty, !templates.isEmpty else { return 0 }

        let zone = writingZone(canvasSize: canvasSize, character: letter.character)

        var perStrokeScores: [Int] = []
        for i in 0..<templates.count {
            if i < drawnBitmaps.count,
               let drawn    = drawnBitmaps[i],
               let template = renderSingleTemplate(templates[i], zone: zone, canvasSize: canvasSize, character: letter.character) {
                perStrokeScores.append(iouScore(drawn: drawn, template: template))
            } else {
                perStrokeScores.append(0)   // missing stroke
            }
        }

        // Extra child strokes with no matching template slot count as 0.
        // Without this, drawing G (3 strokes) against C's template (1 stroke) only
        // compares the arc and ignores the bar + vertical, inflating C's shape score.
        let extraStrokes = max(0, drawnBitmaps.count - templates.count)
        perStrokeScores.append(contentsOf: Array(repeating: 0, count: extraStrokes))

        let avg    = Double(perStrokeScores.reduce(0, +)) / Double(perStrokeScores.count)
        let minVal = Double(perStrokeScores.min() ?? 0)
        return Int(0.5 * avg + 0.5 * minVal)
    }

    // MARK: - Rendering

    /// Normalises a PencilKit stroke's canvas-pixel coordinates to 0–1 and rasterises.
    private func renderSingleStroke(_ stroke: PKStroke, canvasSize: CGSize) -> CGImage? {
        guard stroke.path.count > 1 else { return nil }
        let points = (0..<stroke.path.count).map { i -> CGPoint in
            let loc = stroke.path[i].location
            return CGPoint(x: loc.x / canvasSize.width,
                           y: loc.y / canvasSize.height)
        }
        return rasterise([points])
    }

    /// Maps a template stroke through the writing zone then normalises to 0–1 canvas
    /// space, producing a bitmap in the same coordinate system as `renderSingleStroke`.
    ///
    /// Cached by (character, stroke index, canvas size) since `zone` itself is
    /// fully determined by `character` and `canvasSize` — see `templateBitmapCache`.
    private func renderSingleTemplate(_ template: StrokeTemplate,
                                      zone: CGRect,
                                      canvasSize: CGSize,
                                      character: Character) -> CGImage? {
        let key = TemplateCacheKey(
            character:   character,
            strokeIndex: template.strokeIndex,
            canvasWidth:  Int(canvasSize.width.rounded()),
            canvasHeight: Int(canvasSize.height.rounded())
        )
        if let cached = templateCacheQueue.sync(execute: { templateBitmapCache[key] }) {
            return cached
        }

        guard template.points.count > 1 else { return nil }
        let points = template.points.map { pt -> CGPoint in
            let cx = zone.minX + pt.x * zone.width
            let cy = zone.minY + pt.y * zone.height
            return CGPoint(x: cx / canvasSize.width,
                           y: cy / canvasSize.height)
        }
        guard let image = rasterise([points]) else { return nil }
        templateCacheQueue.sync { templateBitmapCache[key] = image }
        return image
    }

    /// The rectangle on the canvas where a correctly drawn letter should sit.
    /// Mirrors `StrokeGuideOverlay.writingZone(in:)` exactly.
    private func writingZone(canvasSize: CGSize, character: Character) -> CGRect {
        let ascenderY  = canvasSize.height * 0.20
        let xHeightY   = canvasSize.height * 0.45
        let baselineY  = canvasSize.height * 0.70
        let descenderY = canvasSize.height * 0.85

        let top: CGFloat
        let bottom: CGFloat
        switch character {
        case "b", "d", "f", "h", "k", "l", "t":
            top = ascenderY;  bottom = baselineY
        case "g", "j", "p", "q", "y":
            top = ascenderY;  bottom = descenderY
        default:
            if character.isUppercase || character.isNumber {
                top = ascenderY; bottom = baselineY
            } else {
                top = xHeightY; bottom = baselineY
            }
        }

        let height = bottom - top
        let width  = height
        let x      = (canvasSize.width - width) / 2
        return CGRect(x: x, y: top, width: width, height: height)
    }

    /// Rasterises normalised 0–1 polylines directly into a `targetSize` bitmap.
    /// No bounding-box fitting — position and scale relative to the canvas are preserved.
    private func rasterise(_ normalizedPolylines: [[CGPoint]]) -> CGImage? {
        guard !normalizedPolylines.isEmpty else { return nil }

        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let image = renderer.image { ctx in
            UIColor.white.setFill()
            ctx.fill(CGRect(origin: .zero, size: targetSize))

            ctx.cgContext.setStrokeColor(UIColor.black.cgColor)
            ctx.cgContext.setLineWidth(strokeWidth)
            ctx.cgContext.setLineCap(.round)
            ctx.cgContext.setLineJoin(.round)

            for polyline in normalizedPolylines {
                guard let first = polyline.first else { continue }
                ctx.cgContext.beginPath()
                ctx.cgContext.move(to: CGPoint(x: first.x * targetSize.width,
                                               y: first.y * targetSize.height))
                for pt in polyline.dropFirst() {
                    ctx.cgContext.addLine(to: CGPoint(x: pt.x * targetSize.width,
                                                      y: pt.y * targetSize.height))
                }
                ctx.cgContext.strokePath()
            }
        }
        return image.cgImage
    }

    // MARK: - IoU

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
        return Int(min(100, iou / perfectIoU * 100))
    }

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
