import Foundation

struct ChildProgress: Codable, Equatable {
    let letterId: UUID
    var attempts: [Attempt]
    var bestScore: Int
    var isUnlocked: Bool
    var isCompleted: Bool

    struct Attempt: Codable, Equatable {
        let timestamp: Date
        let score: Int
    }
}

extension ChildProgress {
    func recording(_ result: AssessmentResult) -> ChildProgress {
        let newAttempt = Attempt(timestamp: Date(), score: result.overallScore)
        return ChildProgress(
            letterId: letterId,
            attempts: attempts + [newAttempt],
            bestScore: max(bestScore, result.overallScore),
            isUnlocked: isUnlocked,
            isCompleted: isCompleted || result.passed
        )
    }
}
