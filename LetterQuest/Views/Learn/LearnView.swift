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

    var body: some View {
        GeometryReader { geo in
            let animationSize = min(geo.size.width, geo.size.height) * 0.55

            VStack(spacing: 32) {
                Spacer()

                if let letter = viewModel.letter {
                    titleText(for: letter)

                    animationArea(letter: letter, size: animationSize)

                    actionButtons
                } else {
                    ProgressView()
                }

                Spacer()
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 32)
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
                .font(.system(size: 72, weight: .bold, design: .rounded))
                .foregroundStyle(Color.accentColor)
        }
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

            Button {
                viewModel.navigateToPractice()
            } label: {
                Label("Let's practice!", systemImage: "pencil.tip")
                    .font(.title3.bold())
                    .frame(maxWidth: 320)
            }
            .buttonStyle(.borderedProminent)
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
