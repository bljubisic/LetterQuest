import SwiftUI
import PencilKit

struct CanvasView: UIViewRepresentable {

    @Binding var shouldClear: Bool
    let onStrokesChanged: ([PKStroke]) -> Void

    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView()
        canvas.tool = PKInkingTool(.pen, color: .systemBlue, width: 8)
        canvas.drawingPolicy = .anyInput
        canvas.backgroundColor = .clear
        canvas.isOpaque = false
        canvas.delegate = context.coordinator
        return canvas
    }

    func updateUIView(_ canvas: PKCanvasView, context: Context) {
        if shouldClear {
            canvas.drawing = PKDrawing()
            DispatchQueue.main.async { shouldClear = false }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onStrokesChanged: onStrokesChanged)
    }

    final class Coordinator: NSObject, PKCanvasViewDelegate {
        private let onStrokesChanged: ([PKStroke]) -> Void

        init(onStrokesChanged: @escaping ([PKStroke]) -> Void) {
            self.onStrokesChanged = onStrokesChanged
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            onStrokesChanged(canvasView.drawing.strokes)
        }
    }
}
