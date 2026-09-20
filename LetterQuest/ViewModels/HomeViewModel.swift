import Foundation
import RxSwift
import RxRelay

/// Drives `HomeView` by loading the installed alphabet catalogue, the
/// persisted active-alphabet selection, and progress data, then exposing
/// them as `@Published` properties for SwiftUI to observe.
///
/// Internally the reactive pipeline is built with RxSwift. `@Published`
/// properties act as a thin SwiftUI-compatible bridge over the Rx layer.
final class HomeViewModel: HomeViewModelProtocol {

    // MARK: - HomeViewModelProtocol outputs

    /// Every installed alphabet (free and purchased). Used by the "Switch
    /// Alphabet" screen.
    @Published private(set) var installedAlphabets: [Alphabet] = []

    var activeAlphabetDisplayName: String { activeAlphabet?.displayName ?? "" }

    /// Letters of the active alphabet, filtered by `selectedCase`.
    var letters: [Letter] {
        activeAlphabet?.letters.filter { $0.letterCase == selectedCase } ?? []
    }

    /// Progress keyed by letter id; absent entries mean the letter was never attempted.
    @Published private(set) var progressMap: [UUID: ChildProgress] = [:]

    /// The active alphabet's curated words.
    @Published private(set) var words: [Word] = []

    /// Progress keyed by word id; absent entries mean the word was never completed.
    @Published private(set) var wordProgressMap: [UUID: WordProgress] = [:]

    /// `true` while the combined repository fetch is in flight.
    @Published private(set) var isLoading = false

    /// Whether the grid is showing uppercase or lowercase letters.
    @Published private(set) var selectedCase: LetterCase = .upper

    /// `true` once more than one alphabet is installed — shows the "Switch
    /// Alphabet" toolbar button.
    var isMultiAlphabet: Bool { installedAlphabets.count > 1 }

    /// `true` once every uppercase and lowercase letter of the active
    /// alphabet has been completed, unlocking that alphabet's word practice.
    var isWordModeUnlocked: Bool {
        guard let activeAlphabet, !activeAlphabet.letters.isEmpty else { return false }
        return activeAlphabet.letters.allSatisfy { progressMap[$0.id]?.isCompleted == true }
    }

    // MARK: - Private state

    /// Resolved from the persisted `AppSettings.activeAlphabetId` when it
    /// still matches an installed alphabet; falls back to the first
    /// installed alphabet otherwise (first launch, or a stale id left over
    /// from an alphabet that's no longer installed).
    @Published private var activeAlphabet: Alphabet?

    /// The active alphabet's first uppercase letter — bootstraps unlocked by
    /// default, before any `ChildProgress` record exists.
    private var defaultUnlockedLetterId: UUID? {
        activeAlphabet?.letters.first { $0.letterCase == .upper }?.id
    }

    // MARK: - Private Rx

    private let alphabetRepository: AlphabetRepositoryProtocol
    private let progressRepository: ProgressRepositoryProtocol
    private let settingsRepository: SettingsRepositoryProtocol
    private let wordRepository: WordRepositoryProtocol
    private let wordProgressRepository: WordProgressRepositoryProtocol
    private let router: AppRouter
    private let loadTrigger = PublishRelay<Void>()
    private let disposeBag = DisposeBag()

    // MARK: - Init

    /// - Parameters:
    ///   - alphabetRepository: Source of installed alphabets and their letters.
    ///   - progressRepository: Persistent store for practice history.
    ///   - settingsRepository: Source of the persisted active-alphabet selection.
    ///   - wordRepository: Source of the curated word catalogue.
    ///   - wordProgressRepository: Persistent store for word-level completion.
    ///   - router: Navigation coordinator shared across the app.
    init(
        alphabetRepository: AlphabetRepositoryProtocol,
        progressRepository: ProgressRepositoryProtocol,
        settingsRepository: SettingsRepositoryProtocol,
        wordRepository: WordRepositoryProtocol,
        wordProgressRepository: WordProgressRepositoryProtocol,
        router: AppRouter
    ) {
        self.alphabetRepository     = alphabetRepository
        self.progressRepository     = progressRepository
        self.settingsRepository     = settingsRepository
        self.wordRepository         = wordRepository
        self.wordProgressRepository = wordProgressRepository
        self.router                 = router

        bindLoadTrigger()
        load()
    }

    // MARK: - HomeViewModelProtocol inputs

    /// Fires the load pipeline. Called automatically on init and again from
    /// `HomeView.onAppear` to refresh after returning from Switch Alphabet,
    /// the Store, or a practice session.
    func load() {
        loadTrigger.accept(())
    }

    /// Pushes the "Watch me draw" learn route for the tapped letter,
    /// so the child sees a stroke demonstration before practice begins.
    func selectLetter(_ letter: Letter) {
        router.push(.learn(letterId: letter.id))
    }

    func navigateToProgress() {
        router.push(.progress)
    }

    /// Pushes the practice screen for the given word.
    func selectWord(_ word: Word) {
        router.push(.word(wordId: word.id))
    }

    /// Pushes the Settings screen.
    func navigateToSettings() {
        router.push(.settings)
    }

    /// Pushes the alphabet store screen.
    func navigateToStore() {
        router.push(.alphabetStore)
    }

    /// Pushes the "Switch Alphabet" screen.
    func navigateToSwitchAlphabet() {
        router.push(.switchAlphabet)
    }

    /// Switches the letter grid between uppercase and lowercase.
    func selectCase(_ letterCase: LetterCase) {
        selectedCase = letterCase
    }

    /// Whether `letter` is unlocked: an explicit `ChildProgress` record wins,
    /// otherwise it falls back to whether `letter` is its alphabet's own
    /// starting letter.
    func isUnlocked(_ letter: Letter) -> Bool {
        progressMap[letter.id]?.isUnlocked ?? (letter.id == defaultUnlockedLetterId)
    }

    // MARK: - Rx pipeline

    /// Wires the load trigger to a combined fetch of installed alphabets,
    /// the persisted active-alphabet selection, and progress.
    ///
    /// `flatMapLatest` cancels any in-flight request when the user triggers another
    /// load before the first one completes.
    private func bindLoadTrigger() {
        loadTrigger
            .do(onNext: { [weak self] in self?.isLoading = true })
            .flatMapLatest { [weak self] () -> Observable<([Alphabet], [ChildProgress], AppSettings, [Word], [WordProgress])> in
                guard let self else { return .empty() }
                return Observable.zip(
                    self.alphabetRepository.fetchInstalled().asObservable(),
                    self.progressRepository.loadAll().asObservable(),
                    self.settingsRepository.load().asObservable(),
                    self.wordRepository.fetchAll().asObservable(),
                    self.wordProgressRepository.loadAll().asObservable()
                )
            }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] alphabets, progress, settings, words, wordProgress in
                guard let self else { return }
                self.isLoading = false
                self.installedAlphabets = alphabets
                let activeAlphabet = alphabets.first { $0.id == settings.activeAlphabetId } ?? alphabets.first
                self.activeAlphabet = activeAlphabet
                self.progressMap = Dictionary(uniqueKeysWithValues: progress.map { ($0.letterId, $0) })
                self.words = words.filter { $0.alphabetId == activeAlphabet?.id }
                self.wordProgressMap = Dictionary(uniqueKeysWithValues: wordProgress.map { ($0.wordId, $0) })
            })
            .disposed(by: disposeBag)
    }
}
