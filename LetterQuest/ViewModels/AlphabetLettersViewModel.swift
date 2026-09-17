import Foundation
import RxSwift
import RxRelay

/// Drives `AlphabetLettersView` by loading a single installed alphabet
/// (fixed at construction time) and progress data, then exposing them as
/// `@Published` properties for SwiftUI to observe.
///
/// Mirrors `HomeViewModel`'s Rx pipeline, scoped to one alphabet instead of
/// whichever one is selected.
final class AlphabetLettersViewModel: AlphabetLettersViewModelProtocol {

    // MARK: - AlphabetLettersViewModelProtocol outputs

    var alphabetDisplayName: String { alphabet?.displayName ?? "" }

    /// Letters of this screen's alphabet, filtered by `selectedCase`.
    var letters: [Letter] {
        alphabet?.letters.filter { $0.letterCase == selectedCase } ?? []
    }

    @Published private(set) var progressMap: [UUID: ChildProgress] = [:]
    @Published private(set) var isLoading = false
    @Published private(set) var selectedCase: LetterCase = .upper

    /// `true` once every uppercase and lowercase letter of this alphabet has
    /// been completed, unlocking this alphabet's word practice.
    var isWordModeUnlocked: Bool {
        guard let alphabet, !alphabet.letters.isEmpty else { return false }
        return alphabet.letters.allSatisfy { progressMap[$0.id]?.isCompleted == true }
    }

    // MARK: - Private state

    @Published private var alphabet: Alphabet?

    /// This alphabet's own first uppercase letter — bootstraps unlocked by
    /// default, before any `ChildProgress` record exists.
    private var defaultUnlockedLetterId: UUID? {
        alphabet?.letters.first { $0.letterCase == .upper }?.id
    }

    // MARK: - Private Rx

    private let alphabetId: String
    private let alphabetRepository: AlphabetRepositoryProtocol
    private let progressRepository: ProgressRepositoryProtocol
    private let router: AppRouter
    private let loadTrigger = PublishRelay<Void>()
    private let disposeBag = DisposeBag()

    // MARK: - Init

    /// - Parameters:
    ///   - alphabetId: The `Alphabet.id` this screen is scoped to.
    ///   - alphabetRepository: Source of installed alphabets and their letters.
    ///   - progressRepository: Persistent store for practice history.
    ///   - router: Navigation coordinator shared across the app.
    init(
        alphabetId: String,
        alphabetRepository: AlphabetRepositoryProtocol,
        progressRepository: ProgressRepositoryProtocol,
        router: AppRouter
    ) {
        self.alphabetId         = alphabetId
        self.alphabetRepository = alphabetRepository
        self.progressRepository = progressRepository
        self.router             = router

        bindLoadTrigger()
        load()
    }

    // MARK: - AlphabetLettersViewModelProtocol inputs

    /// Fires the load pipeline. Called automatically on init and again from `AlphabetLettersView.onAppear` to refresh on return.
    func load() {
        loadTrigger.accept(())
    }

    /// Switches the letter grid between uppercase and lowercase.
    func selectCase(_ letterCase: LetterCase) {
        selectedCase = letterCase
    }

    /// Pushes the "Watch me draw" learn route for the tapped letter,
    /// so the child sees a stroke demonstration before practice begins.
    func selectLetter(_ letter: Letter) {
        router.push(.learn(letterId: letter.id))
    }

    /// Pushes this alphabet's word-practice list screen.
    func navigateToWords() {
        router.push(.words(alphabetId: alphabetId))
    }

    /// Whether `letter` is unlocked: an explicit `ChildProgress` record wins,
    /// otherwise it falls back to whether `letter` is this alphabet's own
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
                self.alphabet = alphabets.first { $0.id == self.alphabetId }
                self.progressMap = Dictionary(uniqueKeysWithValues: progress.map { ($0.letterId, $0) })
            })
            .disposed(by: disposeBag)
    }
}
