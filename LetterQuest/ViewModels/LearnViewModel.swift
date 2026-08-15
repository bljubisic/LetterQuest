import Foundation
import RxSwift

/// Drives `LearnView` for the animated "Watch me draw" demonstration screen.
///
/// Fetches the target `Letter` from the repository and exposes a `replayToken`
/// that increments on each `play()` call, causing `LearnView` to restart the
/// stroke animation via SwiftUI's `.id()` modifier.
final class LearnViewModel: LearnViewModelProtocol {

    // MARK: - LearnViewModelProtocol outputs

    /// The letter being demonstrated. Populated asynchronously after init.
    @Published private(set) var letter: Letter?

    /// Replaced with a fresh `UUID` on every `play()` call.
    /// `LearnView` uses `.id(replayToken)` on `LetterStrokeAnimation` to force
    /// a fresh `onAppear`, which restarts the stroke sequence from the beginning.
    @Published private(set) var replayToken = UUID()

    // MARK: - Private

    private let letterId: UUID
    private let router: AppRouter
    private let disposeBag = DisposeBag()

    // MARK: - Init

    /// - Parameters:
    ///   - letterId: The stable `UUID` of the letter to demonstrate.
    ///   - letterRepository: Fetches the full `Letter` model.
    ///   - router: Navigation coordinator shared across the app.
    init(
        letterId: UUID,
        letterRepository: LetterRepositoryProtocol,
        router: AppRouter
    ) {
        self.letterId = letterId
        self.router   = router

        letterRepository.fetch(by: letterId)
            .asObservable()
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] letter in
                self?.letter = letter
            })
            .disposed(by: disposeBag)
    }

    // MARK: - LearnViewModelProtocol inputs

    /// Replaces `replayToken` so that `LearnView` replays the animation.
    func play() {
        replayToken = UUID()
    }

    /// Pushes `.practice` for the current letter onto the router's navigation stack.
    func navigateToPractice() {
        router.push(.practice(letterId: letterId))
    }
}
