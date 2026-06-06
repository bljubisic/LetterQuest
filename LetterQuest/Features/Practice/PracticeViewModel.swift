import Foundation
import PencilKit
import RxSwift
import RxRelay

final class PracticeViewModel: ObservableObject {

    // MARK: - Outputs

    @Published var letter: Letter?
    @Published var assessmentResult: AssessmentResult?
    @Published var isAssessing = false
    @Published var showCelebration = false
    @Published var attemptCount = 0

    var guidelines: ProportionChecker.Guidelines = .forCanvas(size: CGSize(width: 600, height: 400))

    // MARK: - Inputs

    private let submitSubject = PublishRelay<[PKStroke]>()

    // MARK: - Private

    private let letterRelay = BehaviorRelay<Letter?>(value: nil)
    private let assessor: HandwritingAssessing
    private let progressRepository: ProgressRepositoryProtocol
    private let router: AppRouter
    private let disposeBag = DisposeBag()

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

        letterRepository.fetch(by: letterId)
            .asObservable()
            .subscribe(onNext: { [weak self] letter in
                self?.letterRelay.accept(letter)
                DispatchQueue.main.async { self?.letter = letter }
            })
            .disposed(by: disposeBag)

        bindSubmission()
    }

    func submit(strokes: [PKStroke]) {
        submitSubject.accept(strokes)
    }

    func clear() {
        assessmentResult = nil
    }

    func continueToNext() {
        router.popToRoot()
    }

    func updateGuidelines(canvasSize: CGSize) {
        guidelines = .forCanvas(size: canvasSize)
    }

    // MARK: - Bindings

    private func bindSubmission() {
        submitSubject
            .withLatestFrom(letterRelay) { strokes, letter in (strokes, letter) }
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
                onNext: { [weak self] result in self?.handleResult(result) },
                onError: { [weak self] _ in self?.isAssessing = false }
            )
            .disposed(by: disposeBag)
    }

    private func handleResult(_ result: AssessmentResult) {
        isAssessing = false
        assessmentResult = result
        attemptCount += 1

        guard let letter else { return }

        progressRepository.loadAll()
            .map { all -> ChildProgress in
                let existing = all.first { $0.letterId == letter.id }
                    ?? ChildProgress(letterId: letter.id, attempts: [], bestScore: 0, isUnlocked: true, isCompleted: false)
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
