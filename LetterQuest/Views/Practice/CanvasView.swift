import SwiftUI
import PencilKit

/// A `UIViewRepresentable` wrapper around `PKCanvasView`.
///
/// Accepts both Apple Pencil and finger input (`drawingPolicy = .anyInput`).
/// The parent view controls clearing via the `shouldClear` binding;
/// stroke changes are reported through the `onStrokesChanged` callback.
///
/// - Note: `CanvasView` intentionally has no knowledge of scoring or navigation.
///   It is a pure rendering primitive driven entirely by the parent view.
struct CanvasView: UIViewRepresentable {

    /// When set to `true` by the parent, clears the canvas and resets to `false`.
    @Binding var shouldClear: Bool

    /// Called every time the drawing changes, with the current set of strokes.
    let onStrokesChanged: ([PKStroke]) -> Void

    // MARK: - UIViewRepresentable

    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView()
        canvas.tool          = PKInkingTool(.pen, color: .systemBlue, width: 28)
        canvas.drawingPolicy = .anyInput    // finger + Apple Pencil
        canvas.backgroundColor = .clear
        canvas.isOpaque      = false
        canvas.delegate      = context.coordinator
        return canvas
    }

    func updateUIView(_ canvas: PKCanvasView, context: Context) {
        guard shouldClear else { return }
        canvas.drawing = PKDrawing()
        // Reset the flag asynchronously to break the SwiftUI update cycle.
        DispatchQueue.main.async { shouldClear = false }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onStrokesChanged: onStrokesChanged)
    }

    // MARK: - Coordinator

    /// Bridges `PKCanvasViewDelegate` callbacks to the parent's closure.
    final class Coordinator: NSObject, PKCanvasViewDelegate {

        private let onStrokesChanged: ([PKStroke]) -> Void

        init(onStrokesChanged: @escaping ([PKStroke]) -> Void) {
            self.onStrokesChanged = onStrokesChanged
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            // PKCanvasView fires this delegate synchronously when `drawing` is
            // mutated — including from `updateUIView` during a SwiftUI view
            // update. Defer the callback so observers can mutate state safely.
            let strokes = canvasView.drawing.strokes
            DispatchQueue.main.async { [onStrokesChanged] in
                onStrokesChanged(strokes)
            }
        }
    }
}
