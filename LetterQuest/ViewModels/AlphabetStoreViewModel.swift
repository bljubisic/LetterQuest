import Foundation
import RxSwift
import RxRelay

/// Drives `AlphabetStoreView` by loading the alphabet catalogue, localized
/// StoreKit pricing, and ownership state, then exposing them as
/// `@Published` properties for SwiftUI to observe.
///
/// Mirrors `WordsListViewModel`'s `loadTrigger` → `flatMapLatest` pipeline,
/// and `SettingsViewModel`'s pattern of surfacing a one-shot result via a
/// `@Published` property the view turns into an alert.
final class AlphabetStoreViewModel: AlphabetStoreViewModelProtocol {

    // MARK: - AlphabetStoreViewModelProtocol outputs

    @Published private(set) var rows: [AlphabetStoreRow] = []
    @Published private(set) var isLoading = false
    @Published private(set) var purchasingAlphabetId: String?
    @Published private(set) var alertMessage: String?
    @Published private(set) var alertIsSuccess = false

    // MARK: - Private

    private let alphabetRepository: AlphabetRepositoryProtocol
    private let purchaseService: PurchaseServiceProtocol
    private let entitlementProvider: AlphabetEntitlementProviding
    private let router: AppRouter
    private let loadTrigger = PublishRelay<Void>()
    private let disposeBag = DisposeBag()

    // MARK: - Init

    /// - Parameters:
    ///   - alphabetRepository: Source of the alphabet catalogue and ownership state.
    ///   - purchaseService: Buys packs, restores purchases, and prices them.
    ///   - entitlementProvider: Refreshed right after a purchase/restore so
    ///     ownership state updates without an app relaunch.
    ///   - router: Navigation coordinator shared across the app.
    init(
        alphabetRepository: AlphabetRepositoryProtocol,
        purchaseService: PurchaseServiceProtocol,
        entitlementProvider: AlphabetEntitlementProviding,
        router: AppRouter
    ) {
        self.alphabetRepository  = alphabetRepository
        self.purchaseService     = purchaseService
        self.entitlementProvider = entitlementProvider
        self.router               = router

        bindLoadTrigger()
        load()
    }

    // MARK: - AlphabetStoreViewModelProtocol inputs

    func load() {
        loadTrigger.accept(())
    }

    func purchase(_ row: AlphabetStoreRow) {
        guard !row.isOwned, let productId = row.alphabet.productId else { return }

        purchasingAlphabetId = row.alphabet.id
        purchaseService.purchase(productId: productId)
            .flatMap { [entitlementProvider] outcome -> Single<PurchaseOutcome> in
                guard case .purchased = outcome else { return .just(outcome) }
                return entitlementProvider.refresh().andThen(.just(outcome))
            }
            .observe(on: MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] outcome in
                guard let self else { return }
                self.purchasingAlphabetId = nil
                if case .purchased = outcome {
                    self.load()
                } else {
                    self.alertIsSuccess = false
                    self.alertMessage = outcome.userMessage
                }
            })
            .disposed(by: disposeBag)
    }

    func restorePurchases() {
        isLoading = true
        purchaseService.restorePurchases()
            .andThen(entitlementProvider.refresh())
            .observe(on: MainScheduler.instance)
            .subscribe(onCompleted: { [weak self] in
                self?.alertIsSuccess = true
                self?.alertMessage = "Purchases restored!"
                self?.load()
            }, onError: { [weak self] _ in
                self?.isLoading = false
                self?.alertIsSuccess = false
                self?.alertMessage = "Couldn't restore purchases. Please try again."
            })
            .disposed(by: disposeBag)
    }

    func dismissAlert() {
        alertMessage = nil
    }

    // MARK: - Rx pipeline

    private func bindLoadTrigger() {
        loadTrigger
            .do(onNext: { [weak self] in self?.isLoading = true })
            .flatMapLatest { [weak self] () -> Observable<[AlphabetStoreRow]> in
                guard let self else { return .empty() }
                return self.fetchRows().asObservable()
            }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] rows in
                self?.isLoading = false
                self?.rows = rows
            })
            .disposed(by: disposeBag)
    }

    /// Combines the catalogue, ownership state, and localized pricing for
    /// every purchasable alphabet into display-ready rows.
    private func fetchRows() -> Single<[AlphabetStoreRow]> {
        Single.zip(alphabetRepository.fetchAvailable(), alphabetRepository.fetchInstalled())
            .flatMap { [purchaseService] available, installed -> Single<[AlphabetStoreRow]> in
                let installedIds = Set(installed.map(\.id))
                let paidProductIds = available.compactMap { $0.isFree ? nil : $0.productId }
                return purchaseService.fetchProducts(ids: paidProductIds)
                    .map { products in
                        let priceById = Dictionary(uniqueKeysWithValues: products.map { ($0.id, $0.priceText) })
                        return available.map { alphabet in
                            AlphabetStoreRow(
                                alphabet: alphabet,
                                priceText: alphabet.isFree ? nil : alphabet.productId.flatMap { priceById[$0] },
                                isOwned: installedIds.contains(alphabet.id)
                            )
                        }
                    }
            }
    }
}
