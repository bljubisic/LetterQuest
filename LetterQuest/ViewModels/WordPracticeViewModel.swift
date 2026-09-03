import Foundation
import RxSwift

/// Drives `WordPracticeView` for a single word session.
///
/// Reuses `PracticeViewModel` for each letter in the word: a fresh instance is
/// built by `makeLetterViewModel()` for every `currentIndex`, constructed with
/// `onWordAdvance` so a passing score calls back into `advanceToNextLetter()`
/// instead of the router-based navigation `PracticeViewModel` normally does.
/// Once every letter has passed, `WordProgress.isCompleted` is persisted and
/// `isWordCompleted` triggers the word-level celebration overlay.
final class WordPracticeViewModel: WordPracticeViewModelProtocol {

    // MARK: - WordPracticeViewModelProtocol outputs

    @Published private(set) var word: Word?
    @Published private(set) var currentIndex = 0
    @Published private(set) var isWordCompleted = false

    // MARK: - Private state

    /// The full lowercase alphabet, used to resolve each of the word's
    /// characters to the matching `Letter`'s stable id.
    private var lowercaseLetters: [Letter] = []

    private let wordId: UUID
    private let letterRepository: LetterRepositoryProtocol
    private let progressRepository: ProgressRepositoryProtocol
    private let wordProgressRepository: WordProgressRepositoryProtocol
    private let assessor: HandwritingAssessing
    private let soundService: SoundServiceProtocol
    private let hapticsService: HapticsServiceProtocol
    private let router: AppRouter
    private let disposeBag = DisposeBag()

    // MARK: - Init

    /// - Parameters:
    ///   - wordId: The stable `UUID` of the word to practice.
    ///   - wordRepository: Fetches the full `Word` model.
    ///   - letterRepository: Resolves each character to its `Letter`.
    ///   - progressRepository: Persists per-letter practice history (shared with normal practice).
    ///   - wordProgressRepository: Persists word-level completion.
    ///   - assessor: Runs the four-signal scoring pipeline for each letter.
    ///   - soundService: Plays audio feedback cues after each letter's assessment.
    ///   - hapticsService: Plays tactile feedback patterns after each letter's assessment.
    ///   - router: Navigation coordinator shared across the app.
    init(
        wordId: UUID,
        wordRepository: WordRepositoryProtocol,
        letterRepository: LetterRepositoryProtocol,
        progressRepository: ProgressRepositoryProtocol,
        wordProgressRepository: WordProgressRepositoryProtocol,
        assessor: HandwritingAssessing,
        soundService: SoundServiceProtocol,
        hapticsService: HapticsServiceProtocol,
        router: AppRouter
    ) {
        self.wordId                 = wordId
        self.letterRepository       = letterRepository
        self.progressRepository     = progressRepository
        self.wordProgressRepository = wordProgressRepository
        self.assessor               = assessor
        self.soundService           = soundService
        self.hapticsService         = hapticsService
        self.router                 = router

        Observable.zip(
            wordRepository.fetch(by: wordId).asObservable(),
            letterRepository.fetchAll().asObservable()
        )
        .observe(on: MainScheduler.instance)
        .subscribe(onNext: { [weak self] word, allLetters in
            self?.word = word
            self?.lowercaseLetters = allLetters.filter { $0.letterCase == .lower }
        })
        .disposed(by: disposeBag)
    }

    // MARK: - WordPracticeViewModelProtocol inputs

    func makeLetterViewModel() -> PracticeViewModel? {
        guard let word, currentIndex < word.characters.count else { return nil }
        let character = word.characters[currentIndex]
        guard let letterId = lowercaseLetters.first(where: { $0.character == character })?.id else {
            return nil
        }
        return PracticeViewModel(
            letterId:           letterId,
            letterRepository:   letterRepository,
            progressRepository: progressRepository,
            assessor:           assessor,
            soundService:       soundService,
            hapticsService:     hapticsService,
            router:             router,
            onWordAdvance:      { [weak self] in self?.advanceToNextLetter() }
        )
    }

    func finish() {
        router.popToRoot()
    }

    // MARK: - Private helpers

    /// Called when the embedded `PracticeViewModel` reports a pass. Moves to the
    /// next letter, or — if that was the last letter — persists word completion.
    private func advanceToNextLetter() {
        guard let word else { return }
        let nextIndex = currentIndex + 1
        guard nextIndex < word.characters.count else {
            wordProgressRepository.save(WordProgress(wordId: word.id, isCompleted: true))
                .observe(on: MainScheduler.instance)
                .subscribe(onCompleted: { [weak self] in
                    self?.isWordCompleted = true
                })
                .disposed(by: disposeBag)
            return
        }
        currentIndex = nextIndex
    }
}
