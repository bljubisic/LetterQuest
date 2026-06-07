import Foundation
import PencilKit
import RxSwift
import RxRelay

/// Drives `PracticeView` for a single letter session.
///
/// **Data flow:**
/// 1. On init, fetches the `Letter` from the repository and stores it in a
///    `BehaviorRelay` so `withLatestFrom` always has the latest value.
/// 2. When the child taps "Check!", `submit(strokes:)` fires the assessment pipeline.
/// 3. The pipeline runs on a background queue via `HandwritingAssessor`,
///    then saves the result and updates `@Published` properties on the main thread.
///
/// All struct mutations (e.g. recording a new attempt) go through
/// `ChildProgress`'s lenses rather than in-place mutation.
final class PracticeViewModel: PracticeViewModelProtocol {

    // MARK: - PracticeViewModelProtocol outputs

    /// The letter being practiced. Populated asynchronously after init.
    @Published private(set) var letter: Letter?

    /// The last assessment result. `nil` before the first submission or after a clear.
    @Published private(set) var assessmentResult: AssessmentResult?

    /// `true` while scoring is running on a background queue.
    @Published private(set) var isAssessing = false

    /// `true` after a passing score; causes `PracticeView` to show the celebration overlay.
    @Published private(set) var showCelebration = false

    /// Running count of submissions in the current session.
    @Published private(set) var attemptCount = 0

    // MARK: - Private state

    /// Caches the resolved `Letter` for `withLatestFrom` — avoids capturing `self.letter`
    /// at subscription time (which would be stale on the first emission).
    private let letterRelay = BehaviorRelay<Letter?>(value: nil)

    /// Holds the proportion-checker guide lines; updated once the canvas size is known.
    private var guidelines: ProportionChecker.Guidelines = .forCanvas(size: CGSize(width: 600, height: 400))

    // MARK: - Private Rx

    private let submitRelay = PublishRelay<[PKStroke]>()
    private let assessor: HandwritingAssessing
    private let progressRepository: ProgressRepositoryProtocol
    private let router: AppRouter
    private let disposeBag = DisposeBag()

    // MARK: - Init

    /// - Parameters:
    ///   - letterId: The stable `UUID` of the letter to practice.
    ///   - letterRepository: Fetches the full `Letter` model.
    ///   - progressRepository: Persists and retrieves practice history.
    ///   - assessor: Runs the four-signal scoring pipeline.
    ///   - router: Navigation coordinator shared across the app.
    init(
        letterId: UUID,
        letterRepository: LetterRepositoryProtocol,
        progressRepository: ProgressRepositoryProtocol,
        assessor: HandwritingAssessing,
        router: AppRouter
    ) {
        self.assessor           = assessor
        self.progressRepository = progressRepository
        self.router             = router

        fetchLetter(letterId: letterId, from: letterRepository)
        bindSubmissionPipeline()
    }

    // MARK: - PracticeViewModelProtocol inputs

    /// Sends the canvas strokes into the assessment pipeline.
    func submit(strokes: [PKStroke]) {
        submitRelay.accept(strokes)
    }

    /// Resets the last result so the child can try again without the score panel showing.
    func clear() {
        assessmentResult = nil
    }

    /// Navigates back to the home screen.
    func continueToNext() {
        router.popToRoot()
    }

    /// Recalculates proportion-checker guide lines when the real canvas size is available.
    func updateGuidelines(canvasSize: CGSize) {
        guidelines = .forCanvas(size: canvasSize)
    }

    // MARK: - Private helpers

    private func fetchLetter(letterId: UUID, from repository: LetterRepositoryProtocol) {
        repository.fetch(by: letterId)
            .asObservable()
            .subscribe(onNext: { [weak self] letter in
                self?.letterRelay.accept(letter)
                DispatchQueue.main.async { self?.letter = letter }
            })
            .disposed(by: disposeBag)
    }

    /// Wires `submitRelay` → latest letter → assessor → save → UI update.
    ///
    /// `flatMapLatest` automatically cancels a prior assessment if the child
    /// taps "Check!" again before scoring finishes.
    private func bindSubmissionPipeline() {
        submitRelay
            .withLatestFrom(letterRelay) { ($0, $1) }                       // attach latest letter
            .compactMap { strokes, letter -> (strokes: [PKStroke], letter: Letter)? in
                guard let letter else { return nil }
                return (strokes, letter)
            }
            .do(onNext: { [weak self] _ in
                DispatchQueue.main.async { self?.isAssessing = true }
            })
            .flatMapLatest { [weak self] pair -> Observable<AssessmentResult> in
                guard let self else { return .empty() }
                return self.assessor
                    .assess(strokes: pair.strokes, for: pair.letter, guidelines: self.guidelines)
                    .asObservable()
            }
            .observe(on: MainScheduler.instance)
            .subscribe(
                onNext:  { [weak self] result in self?.handle(result: result) },
                onError: { [weak self] _ in self?.isAssessing = false }
            )
            .disposed(by: disposeBag)
    }

    /// Persists the result via lenses and triggers the celebration if the child passed.
    private func handle(result: AssessmentResult) {
        isAssessing  = false
        assessmentResult = result
        attemptCount    += 1

        guard let letter else { return }

        progressRepository.loadAll()
            .map { all -> ChildProgress in
                // Either update the existing record or create a fresh one.
                let existing = all.first { $0.letterId == letter.id }
                    ?? ChildProgress(
                        letterId:    letter.id,
                        attempts:    [],
                        bestScore:   0,
                        isUnlocked:  true,
                        isCompleted: false
                    )
                // All struct mutations happen through lenses — no in-place mutation.
                return existing.recording(result)
            }
            .flatMapCompletable { [weak self] updated in
                self?.progressRepository.save(updated) ?? .empty()
            }
            .subscribe(onCompleted: { [weak self] in
                if result.passed { self?.showCelebration = true }
            })
            .disposed(by: disposeBag)
    }
}
