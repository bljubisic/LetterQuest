import SwiftUI
import PencilKit

/// The main drawing screen where a child practices a single letter.
///
/// Generic over `VM: PracticeViewModelProtocol` so that the real `PracticeViewModel`
/// and a preview/test mock are interchangeable without changing the view.
///
/// **Layout** (top → bottom):
/// 1. Large letter glyph + instruction label
/// 2. Drawing canvas with four guide lines (ascender, x-height, baseline, descender)
/// 3. `ScorePanel` — animates in after each submission
/// 4. Clear / Check action buttons
@MainActor
private final class StrokesStore: ObservableObject {

    /// Observed by the view to enable/disable the Check button.
    /// Transitions empty ↔ non-empty are rare relative to per-stroke updates,
    /// and are dispatched async so the publish never lands inside a view update.
    @Published private(set) var hasStrokes = false

    /// Not `@Published` — the array is read on demand by the Check button,
    /// so updating it from a PencilKit delegate callback can never trigger a
    /// SwiftUI re-render during an in-flight view update.
    private(set) var strokes: [PKStroke] = []

    func update(strokes: [PKStroke]) {
        self.strokes = strokes
        let nowHasStrokes = !strokes.isEmpty
        guard nowHasStrokes != hasStrokes else { return }
        DispatchQueue.main.async { [weak self] in
            self?.hasStrokes = nowHasStrokes
        }
    }

    func reset() {
        strokes = []
        guard hasStrokes else { return }
        DispatchQueue.main.async { [weak self] in
            self?.hasStrokes = false
        }
    }
}

struct PracticeView<VM: PracticeViewModelProtocol>: View {

    @ObservedObject var viewModel: VM
    @StateObject private var strokesStore = StrokesStore()
    @State private var shouldClearCanvas = false

    var body: some View {
        ZStack {
            Color(uiColor: .systemYellow).opacity(0.05).ignoresSafeArea()

            // A plain fixed `VStack` clipped the Check/Clear buttons in
            // landscape (much less available height than portrait, on top of
            // the canvas's fixed 380pt height) or at larger Dynamic Type
            // sizes — a `ScrollView` makes the content scrollable instead of
            // clipped when it doesn't fit, with no visible change when it does.
            ScrollView {
                VStack(spacing: 24) {
                    if let letter = viewModel.letter {
                        letterHeader(for: letter)
                    }

                    drawingArea

                    if let result = viewModel.assessmentResult {
                        ScorePanel(result: result)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    actionButtons
                }
                .padding()
                .animation(.spring(), value: viewModel.assessmentResult != nil)
            }

            if viewModel.isAssessing {
                assessingOverlay
            }

            if viewModel.showCelebration {
                CelebrationView(onContinue: viewModel.continueToNext)
                    .transition(.opacity)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: viewModel.assessmentResult) { _, result in
            guard let result else { return }
            let outcome = result.passed ? "Great job!" : (result.feedback.first?.message ?? "Keep trying!")
            UIAccessibility.post(notification: .announcement,
                                 argument: "Overall score \(result.overallScore). \(outcome)")
        }
    }

    // MARK: - Subviews

    /// Shows the target letter as an animated stroke demonstration. Tapping
    /// replays the animation; it also auto-plays whenever the letter changes.
    private func letterHeader(for letter: Letter) -> some View {
        VStack(spacing: 4) {
            LetterStrokeAnimation(letter: letter)
                .id(letter.id)
                .accessibilityLabel("Letter demonstration")
                .accessibilityHint("Double-tap to watch how to draw \(String(letter.character)) again.")

            Text("Draw the letter \(String(letter.character))")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
    }

    /// White rounded card containing the four guide lines and the PencilKit canvas.
    private var drawingArea: some View {
        GeometryReader { geo in
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.08), radius: 8, y: 4)

                GuideLines(size: geo.size)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .accessibilityHidden(true)

                if let letter = viewModel.letter {
                    StrokeGuideOverlay(
                        templates: letter.strokeTemplates,
                        canvasSize: geo.size,
                        character: letter.character
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .accessibilityHidden(true)
                }

                CanvasView(shouldClear: $shouldClearCanvas) { strokes in
                    strokesStore.update(strokes: strokes)
                }
                .clipShape(RoundedRectangle(cornerRadius: 20))
                // Force a brand-new `PKCanvasView` whenever the target letter
                // changes. Without this, SwiftUI's view diffing can match the
                // `UIViewRepresentable` by type+position and keep the previous
                // letter's drawing around — even when the enclosing
                // `PracticeView` is itself a fresh instance.
                .id(viewModel.letter?.id)
            }
            .onChange(of: viewModel.letter?.id) { _, _ in
                strokesStore.reset()
            }
            .onAppear {
                viewModel.updateGuidelines(canvasSize: geo.size)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 380)
        // The guide lines and stroke overlay beneath are purely decorative;
        // present the whole card as one direct-manipulation drawing surface
        // so VoiceOver users double-tap once, then draw normally with touch.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Drawing canvas")
        .accessibilityHint("Double-tap to begin drawing.")
        .accessibilityAddTraits(.allowsDirectInteraction)
    }

    /// Clear and Check buttons.
    private var actionButtons: some View {
        HStack(spacing: 20) {
            Button {
                shouldClearCanvas = true
                strokesStore.reset()
                viewModel.clear()
            } label: {
                Label("Clear", systemImage: "arrow.counterclockwise")
                    .font(.title3.bold())
            }
            .buttonStyle(.bordered)
            .accessibilityHint("Clears your drawing so you can try again.")

            Button {
                viewModel.submit(strokes: strokesStore.strokes)
            } label: {
                Label("Check!", systemImage: "checkmark.circle.fill")
                    .font(.title3.bold())
            }
            .buttonStyle(.borderedProminent)
            .disabled(!strokesStore.hasStrokes || viewModel.isAssessing)
            .accessibilityHint("Submits your drawing to be scored.")
        }
    }

    /// Shown while `HandwritingAssessor` is working on a background thread.
    private var assessingOverlay: some View {
        ZStack {
            Color.black.opacity(0.25).ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView().scaleEffect(1.5).tint(.white)
                Text("Checking your letter…")
                    .font(.title3.bold())
                    .foregroundStyle(.white)
            }
            .padding(32)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Guide Lines

/// Four horizontal rules drawn with `Canvas` to avoid creating layout views for each line.
///
/// | Line colour | Purpose                        | Position  |
/// |-------------|--------------------------------|-----------|
/// | Blue dashed | Ascender                       | 20 % down |
/// | Blue solid  | x-height                       | 45 % down |
/// | Red solid   | Baseline                       | 70 % down |
/// | Blue dashed | Descender                      | 85 % down |
private struct GuideLines: View {

    let size: CGSize

    var body: some View {
        Canvas { ctx, sz in
            let h = sz.height
            drawLine(ctx: ctx, y: h * 0.20, width: sz.width, color: .blue.opacity(0.25), dashed: true)
            drawLine(ctx: ctx, y: h * 0.45, width: sz.width, color: .blue.opacity(0.45))
            drawLine(ctx: ctx, y: h * 0.70, width: sz.width, color: .red.opacity(0.40))
            drawLine(ctx: ctx, y: h * 0.85, width: sz.width, color: .blue.opacity(0.25), dashed: true)
        }
    }

    private func drawLine(ctx: GraphicsContext, y: CGFloat, width: CGFloat, color: Color, dashed: Bool = false) {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: y))
        path.addLine(to: CGPoint(x: width, y: y))
        ctx.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: 1, dash: dashed ? [8, 5] : []))
    }
}
