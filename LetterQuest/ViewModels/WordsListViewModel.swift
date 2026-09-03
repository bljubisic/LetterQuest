import Foundation
import RxSwift
import RxRelay

/// Drives `WordsListView` by loading the curated word catalogue and word-level
/// progress, then exposing them as `@Published` properties for SwiftUI to observe.
///
/// Mirrors `HomeViewModel`'s load pipeline, minus the case picker (words have no
/// upper/lower split).
final class WordsListViewModel: WordsListViewModelProtocol {

    // MARK: - WordsListViewModelProtocol outputs

    @Published private(set) var words: [Word] = []
    @Published private(set) var progressMap: [UUID: WordProgress] = [:]
    @Published private(set) var isLoading = false

    // MARK: - Private Rx

    private let wordRepository: WordRepositoryProtocol
    private let wordProgressRepository: WordProgressRepositoryProtocol
    private let router: AppRouter
    private let loadTrigger = PublishRelay<Void>()
    private let disposeBag = DisposeBag()

    // MARK: - Init

    /// - Parameters:
    ///   - wordRepository: Source of the curated word list.
    ///   - wordProgressRepository: Persistent store for word-level completion.
    ///   - router: Navigation coordinator shared across the app.
    init(
        wordRepository: WordRepositoryProtocol,
        wordProgressRepository: WordProgressRepositoryProtocol,
        router: AppRouter
    ) {
        self.wordRepository         = wordRepository
        self.wordProgressRepository = wordProgressRepository
        self.router                 = router

        bindLoadTrigger()
        load()
    }

    // MARK: - WordsListViewModelProtocol inputs

    func load() {
        loadTrigger.accept(())
    }

    func selectWord(_ word: Word) {
        router.push(.word(wordId: word.id))
    }

    // MARK: - Rx pipeline

    private func bindLoadTrigger() {
        loadTrigger
            .do(onNext: { [weak self] in self?.isLoading = true })
            .flatMapLatest { [weak self] () -> Observable<([Word], [WordProgress])> in
                guard let self else { return .empty() }
                return Observable.zip(
                    self.wordRepository.fetchAll().asObservable(),
                    self.wordProgressRepository.loadAll().asObservable()
                )
            }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] words, progress in
                self?.isLoading   = false
                self?.words       = words
                self?.progressMap = Dictionary(uniqueKeysWithValues: progress.map { ($0.wordId, $0) })
            })
            .disposed(by: disposeBag)
    }
}
