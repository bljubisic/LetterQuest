import Foundation
import PencilKit

/// The contract that `PracticeView` depends on.
///
/// `PracticeView` is generic over this protocol so that the real and mock
/// implementations are interchangeable at compile time.
protocol PracticeViewModelProtocol: ObservableObject {

    /// The letter being practiced, populated asynchronously after init.
    var letter: Letter? { get }

    /// The most recent scoring result, or `nil` before the first submission.
    var assessmentResult: AssessmentResult? { get }

    /// `true` while the assessment pipeline is running on a background queue.
    var isAssessing: Bool { get }

    /// `true` after the child achieves a passing score (≥ 75); triggers the celebration overlay.
    var showCelebration: Bool { get }

    /// The total number of submissions made in this session.
    var attemptCount: Int { get }

    /// Submits the current canvas strokes for assessment.
    ///
    /// - Parameter strokes: All strokes currently on the `PKCanvasView`.
    func submit(strokes: [PKStroke])

    /// Clears the last assessment result so the child can try again.
    func clear()

    /// Navigates back to the home screen after a successful letter completion.
    func continueToNext()

    /// Updates the proportion-checker guide lines when the canvas frame is known.
    ///
    /// Called from `PracticeView` via `GeometryReader` on `.onAppear`.
    ///
    /// - Parameter canvasSize: The actual pixel size of the drawing canvas.
    func updateGuidelines(canvasSize: CGSize)
}
