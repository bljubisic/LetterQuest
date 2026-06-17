import Foundation
import CoreGraphics
import PencilKit

/// Measures how smooth and controlled the drawn strokes are.
///
/// Two signals contribute to each stroke's score:
/// - **Jitter** (60 %): The standard deviation of turning angles along an
///   arc-length-resampled path. A perfectly smooth curve has near-zero spread;
///   a shaky stroke has a high one.
/// - **Speed consistency** (40 %): The coefficient of variation (σ/μ) of the
///   instantaneous speed at each stroke point, after trimming the
///   touch-down / lift-off transients that always look "non-uniform".
///
/// The constants are tuned for **finger** input on iPhone, which is noisier
/// and lower-rate than Apple Pencil.
///
/// The final score is the mean over all strokes.
final class SmoothnessAnalyzer {

    // MARK: - Tuning constants (calibrated for finger input)

    /// Minimum spacing in points between resampled path vertices.
    /// Filters out micro-jitter from the dense PencilKit sample stream.
    private static let resampleSpacing: CGFloat = 6.0

    /// Multiplier applied to the turning-angle standard deviation (in degrees).
    /// Smaller = more lenient. ×1.5 gives ~75/100 for a typical finger stroke.
    private static let jitterPenalty: Double = 1.5

    /// Fraction of speed samples trimmed from the start and end of each stroke.
    /// Children naturally start and end strokes slowly; trimming these
    /// transients prevents that natural curve from tanking the CV.
    private static let speedTrimFraction: Double = 0.15

    /// Multiplier applied to the trimmed-speed coefficient of variation.
    /// ×20 gives ~90/100 for a steady finger stroke (CV ≈ 0.5).
    private static let speedPenalty: Double = 20.0

    // MARK: - Public interface

    /// Returns a smoothness score for all strokes combined (0–100).
    ///
    /// - Parameter strokes: All `PKStroke` objects on the canvas.
    /// - Returns: A score in **0–100**; higher is smoother.
    func score(strokes: [PKStroke]) -> Int {
        guard !strokes.isEmpty else { return 0 }
        let scores = strokes.map { scoreStroke($0) }
        return Int(scores.reduce(0.0, +) / Double(scores.count))
    }

    // MARK: - Per-stroke scoring

    private func scoreStroke(_ stroke: PKStroke) -> Double {
        jitterScore(stroke) * 0.6 + speedConsistencyScore(stroke) * 0.4
    }

    // MARK: - Jitter

    /// Computes the turning-angle spread along the stroke path, after
    /// arc-length resampling so micro-jitter between dense samples doesn't
    /// dominate the result.
    ///
    /// A straight line has spread ≈ 0; a zigzag path has a large one.
    private func jitterScore(_ stroke: PKStroke) -> Double {
        let points = resampledPoints(of: stroke, spacing: Self.resampleSpacing)
        guard points.count >= 3 else { return 100 }

        let angles: [Double] = (1..<points.count - 1).map { i in
            angleBetween(points[i - 1], points[i], points[i + 1])
        }

        let spread = sqrt(angles.variance())   // standard deviation, in degrees
        return max(0, 100 - spread * Self.jitterPenalty)
    }

    // MARK: - Speed consistency

    /// Computes the coefficient of variation of instantaneous speed, with the
    /// natural touch-down and lift-off transients trimmed from each end.
    ///
    /// Speed is derived from the spatial distance between consecutive points
    /// divided by the PencilKit `timeOffset` delta.
    /// Pairs with zero time delta are skipped to avoid division by zero.
    private func speedConsistencyScore(_ stroke: PKStroke) -> Double {
        guard stroke.path.count >= 2 else { return 100 }

        let speeds: [Double] = (1..<stroke.path.count).compactMap { i in
            let prev = stroke.path[i - 1]
            let curr = stroke.path[i]
            let dt   = curr.timeOffset - prev.timeOffset
            guard dt > 0 else { return nil }
            return prev.location.distance(to: curr.location) / dt
        }

        let trimmed = trimEnds(speeds, fraction: Self.speedTrimFraction)
        guard !trimmed.isEmpty else { return 100 }
        return max(0, 100 - trimmed.coefficientOfVariation() * Self.speedPenalty)
    }

    // MARK: - Resampling

    /// Walks the stroke path keeping only points at least `spacing` apart, so
    /// the turning-angle calculation sees the macro shape rather than dense,
    /// noisy raw samples (especially important for finger input).
    private func resampledPoints(of stroke: PKStroke, spacing: CGFloat) -> [CGPoint] {
        guard stroke.path.count > 0 else { return [] }

        var result: [CGPoint] = [stroke.path[0].location]
        for i in 1..<stroke.path.count {
            let pt = stroke.path[i].location
            if pt.distance(to: result.last!) >= spacing {
                result.append(pt)
            }
        }
        return result
    }

    /// Drops the first and last `fraction` of the array — used to remove the
    /// touch-down / lift-off speed transients that exist in every stroke.
    private func trimEnds(_ values: [Double], fraction: Double) -> [Double] {
        guard values.count > 4 else { return values }
        let n = Int(Double(values.count) * fraction)
        return Array(values.dropFirst(n).dropLast(n))
    }

    // MARK: - Geometry

    /// Returns the turning angle at point `b` (in degrees), given three consecutive points.
    ///
    /// A value of 0° means the path is perfectly straight at that point.
    /// A value of 180° means the path reverses direction.
    private func angleBetween(_ a: CGPoint, _ b: CGPoint, _ c: CGPoint) -> Double {
        let v1  = CGVector(dx: b.x - a.x, dy: b.y - a.y)
        let v2  = CGVector(dx: c.x - b.x, dy: c.y - b.y)
        let dot = v1.dx * v2.dx + v1.dy * v2.dy
        let mag = v1.magnitude * v2.magnitude
        guard mag > 0 else { return 0 }
        return acos(max(-1, min(1, dot / mag))) * 180 / .pi
    }
}

// MARK: - Statistics helpers

private extension Array where Element == Double {

    func mean() -> Double {
        guard !isEmpty else { return 0 }
        return reduce(0, +) / Double(count)
    }

    /// Population variance.
    func variance() -> Double {
        guard count > 1 else { return 0 }
        let m = mean()
        return map { pow($0 - m, 2) }.reduce(0, +) / Double(count)
    }

    /// Coefficient of variation (σ / μ); 0 for a constant sequence.
    func coefficientOfVariation() -> Double {
        let m = mean()
        guard m > 0 else { return 0 }
        return sqrt(variance()) / m
    }
}

private extension CGVector {
    var magnitude: Double { sqrt(dx * dx + dy * dy) }
}

private extension CGPoint {
    func distance(to other: CGPoint) -> Double {
        sqrt(pow(x - other.x, 2) + pow(y - other.y, 2))
    }
}
