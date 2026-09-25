import Foundation
import CoreGraphics
import PencilKit

/// Scores how closely a drawn set of strokes matches the reference stroke templates.
///
/// Two independent signals contribute to each stroke's score:
/// - **Path similarity** (60 %): Dynamic Time Warping distance between the
///   normalised point sequences of the drawn stroke and the reference template.
/// - **Direction** (40 %): Whether the stroke moves in the expected direction
///   (e.g. left-to-right for a crossbar).
///
/// The final score is the arithmetic mean of all per-stroke scores.
/// A stroke-count mismatch is penalised by 25 points per extra/missing stroke.
final class DTWMatcher {

    // MARK: - Public interface

    /// Computes a 0–100 score for a set of strokes against a letter's templates.
    ///
    /// - Parameters:
    ///   - strokes: The strokes drawn by the child.
    ///   - templates: The ordered reference strokes for the target letter.
    ///   - ignoringTravelDirection: Scores each stroke both as drawn and
    ///     reversed, keeping the better result. For recognising *which letter*
    ///     a drawing looks like, where the end a stroke starts from shouldn't
    ///     matter; ordinary scoring leaves it `false` so wrong-way strokes are
    ///     still penalised.
    /// - Returns: An integer score in **0–100**.
    func score(strokes: [PKStroke], against templates: [StrokeTemplate], ignoringTravelDirection: Bool = false) -> Int {
        guard !templates.isEmpty else { return 0 }

        guard strokes.count == templates.count else {
            let mismatch = abs(strokes.count - templates.count)
            return max(0, 100 - mismatch * 25)
        }

        let scores = zip(strokes, templates).map { stroke, template in
            let points = strokePoints(stroke)
            let forwards = scoreStroke(points, against: template)
            guard ignoringTravelDirection else { return forwards }
            return max(forwards, scoreStroke(points.reversed(), against: template))
        }
        return Int(scores.reduce(0.0, +) / Double(scores.count))
    }

    // MARK: - Per-stroke scoring

    private func scoreStroke(_ points: [CGPoint], against template: StrokeTemplate) -> Double {
        let drawn     = normalizedPoints(from: sampled(points))
        let reference = normalizedPoints(from: template.points)
        let direction = scoreDirection(points, expected: template.direction)
        let path      = dtwSimilarity(series1: drawn, series2: reference)
        return direction * 0.4 + path * 0.6
    }

    private func strokePoints(_ stroke: PKStroke) -> [CGPoint] {
        (0..<stroke.path.count).map { stroke.path[$0].location }
    }

    // MARK: - Dynamic Time Warping

    /// Computes the normalised DTW similarity (0–100) between two point series.
    ///
    /// Both series are expected to already be in the unit square.
    /// The raw DTW cost is divided by the theoretical maximum to produce a 0–1
    /// similarity, which is then scaled to 0–100.
    ///
    /// Time complexity: O(n × m) where n and m are the series lengths.
    private func dtwSimilarity(
        series1: [(x: Double, y: Double)],
        series2: [(x: Double, y: Double)]
    ) -> Double {
        let n = series1.count, m = series2.count
        guard n > 0, m > 0 else { return 0 }

        var matrix = Array(repeating: Array(repeating: Double.infinity, count: m + 1), count: n + 1)
        matrix[0][0] = 0

        for i in 1...n {
            for j in 1...m {
                let cost  = euclideanDistance(series1[i - 1], series2[j - 1])
                matrix[i][j] = cost + min(matrix[i-1][j], matrix[i][j-1], matrix[i-1][j-1])
            }
        }

        let maxDistance = sqrt(2.0) * Double(max(n, m))
        return max(0, (1.0 - matrix[n][m] / maxDistance) * 100)
    }

    // MARK: - Direction scoring

    /// The shorter axis of a diagonal's overall movement must be at least this
    /// fraction of the longer one — roughly 14°–76° from horizontal.
    static let minimumDiagonalAxisRatio: CGFloat = 0.25

    /// Awards 100 points when the overall movement direction matches `expected`,
    /// or 20 points when it is opposite/wrong. Curved strokes always get 80 points
    /// (direction is implicit in the DTW path match).
    ///
    /// Diagonals are scored by slope, not travel direction: the templates'
    /// `.diagonal(angle:)` labels only encode "\" (positive angle — x and y
    /// grow together, y pointing down) vs "/" (negative angle), and children
    /// draw short diagonals such as accents either way round. Without this,
    /// every diagonal got the same flat 80 as a curve, so a "/" tick was no
    /// better a match for Ć's acute than for Č's V-shaped caron. A stroke only
    /// counts as diagonal if it moves meaningfully along both axes (see
    /// `minimumDiagonalAxisRatio`) — a V starts and ends level, so it isn't one.
    private func scoreDirection(_ points: [CGPoint], expected: StrokeDirection) -> Double {
        guard points.count >= 2, let first = points.first, let last = points.last else { return 50 }
        let dx = last.x - first.x
        let dy = last.y - first.y

        switch expected {
        case .leftToRight:  return dx > 0 ? 100 : 20
        case .rightToLeft:  return dx < 0 ? 100 : 20
        case .topToBottom:  return dy > 0 ? 100 : 20
        case .bottomToTop:  return dy < 0 ? 100 : 20
        case .diagonal(let angle):
            let isDiagonal = min(abs(dx), abs(dy)) >= Self.minimumDiagonalAxisRatio * max(abs(dx), abs(dy))
            let drawnIsBackslash = dx * dy > 0
            return isDiagonal && drawnIsBackslash == (angle > 0) ? 100 : 20
        case .curved: return 80
        }
    }

    // MARK: - Normalisation

    /// Samples up to 50 evenly-spaced points from a drawn stroke, so DTW cost
    /// stays bounded however densely PencilKit recorded it.
    private func sampled(_ points: [CGPoint]) -> [CGPoint] {
        let step = max(1, points.count / 50)
        return stride(from: 0, to: points.count, by: step).map { points[$0] }
    }

    /// Converts a `CGPoint` array into the tuple format used by the DTW
    /// algorithm, normalised to the unit square so that size and position do
    /// not affect the score.
    private func normalizedPoints(from points: [CGPoint]) -> [(x: Double, y: Double)] {
        normalizeToUnitSquare(points.map { (x: Double($0.x), y: Double($0.y)) })
    }

    /// Translates and scales a point set so all values fall in **[0, 1]**.
    private func normalizeToUnitSquare(_ points: [(x: Double, y: Double)]) -> [(x: Double, y: Double)] {
        guard let minX = points.map(\.x).min(),
              let maxX = points.map(\.x).max(),
              let minY = points.map(\.y).min(),
              let maxY = points.map(\.y).max() else { return points }

        let range = max(maxX - minX, maxY - minY, 0.001)
        return points.map { (x: ($0.x - minX) / range, y: ($0.y - minY) / range) }
    }

    private func euclideanDistance(_ a: (x: Double, y: Double), _ b: (x: Double, y: Double)) -> Double {
        sqrt(pow(a.x - b.x, 2) + pow(a.y - b.y, 2))
    }
}
