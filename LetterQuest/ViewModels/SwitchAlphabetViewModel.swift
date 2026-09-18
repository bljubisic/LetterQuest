import Foundation
import RxSwift
import RxRelay

/// Drives `SwitchAlphabetView` by loading the installed alphabet catalogue
/// and the persisted active-alphabet selection, then exposing them as
/// `@Published` properties for SwiftUI to observe.
final class SwitchAlphabetViewModel: SwitchAlphabetViewModelProtocol {

    // MARK: - SwitchAlphabetViewModelProtocol outputs

    @Published private(set) var installedAlphabets: [Alphabet] = []
    @Published private(set) var activeAlphabetId: String = Alphabet.latinId
    @Published private(set) var isLoading = false

    // MARK: - Private state

    /// The full loaded settings, kept around so `selectAlphabet` can update
    /// just `activeAlphabetId` via a lens without wiping out other fields
    /// (like `difficulty`) that this screen doesn't otherwise touch.
    private var currentSettings = AppSettings.default

    // MARK: - Private Rx

    private let alphabetRepository: AlphabetRepositoryProtocol
    private let settingsRepository: SettingsRepositoryProtocol
    private let router: AppRouter
    private let loadTrigger = PublishRelay<Void>()
    private let disposeBag = DisposeBag()

    // MARK: - Init

    /// - Parameters:
    ///   - alphabetRepository: Source of installed alphabets.
    ///   - settingsRepository: Persists the active-alphabet selection.
    ///   - router: Navigation coordinator shared across the app.
    init(
        alphabetRepository: AlphabetRepositoryProtocol,
        settingsRepository: SettingsRepositoryProtocol,
        router: AppRouter
    ) {
        self.alphabetRepository = alphabetRepository
        self.settingsRepository = settingsRepository
        self.router             = router

        bindLoadTrigger()
        load()
    }

    // MARK: - SwitchAlphabetViewModelProtocol inputs

    func load() {
        loadTrigger.accept(())
    }

    /// Makes `alphabetId` the active alphabet, persists the choice, and pops
    /// back to Home — whose own `onAppear { load() }` picks up the new
    /// selection automatically.
    func selectAlphabet(_ alphabetId: String) {
        currentSettings = AppSettings.lensActiveAlphabetId.set(currentSettings, alphabetId)
        settingsRepository.save(currentSettings)
            .observe(on: MainScheduler.instance)
            .subscribe(onCompleted: { [weak self] in
                self?.router.pop()
            })
            .disposed(by: disposeBag)
    }

    func navigateToStore() {
        router.push(.alphabetStore)
    }

    // MARK: - Rx pipeline

    private func bindLoadTrigger() {
        loadTrigger
            .do(onNext: { [weak self] in self?.isLoading = true })
            .flatMapLatest { [weak self] () -> Observable<([Alphabet], AppSettings)> in
                guard let self else { return .empty() }
                return Observable.zip(
                    self.alphabetRepository.fetchInstalled().asObservable(),
                    self.settingsRepository.load().asObservable()
                )
            }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] alphabets, settings in
                guard let self else { return }
                self.isLoading = false
                self.installedAlphabets = alphabets
                self.currentSettings = settings
                self.activeAlphabetId = settings.activeAlphabetId
                    ?? alphabets.first?.id
                    ?? Alphabet.latinId
            })
            .disposed(by: disposeBag)
    }
}
