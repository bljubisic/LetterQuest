import SwiftUI

/// A single tappable tile showing the word text and its completion status.
struct WordCard: View {

    let word: Word
    let progress: WordProgress?
    let onTap: () -> Void

    @ScaledMetric(relativeTo: .largeTitle) private var glyphSize: CGFloat = 40

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 10) {
                Text(word.text)
                    .font(.system(size: glyphSize, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.accentColor)

                Text(isCompleted ? "⭐ Done!" : "Tap to start")
                    .font(.caption.bold())
                    .foregroundStyle(isCompleted ? .green : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.08), radius: 6, y: 3)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(word.text)
        .accessibilityValue(isCompleted ? "Completed" : "Not started")
    }

    private var isCompleted: Bool { progress?.isCompleted ?? false }
}
