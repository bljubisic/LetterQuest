import Foundation
import CoreGraphics
import PencilKit

final class SmoothnessAnalyzer {

    func score(strokes: [PKStroke]) -> Int {
        guard !strokes.isEmpty else { return 0 }
        let scores = strokes.map { scoreStroke($0) }
        return Int(scores.reduce(0.0, +) / Double(scores.count))
    }

    private func scoreStroke(_ stroke: PKStroke) -> Double {
        let jitter       = jitterScore(stroke)
        let speedConsistency = speedConsistencyScore(stroke)
        return jitter * 0.6 + speedConsistency * 0.4
    }

    // MARK: - Jitter (angular variance along the path)

    private func jitterScore(_ stroke: PKStroke) -> Double {
        guard stroke.path.count >= 3 else { return 100 }

        var angles: [Double] = []
        for i in 1..<stroke.path.count - 1 {
            let a = stroke.path[i - 1].location
            let b = stroke.path[i].location
            let c = stroke.path[i + 1].location
            angles.append(angleBetween(a, b, c))
        }

        return max(0, 100 - angles.variance() * 10)
    }

    // MARK: - Speed consistency

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

    // MARK: - Geometry helpers

    private func angleBetween(_ a: CGPoint, _ b: CGPoint, _ c: CGPoint) -> Double {
        let v1 = CGVector(dx: b.x - a.x, dy: b.y - a.y)
        let v2 = CGVector(dx: c.x - b.x, dy: c.y - b.y)
        let dot = v1.dx * v2.dx + v1.dy * v2.dy
        let mag = v1.magnitude * v2.magnitude
        guard mag > 0 else { return 0 }
        return acos(max(-1, min(1, dot / mag))) * 180 / .pi
    }
}

// MARK: - Math extensions

private extension Array where Element == Double {
    func mean() -> Double {
        guard !isEmpty else { return 0 }
        return reduce(0, +) / Double(count)
    }

    func variance() -> Double {
        guard count > 1 else { return 0 }
        let m = mean()
        return map { pow($0 - m, 2) }.reduce(0, +) / Double(count)
    }

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
