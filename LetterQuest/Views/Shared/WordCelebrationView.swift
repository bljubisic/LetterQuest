import SwiftUI

/// A full-screen overlay shown when the child finishes tracing every letter in a word.
///
/// Tapping "Done!" calls `onContinue`, which `WordPracticeViewModel` routes back
/// to the home screen.
struct WordCelebrationView: View {

    /// The word text just completed, e.g. `"cat"`.
    let word: String

    /// Called when the child taps the continue button.
    let onContinue: () -> Void

    @ScaledMetric(relativeTo: .largeTitle) private var emojiSize: CGFloat = 80

    var body: some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()

            VStack(spacing: 28) {
                Text("🎉")
                    .font(.system(size: emojiSize))
                    .accessibilityHidden(true)

                VStack(spacing: 8) {
                    Text("You spelled it!")
                        .font(.largeTitle.bold())
                        .foregroundStyle(.white)

                    Text("\"\(word)\" — great job!")
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.85))
                }
                .accessibilityElement(children: .combine)

                Button("Done! →", action: onContinue)
                    .buttonStyle(.borderedProminent)
                    .font(.title2.bold())
                    .controlSize(.large)
                    .accessibilityHint("Returns to the home screen.")
            }
            .padding(40)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28))
        }
        .onAppear {
            UIAccessibility.post(notification: .screenChanged, argument: nil)
        }
    }
}
