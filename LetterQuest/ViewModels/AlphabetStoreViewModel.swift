import Foundation
import RxSwift
import RxRelay

/// Drives `AlphabetStoreView` by loading the alphabet catalogue, localized
/// StoreKit pricing, and ownership state, then exposing them as
/// `@Published` properties for SwiftUI to observe.
///
/// Mirrors `HomeViewModel`'s `loadTrigger` → `flatMapLatest` pipeline,
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
        guard !row.isOwned, let productId = row.alphabets.first?.productId else { return }

        purchasingAlphabetId = row.id
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

    /// Marketing names for bundled packs — more than one `Alphabet` sharing
    /// a single StoreKit product id, purchased/restored as one unit (see
    /// issue #52). Any bundle not listed here falls back to joining its
    /// members' own display names, so a future pack still renders sensibly
    /// even before someone gives it a proper name here.
    private static let packDisplayNames: [String: String] = [
        "com.persukibo.letterquest.alphabet.extended_latin": "Extended Latin Pack"
    ]

    /// Combines the catalogue, ownership state, and localized pricing for
    /// every purchasable alphabet into display-ready rows. Alphabets that
    /// share a non-nil `productId` collapse into a single bundled row.
    private func fetchRows() -> Single<[AlphabetStoreRow]> {
        Single.zip(alphabetRepository.fetchAvailable(), alphabetRepository.fetchInstalled())
            .flatMap { [purchaseService] available, installed -> Single<[AlphabetStoreRow]> in
                let installedIds = Set(installed.map(\.id))
                let groups = Self.grouped(available)
                let paidProductIds = available.compactMap { $0.isFree ? nil : $0.productId }
                return purchaseService.fetchProducts(ids: paidProductIds)
                    .map { products in
                        let priceById = Dictionary(uniqueKeysWithValues: products.map { ($0.id, $0.priceText) })
                        return groups.map { members in
                            Self.makeRow(for: members, priceById: priceById, installedIds: installedIds)
                        }
                    }
            }
    }

    /// Groups `alphabets` by `productId` (falling back to the alphabet's
    /// own `id` when `productId` is `nil`, so free/unbundled alphabets each
    /// stay their own group), preserving the catalogue's original order.
    private static func grouped(_ alphabets: [Alphabet]) -> [[Alphabet]] {
        var order: [String] = []
        var membersByKey: [String: [Alphabet]] = [:]
        for alphabet in alphabets {
            let key = alphabet.productId ?? alphabet.id
            if membersByKey[key] == nil { order.append(key) }
            membersByKey[key, default: []].append(alphabet)
        }
        return order.map { membersByKey[$0] ?? [] }
    }

    private static func makeRow(
        for alphabets: [Alphabet],
        priceById: [String: String],
        installedIds: Set<String>
    ) -> AlphabetStoreRow {
        let productId = alphabets.first?.productId
        // A product id explicitly registered in `packDisplayNames` always
        // shows its pack name, even if only some of its member alphabets
        // have shipped so far (e.g. a partial content rollout) — grouping
        // is keyed by "is this a named pack", not by how many alphabets
        // currently happen to share the id.
        let packName = productId.flatMap { packDisplayNames[$0] }
        let displayName = packName
            ?? (alphabets.count == 1 ? alphabets[0].displayName : alphabets.map(\.displayName).joined(separator: ", "))
        let nativeName = (packName != nil || alphabets.count > 1)
            ? alphabets.map(\.displayName).joined(separator: " · ")
            : alphabets[0].nativeName
        return AlphabetStoreRow(
            alphabets:  alphabets,
            displayName: displayName,
            nativeName:  nativeName,
            priceText:   alphabets[0].isFree ? nil : productId.flatMap { priceById[$0] },
            isOwned:     alphabets.allSatisfy { installedIds.contains($0.id) }
        )
    }
}
