import SwiftUI

/// A single tappable tile showing the letter character and its practice progress.
struct LetterCard: View {

    let letter: Letter
    let progress: ChildProgress?
    let isUnlocked: Bool
    let onTap: () -> Void

    @ScaledMetric(relativeTo: .largeTitle) private var glyphSize: CGFloat = 64

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 10) {
                // Large character glyph
                Text(String(letter.character))
                    .font(.system(size: glyphSize, weight: .bold, design: .rounded))
                    .foregroundStyle(isUnlocked ? Color.accentColor : .gray)

                // Progress indicator or status label
                if let progress {
                    VStack(spacing: 4) {
                        ProgressView(value: Double(progress.bestScore), total: 100)
                            .tint(progress.isCompleted ? .green : .accentColor)
                            .padding(.horizontal, 8)

                        Text(progress.isCompleted ? "⭐ Done!" : "\(progress.bestScore)%")
                            .font(.caption.bold())
                            .foregroundStyle(progress.isCompleted ? .green : .secondary)
                    }
                } else {
                    Text(isUnlocked ? "Tap to start" : "🔒 Locked")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isUnlocked ? Color.white : Color.gray.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(isUnlocked ? 0.08 : 0), radius: 6, y: 3)
        }
        .disabled(!isUnlocked)
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Letter \(String(letter.character))")
        .accessibilityValue(accessibilityStatus)
        .accessibilityIdentifier("home.letterCard.\(letter.character)")
    }

    private var accessibilityStatus: String {
        guard let progress else {
            return isUnlocked ? "Not started" : "Locked"
        }
        return progress.isCompleted
            ? "Completed, best score \(progress.bestScore) percent"
            : "In progress, best score \(progress.bestScore) percent"
    }
}
