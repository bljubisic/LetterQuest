import Foundation

/// The contract that `LearnView` depends on.
///
/// `LearnView` is generic over this protocol so that the real `LearnViewModel`
/// and a preview/test mock are interchangeable at compile time.
protocol LearnViewModelProtocol: ObservableObject {

    /// The letter being demonstrated, populated asynchronously after init.
    var letter: Letter? { get }

    /// Changes to a new value each time `play()` is called, driving a fresh
    /// animation via `.id(replayToken)` on `LetterStrokeAnimation`.
    var replayToken: UUID { get }

    /// Triggers a new animation replay.
    func play()

    /// Pushes the practice route for the current letter onto the navigation stack.
    func navigateToPractice()
}
