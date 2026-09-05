import SwiftUI

/// The animated "Watch me draw" demonstration screen shown before practice.
///
/// Plays the letter's strokes one-by-one so the child can see correct formation
/// before picking up a pencil. Tapping "Watch again" replays from the beginning;
/// "Let's practice!" advances to `PracticeView`.
///
/// Generic over `VM: LearnViewModelProtocol` so that the real `LearnViewModel`
/// and a preview/test mock are interchangeable at compile time.
struct LearnView<VM: LearnViewModelProtocol>: View {

    @ObservedObject var viewModel: VM

    @ScaledMetric(relativeTo: .largeTitle) private var glyphSize: CGFloat = 72

    var body: some View {
        GeometryReader { geo in
            let animationSize = min(geo.size.width, geo.size.height) * 0.55

            // A plain fixed `VStack` clipped the bottom button in landscape
            // (much less available height than portrait) or at larger Dynamic
            // Type sizes — wrapping in a `ScrollView` with a `minHeight` equal
            // to the screen keeps content vertically centered when it fits,
            // and makes it scrollable (instead of clipped) when it doesn't.
            ScrollView {
                VStack(spacing: 32) {
                    Spacer(minLength: 0)

                    if let letter = viewModel.letter {
                        titleText(for: letter)

                        animationArea(letter: letter, size: animationSize)

                        actionButtons
                    } else {
                        ProgressView()
                    }

                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, minHeight: geo.size.height)
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(uiColor: .systemYellow).opacity(0.05).ignoresSafeArea())
    }

    // MARK: - Subviews

    private func titleText(for letter: Letter) -> some View {
        VStack(spacing: 6) {
            Text("Watch how to draw")
                .font(.title2)
                .foregroundStyle(.secondary)

            Text(String(letter.character))
                .font(.system(size: glyphSize, weight: .bold, design: .rounded))
                .foregroundStyle(Color.accentColor)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Watch how to draw the letter \(String(letter.character))")
    }

    /// The animation area: a rounded card containing the stroke animation.
    /// The card scales with available screen space so it looks good on both
    /// compact (iPhone) and regular (iPad) size classes.
    private func animationArea(letter: Letter, size: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.09), radius: 12, y: 5)

            LetterStrokeAnimation(letter: letter, size: size)
                // Replacing the id forces a fresh onAppear → the animation
                // restarts from scratch without the user having to swipe away.
                .id(viewModel.replayToken)
        }
        .frame(width: size + 48, height: size + 48)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Letter demonstration")
        .accessibilityHint("Double-tap to watch again.")
        .accessibilityAddTraits(.isButton)
        // The tap-to-replay gesture lives on the now-hidden `LetterStrokeAnimation`
        // child; `.accessibilityAction` (not another `.onTapGesture`) is the
        // correct way to re-expose it for VoiceOver without adding a second,
        // ambiguous gesture recognizer over the same region for sighted users.
        .accessibilityAction { viewModel.play() }
    }

    private var actionButtons: some View {
        VStack(spacing: 14) {
            Button {
                viewModel.play()
            } label: {
                Label("Watch again", systemImage: "arrow.counterclockwise")
                    .font(.title3.bold())
                    .frame(maxWidth: 320)
            }
            .buttonStyle(.bordered)
            .tint(.accentColor)
            .accessibilityHint("Replays the letter demonstration.")

            Button {
                viewModel.navigateToPractice()
            } label: {
                Label("Let's practice!", systemImage: "pencil.tip")
                    .font(.title3.bold())
                    .frame(maxWidth: 320)
            }
            .buttonStyle(.borderedProminent)
            .accessibilityHint("Moves to the drawing practice screen.")
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        LearnView(viewModel: PreviewLearnViewModel())
    }
}

private final class PreviewLearnViewModel: LearnViewModelProtocol {
    @Published var letter: Letter? = Letter.alphabet.first { $0.character == "A" }
    @Published var replayToken = UUID()
    func play() { replayToken = UUID() }
    func navigateToPractice() {}
}
