import Foundation
import RxSwift
import RxRelay

/// Drives `HomeView` by loading the installed alphabet catalogue and progress
/// data, then exposing them as `@Published` properties for SwiftUI to observe.
///
/// Internally the reactive pipeline is built with RxSwift. `@Published`
/// properties act as a thin SwiftUI-compatible bridge over the Rx layer.
final class HomeViewModel: HomeViewModelProtocol {

    // MARK: - HomeViewModelProtocol outputs

    /// Every installed alphabet (free and purchased). Used to drive the
    /// alphabet picker once more than one is installed.
    @Published private(set) var installedAlphabets: [Alphabet] = []

    /// Letters of the single installed alphabet, filtered by `selectedCase`.
    /// Only shown directly when exactly one alphabet is installed — once
    /// `isMultiAlphabet` is `true`, Home shows the alphabet picker instead.
    var letters: [Letter] {
        installedAlphabets.first?.letters.filter { $0.letterCase == selectedCase } ?? []
    }

    /// Progress keyed by letter id; absent entries mean the letter was never attempted.
    @Published private(set) var progressMap: [UUID: ChildProgress] = [:]

    /// `true` while the combined repository fetch is in flight.
    @Published private(set) var isLoading = false

    /// Whether the grid is showing uppercase or lowercase letters.
    @Published private(set) var selectedCase: LetterCase = .upper

    /// `true` once more than one alphabet is installed — shows the alphabet
    /// picker grid instead of a direct letter grid.
    var isMultiAlphabet: Bool { installedAlphabets.count > 1 }

    /// `true` once every uppercase and lowercase letter of the single
    /// installed alphabet has been completed. Only meaningful when
    /// `!isMultiAlphabet` — Home shows this alphabet's letters directly only
    /// in that state; each other alphabet has its own `isWordModeUnlocked`
    /// on `AlphabetLettersViewModel`.
    var isWordModeUnlocked: Bool {
        guard let alphabet = installedAlphabets.first, !alphabet.letters.isEmpty else { return false }
        return alphabet.letters.allSatisfy { progressMap[$0.id]?.isCompleted == true }
    }

    // MARK: - Private state

    /// The single installed alphabet's first uppercase letter — bootstraps
    /// unlocked by default, before any `ChildProgress` record exists.
    private var defaultUnlockedLetterId: UUID? {
        installedAlphabets.first?.letters.first { $0.letterCase == .upper }?.id
    }

    // MARK: - Private Rx

    private let alphabetRepository: AlphabetRepositoryProtocol
    private let progressRepository: ProgressRepositoryProtocol
    private let router: AppRouter
    private let loadTrigger = PublishRelay<Void>()
    private let disposeBag = DisposeBag()

    // MARK: - Init

    /// - Parameters:
    ///   - alphabetRepository: Source of installed alphabets and their letters.
    ///   - progressRepository: Persistent store for practice history.
    ///   - router: Navigation coordinator shared across the app.
    init(
        alphabetRepository: AlphabetRepositoryProtocol,
        progressRepository: ProgressRepositoryProtocol,
        router: AppRouter
    ) {
        self.alphabetRepository = alphabetRepository
        self.progressRepository = progressRepository
        self.router             = router

        bindLoadTrigger()
        load()
    }

    // MARK: - HomeViewModelProtocol inputs

    /// Fires the load pipeline. Called automatically on init and again from `HomeView.onAppear` to refresh on return.
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

    /// Pushes the word-practice list screen.
    func navigateToWords() {
        router.push(.words(alphabetId: installedAlphabets.first?.id ?? Alphabet.latinId))
    }

    /// Pushes the Settings screen.
    func navigateToSettings() {
        router.push(.settings)
    }

    /// Pushes the alphabet store screen.
    func navigateToStore() {
        router.push(.alphabetStore)
    }

    /// Switches the letter grid between uppercase and lowercase.
    func selectCase(_ letterCase: LetterCase) {
        selectedCase = letterCase
    }

    /// Pushes the letter grid for the given installed alphabet.
    func selectAlphabet(_ alphabetId: String) {
        router.push(.alphabetLetters(alphabetId: alphabetId))
    }

    /// Whether `letter` is unlocked: an explicit `ChildProgress` record wins,
    /// otherwise it falls back to whether `letter` is its alphabet's own
    /// starting letter.
    func isUnlocked(_ letter: Letter) -> Bool {
        progressMap[letter.id]?.isUnlocked ?? (letter.id == defaultUnlockedLetterId)
    }

    // MARK: - Rx pipeline

    /// Wires the load trigger to a combined fetch of installed alphabets + progress.
    ///
    /// `flatMapLatest` cancels any in-flight request when the user triggers another
    /// load before the first one completes.
    private func bindLoadTrigger() {
        loadTrigger
            .do(onNext: { [weak self] in self?.isLoading = true })
            .flatMapLatest { [weak self] () -> Observable<([Alphabet], [ChildProgress])> in
                guard let self else { return .empty() }
                return Observable.zip(
                    self.alphabetRepository.fetchInstalled().asObservable(),
                    self.progressRepository.loadAll().asObservable()
                )
            }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] alphabets, progress in
                guard let self else { return }
                self.isLoading = false
                self.installedAlphabets = alphabets
                self.progressMap = Dictionary(uniqueKeysWithValues: progress.map { ($0.letterId, $0) })
            })
            .disposed(by: disposeBag)
    }
}
