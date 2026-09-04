import SwiftUI

/// A full-screen overlay shown when the child achieves a passing score (≥ 75).
///
/// Tapping "Next Letter →" calls `onContinue`, which the parent view model
/// routes back to the home screen.
struct CelebrationView: View {

    /// Called when the child taps the continue button.
    let onContinue: () -> Void

    @ScaledMetric(relativeTo: .largeTitle) private var starSize: CGFloat = 80

    var body: some View {
        ZStack {
            // Dim the canvas behind the celebration
            Color.black.opacity(0.4).ignoresSafeArea()

            VStack(spacing: 28) {
                Text("⭐")
                    .font(.system(size: starSize))
                    .accessibilityHidden(true)

                VStack(spacing: 8) {
                    Text("Amazing!")
                        .font(.largeTitle.bold())
                        .foregroundStyle(.white)

                    Text("You nailed that letter!")
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.85))
                }
                .accessibilityElement(children: .combine)

                Button("Next Letter →", action: onContinue)
                    .buttonStyle(.borderedProminent)
                    .font(.title2.bold())
                    .controlSize(.large)
                    .accessibilityHint("Moves on to the next letter.")
            }
            .padding(40)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28))
        }
        .onAppear {
            UIAccessibility.post(notification: .screenChanged, argument: nil)
        }
    }
}
