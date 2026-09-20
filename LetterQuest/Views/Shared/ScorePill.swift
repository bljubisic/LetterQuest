import SwiftUI

/// A small chip that displays a score label (e.g. "Stroke") above a numeric value,
/// colour-coded green / orange / red based on pass / borderline / fail thresholds.
struct ScorePill: View {

    /// Short display label — kept to 6 characters to fit on iPad and iPhone.
    let label: String

    /// Score in 0–100.
    let score: Int

    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption2.bold())
                .foregroundStyle(.secondary)

            Text("\(score)")
                .font(.title2.bold())
                .foregroundStyle(scoreColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(scoreColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label) score")
        .accessibilityValue("\(score) out of 100")
    }

    /// Green ≥ 75, orange ≥ 50, red below 50.
    private var scoreColor: Color {
        score >= 75 ? .green : score >= 50 ? .orange : .red
    }
}
