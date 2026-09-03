import Foundation
import RxSwift
import RxRelay

/// Drives `HomeView` by loading the letter catalogue and progress data,
/// then exposing them as `@Published` properties for SwiftUI to observe.
///
/// Internally the reactive pipeline is built with RxSwift. `@Published`
/// properties act as a thin SwiftUI-compatible bridge over the Rx layer.
final class HomeViewModel: HomeViewModelProtocol {

    // MARK: - HomeViewModelProtocol outputs

    /// Letters filtered by `selectedCase`.
    var letters: [Letter] { allLetters.filter { $0.letterCase == selectedCase } }

    /// Progress keyed by letter id; absent entries mean the letter was never attempted.
    @Published private(set) var progressMap: [UUID: ChildProgress] = [:]

    /// `true` while the combined repository fetch is in flight.
    @Published private(set) var isLoading = false

    /// Whether the grid is showing uppercase or lowercase letters.
    @Published private(set) var selectedCase: LetterCase = .upper

    /// `true` once every uppercase and lowercase letter has been completed.
    var isWordModeUnlocked: Bool {
        !allLetters.isEmpty && allLetters.allSatisfy { progressMap[$0.id]?.isCompleted == true }
    }

    // MARK: - Private state

    @Published private var allLetters: [Letter] = []

    // MARK: - Private Rx

    private let letterRepository: LetterRepositoryProtocol
    private let progressRepository: ProgressRepositoryProtocol
    private let router: AppRouter
    private let loadTrigger = PublishRelay<Void>()
    private let disposeBag = DisposeBag()

    // MARK: - Init

    /// - Parameters:
    ///   - letterRepository: Source of letter definitions.
    ///   - progressRepository: Persistent store for practice history.
    ///   - router: Navigation coordinator shared across the app.
    init(
        letterRepository: LetterRepositoryProtocol,
        progressRepository: ProgressRepositoryProtocol,
        router: AppRouter
    ) {
        self.letterRepository   = letterRepository
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
        router.push(.words)
    }

    /// Switches the letter grid between uppercase and lowercase.
    func selectCase(_ letterCase: LetterCase) {
        selectedCase = letterCase
    }

    // MARK: - Rx pipeline

    /// Wires the load trigger to a combined fetch of letters + progress.
    ///
    /// `flatMapLatest` cancels any in-flight request when the user triggers another
    /// load before the first one completes.
    private func bindLoadTrigger() {
        loadTrigger
            .do(onNext: { [weak self] in self?.isLoading = true })
            .flatMapLatest { [weak self] () -> Observable<([Letter], [ChildProgress])> in
                guard let self else { return .empty() }
                return Observable.zip(
                    self.letterRepository.fetchAll().asObservable(),
                    self.progressRepository.loadAll().asObservable()
                )
            }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] letters, progress in
                self?.isLoading   = false
                self?.allLetters  = letters
                self?.progressMap = Dictionary(uniqueKeysWithValues: progress.map { ($0.letterId, $0) })
            })
            .disposed(by: disposeBag)
    }
}
