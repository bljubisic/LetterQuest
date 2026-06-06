import Foundation
import CoreGraphics
import PencilKit

final class DTWMatcher {

    func score(strokes: [PKStroke], against templates: [StrokeTemplate]) -> Int {
        guard !templates.isEmpty else { return 0 }

        guard strokes.count == templates.count else {
            let diff = abs(strokes.count - templates.count)
            return max(0, 100 - diff * 25)
        }

        let scores = zip(strokes, templates).map { scoreStroke($0, against: $1) }
        return Int(scores.reduce(0.0, +) / Double(scores.count))
    }

    private func scoreStroke(_ stroke: PKStroke, against template: StrokeTemplate) -> Double {
        let drawn = normalizedPoints(from: stroke)
        let reference = normalizedPoints(from: template.points)
        let directionScore = scoreDirection(stroke, expected: template.direction)
        let pathScore = dtwSimilarity(series1: drawn, series2: reference)
        return directionScore * 0.4 + pathScore * 0.6
    }

    // MARK: - DTW

    private func dtwSimilarity(
        series1: [(x: Double, y: Double)],
        series2: [(x: Double, y: Double)]
    ) -> Double {
        let n = series1.count
        let m = series2.count
        guard n > 0, m > 0 else { return 0 }

        var matrix = Array(repeating: Array(repeating: Double.infinity, count: m + 1), count: n + 1)
        matrix[0][0] = 0

        for i in 1...n {
            for j in 1...m {
                let cost = euclideanDistance(series1[i - 1], series2[j - 1])
                matrix[i][j] = cost + min(matrix[i-1][j], matrix[i][j-1], matrix[i-1][j-1])
            }
        }

        let maxPossibleDistance = sqrt(2.0) * Double(max(n, m))
        let normalizedDistance = matrix[n][m] / maxPossibleDistance
        return max(0, (1.0 - normalizedDistance) * 100)
    }

    // MARK: - Direction scoring

    private func scoreDirection(_ stroke: PKStroke, expected: StrokeTemplate.StrokeDirection) -> Double {
        guard stroke.path.count >= 2 else { return 50 }
        let first = stroke.path[0].location
        let last = stroke.path[stroke.path.count - 1].location
        let dx = last.x - first.x
        let dy = last.y - first.y

        switch expected {
        case .leftToRight:  return dx > 0 ? 100 : 20
        case .rightToLeft:  return dx < 0 ? 100 : 20
        case .topToBottom:  return dy > 0 ? 100 : 20
        case .bottomToTop:  return dy < 0 ? 100 : 20
        case .diagonal, .curved: return 80
        }
    }

    // MARK: - Normalization

    private func normalizedPoints(from stroke: PKStroke) -> [(x: Double, y: Double)] {
        let step = max(1, stroke.path.count / 50)
        let raw = stride(from: 0, to: stroke.path.count, by: step)
            .map { stroke.path[$0].location }
            .map { (x: Double($0.x), y: Double($0.y)) }
        return normalizeToUnitSquare(raw)
    }

    private func normalizedPoints(from points: [CGPoint]) -> [(x: Double, y: Double)] {
        let raw = points.map { (x: Double($0.x), y: Double($0.y)) }
        return normalizeToUnitSquare(raw)
    }

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
