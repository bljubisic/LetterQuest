import SwiftUI
import PencilKit

struct PracticeView: View {

    @ObservedObject var viewModel: PracticeViewModel
    @State private var currentStrokes: [PKStroke] = []
    @State private var shouldClearCanvas = false

    var body: some View {
        ZStack {
            Color(uiColor: .systemYellow).opacity(0.05).ignoresSafeArea()

            VStack(spacing: 24) {
                if let letter = viewModel.letter {
                    letterHeader(letter)
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

            if viewModel.isAssessing {
                assessingOverlay
            }

            if viewModel.showCelebration {
                CelebrationView(onContinue: viewModel.continueToNext)
                    .transition(.opacity)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Subviews

    private func letterHeader(_ letter: Letter) -> some View {
        VStack(spacing: 4) {
            Text(String(letter.character))
                .font(.system(size: 110, weight: .bold, design: .rounded))
                .foregroundStyle(.blue)
            Text("Draw the letter \(String(letter.character))")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
    }

    private var drawingArea: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.08), radius: 8, y: 4)

                GuideLines(size: geo.size)
                    .clipShape(RoundedRectangle(cornerRadius: 20))

                CanvasView(shouldClear: $shouldClearCanvas) { strokes in
                    currentStrokes = strokes
                }
                .clipShape(RoundedRectangle(cornerRadius: 20))
            }
            .onAppear { viewModel.updateGuidelines(canvasSize: geo.size) }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 380)
    }

    private var actionButtons: some View {
        HStack(spacing: 20) {
            Button {
                shouldClearCanvas = true
                viewModel.clear()
            } label: {
                Label("Clear", systemImage: "arrow.counterclockwise")
                    .font(.title3.bold())
            }
            .buttonStyle(.bordered)

            Button {
                viewModel.submit(strokes: currentStrokes)
            } label: {
                Label("Check!", systemImage: "checkmark.circle.fill")
                    .font(.title3.bold())
            }
            .buttonStyle(.borderedProminent)
            .disabled(currentStrokes.isEmpty || viewModel.isAssessing)
        }
    }

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
    }
}

// MARK: - Guide Lines

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

// MARK: - Score Panel

struct ScorePanel: View {
    let result: AssessmentResult

    private let metrics: [(label: String, score: Int)] = []

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
        .background(Color(uiColor: .systemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }
}

struct ScorePill: View {
    let label: String
    let score: Int

    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption2.bold())
                .foregroundStyle(.secondary)
            Text("\(score)")
                .font(.title2.bold())
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
    }

    private var color: Color {
        score >= 75 ? .green : score >= 50 ? .orange : .red
    }
}

// MARK: - Celebration

struct CelebrationView: View {
    let onContinue: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()

            VStack(spacing: 28) {
                Text("⭐")
                    .font(.system(size: 80))

                VStack(spacing: 8) {
                    Text("Amazing!")
                        .font(.largeTitle.bold())
                        .foregroundStyle(.white)
                    Text("You nailed that letter!")
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.85))
                }

                Button("Next Letter →", action: onContinue)
                    .buttonStyle(.borderedProminent)
                    .font(.title2.bold())
                    .controlSize(.large)
            }
            .padding(40)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28))
        }
    }
}
