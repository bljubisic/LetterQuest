import Foundation

struct AssessmentResult {
    let overallScore: Int
    let strokeOrderScore: Int
    let shapeScore: Int
    let proportionScore: Int
    let smoothnessScore: Int
    let feedback: [FeedbackItem]
    let passed: Bool

    struct FeedbackItem {
        let type: FeedbackType
        let message: String
    }

    enum FeedbackType {
        case strokeOrder
        case shape
        case proportion
        case smoothness
        case encouragement
    }
}
