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

    /// The next letter in sequence, populated after a passing score so that
    /// `continueToNext()` can navigate straight to it. `nil` until the child
    /// passes (or when the current letter is the final one, "Z").
    private var nextLetterId: UUID?

    // MARK: - Private Rx

    private let submitRelay = PublishRelay<[PKStroke]>()
    private let assessor: HandwritingAssessing
    private let letterRepository: LetterRepositoryProtocol
    private let progressRepository: ProgressRepositoryProtocol
    private let soundService: SoundServiceProtocol
    private let router: AppRouter
    private let disposeBag = DisposeBag()

    // MARK: - Init

    /// - Parameters:
    ///   - letterId: The stable `UUID` of the letter to practice.
    ///   - letterRepository: Fetches the full `Letter` model.
    ///   - progressRepository: Persists and retrieves practice history.
    ///   - assessor: Runs the four-signal scoring pipeline.
    ///   - soundService: Plays audio feedback cues after each assessment.
    ///   - router: Navigation coordinator shared across the app.
    init(
        letterId: UUID,
        letterRepository: LetterRepositoryProtocol,
        progressRepository: ProgressRepositoryProtocol,
        assessor: HandwritingAssessing,
        soundService: SoundServiceProtocol,
        router: AppRouter
    ) {
        self.assessor           = assessor
        self.letterRepository   = letterRepository
        self.progressRepository = progressRepository
        self.soundService       = soundService
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

    /// Advances to the next letter when one was unlocked by the most recent
    /// pass. Falls back to popping to the home screen when there's no next
    /// letter (e.g. after passing "Z").
    ///
    /// Uses `router.replaceStack(with:)` so the navigation transition is
    /// atomic — no flash through the home screen and the previous
    /// `PracticeView` (with its canvas state) is fully torn down before the
    /// next one mounts.
    func continueToNext() {
        guard let nextLetterId else {
            router.popToRoot()
            return
        }
        router.replaceStack(with: .practice(letterId: nextLetterId))
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

    /// Persists the result via lenses, unlocks the next letter when the
    /// child passes, and triggers the celebration once both saves complete.
    private func handle(result: AssessmentResult) {
        isAssessing      = false
        assessmentResult = result
        attemptCount    += 1

        triggerSound(for: result)

        guard let letter else { return }

        let saveCurrent = progressRepository.loadAll()
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

        let unlockNext: Completable = result.passed
            ? unlockNextLetter(after: letter.id)
            : .empty()

        saveCurrent
            .andThen(unlockNext)
            .observe(on: MainScheduler.instance)
            .subscribe(onCompleted: { [weak self] in
                if result.passed { self?.showCelebration = true }
            })
            .disposed(by: disposeBag)
    }

    private func triggerSound(for result: AssessmentResult) {
        guard soundService.isSoundEnabled else { return }
        if result.passed {
            soundService.playSuccess()
        } else if result.overallScore >= 50 {
            soundService.playEncouragement()
        } else {
            soundService.playSoftError()
        }
    }

    /// Looks up the letter that follows `currentId`, ensures its persisted
    /// progress has `isUnlocked = true`, and remembers the id so the
    /// celebration's continue button can jump straight to it.
    ///
    /// Returns a no-op `Completable` when the current letter is the final one
    /// (`fetchNext` returns `nil`), so the caller can chain unconditionally.
    private func unlockNextLetter(after currentId: UUID) -> Completable {
        letterRepository.fetchNext(after: currentId)
            .flatMapCompletable { [weak self] next -> Completable in
                guard let self, let next else { return .empty() }
                return self.progressRepository.loadAll()
                    .map { all -> ChildProgress in
                        let existing = all.first { $0.letterId == next.id }
                            ?? ChildProgress(
                                letterId:    next.id,
                                attempts:    [],
                                bestScore:   0,
                                isUnlocked:  false,
                                isCompleted: false
                            )
                        return ChildProgress.lensIsUnlocked.set(existing, true)
                    }
                    .flatMapCompletable { self.progressRepository.save($0) }
                    .do(onCompleted: { [weak self] in
                        self?.nextLetterId = next.id
                    })
            }
    }
}
