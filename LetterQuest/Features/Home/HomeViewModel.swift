import Foundation
import RxSwift
import RxRelay

final class HomeViewModel: ObservableObject {

    // MARK: - Outputs

    @Published var letters: [Letter] = []
    @Published var progressMap: [UUID: ChildProgress] = [:]
    @Published var isLoading = false

    // MARK: - Private

    private let letterRepository: LetterRepositoryProtocol
    private let progressRepository: ProgressRepositoryProtocol
    private let router: AppRouter
    private let loadTrigger = PublishRelay<Void>()
    private let disposeBag = DisposeBag()

    init(
        letterRepository: LetterRepositoryProtocol,
        progressRepository: ProgressRepositoryProtocol,
        router: AppRouter
    ) {
        self.letterRepository   = letterRepository
        self.progressRepository = progressRepository
        self.router             = router

        bindLoad()
    }

    func load() {
        loadTrigger.accept(())
    }

    func selectLetter(_ letter: Letter) {
        router.push(.practice(letterId: letter.id))
    }

    // MARK: - Bindings

    private func bindLoad() {
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
                self?.isLoading = false
                self?.letters = letters
                self?.progressMap = Dictionary(
                    uniqueKeysWithValues: progress.map { ($0.letterId, $0) }
                )
            })
            .disposed(by: disposeBag)
    }
}
