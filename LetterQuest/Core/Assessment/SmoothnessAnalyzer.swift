import Foundation
import CoreGraphics
import PencilKit

/// Measures how smooth and controlled the drawn strokes are.
///
/// Two signals contribute to each stroke's score:
/// - **Jitter** (60 %): The variance of turning angles along the path.
///   A perfectly smooth curve has near-zero variance; a shaky stroke has high variance.
/// - **Speed consistency** (40 %): The coefficient of variation (σ/μ) of the
///   instantaneous speed at each stroke point.
///   A controlled stroke is drawn at roughly constant speed; hesitation produces
///   a high coefficient.
///
/// The final score is the mean over all strokes.
final class SmoothnessAnalyzer {

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

    /// Computes the turning-angle variance along the stroke path.
    ///
    /// A straight line has a variance of 0; a zigzag path has a high variance.
    /// The score decays exponentially as variance increases, with a factor of 10.
    private func jitterScore(_ stroke: PKStroke) -> Double {
        guard stroke.path.count >= 3 else { return 100 }

        let angles: [Double] = (1..<stroke.path.count - 1).map { i in
            angleBetween(
                stroke.path[i - 1].location,
                stroke.path[i].location,
                stroke.path[i + 1].location
            )
        }

        return max(0, 100 - angles.variance() * 10)
    }

    // MARK: - Speed consistency

    /// Computes the coefficient of variation of the instantaneous speed at each point.
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

        guard !speeds.isEmpty else { return 100 }
        return max(0, 100 - speeds.coefficientOfVariation() * 50)
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
