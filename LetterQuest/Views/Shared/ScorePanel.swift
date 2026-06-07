import SwiftUI

/// A grouped panel shown below the canvas after each submission.
///
/// Displays the four individual signal scores as `ScorePill` chips
/// and the first (most important) feedback message.
struct ScorePanel: View {

    let result: AssessmentResult

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                ScorePill(label: "Stroke", score: result.strokeOrderScore)
                ScorePill(label: "Shape",  score: result.shapeScore)
                ScorePill(label: "Size",   score: result.proportionScore)
                ScorePill(label: "Smooth", score: result.smoothnessScore)
            }

            if let item = result.feedback.first {
                Text(item.message)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
            }
        }
        .padding()
        .background(
            Color(uiColor: .systemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 16)
        )
    }
}
