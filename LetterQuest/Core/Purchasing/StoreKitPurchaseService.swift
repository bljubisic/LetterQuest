import Foundation
import RxSwift
import StoreKit

/// StoreKit 2–backed implementation of `PurchaseServiceProtocol`.
///
/// Every StoreKit call is `async`/`throws` or an `AsyncSequence`; each is
/// bridged into RxSwift here so the rest of the app (built entirely on Rx)
/// doesn't need two concurrency styles side by side. Only `.verified`
/// transactions are ever trusted — unverified ones are treated as failures,
/// per Apple's guidance.
final class StoreKitPurchaseService: PurchaseServiceProtocol {

    private let updatesSubject = PublishSubject<String>()
    private var updatesTask: Task<Void, Never>?

    init() {
        // Long-lived listener for transactions that complete outside a
        // direct `purchase()` call — e.g. a delayed Ask-to-Buy approval, or
        // a purchase restored via family sharing on another device.
        updatesTask = Task { [weak self] in
            for await result in Transaction.updates {
                guard let transaction = Self.verifiedTransaction(from: result) else { continue }
                await transaction.finish()
                self?.updatesSubject.onNext(transaction.productID)
            }
        }
    }

    deinit {
        updatesTask?.cancel()
    }

    var entitlementUpdates: Observable<String> { updatesSubject.asObservable() }

    // MARK: - PurchaseServiceProtocol

    func fetchProducts(ids: [String]) -> Single<[PurchasableAlphabet]> {
        Single.create { observer in
            let task = Task {
                do {
                    let products = try await Product.products(for: Set(ids))
                    let purchasable = products.map {
                        PurchasableAlphabet(id: $0.id, displayName: $0.displayName, priceText: $0.displayPrice)
                    }
                    observer(.success(purchasable))
                } catch {
                    observer(.failure(error))
                }
            }
            return Disposables.create { task.cancel() }
        }
    }

    func purchase(productId: String) -> Single<PurchaseOutcome> {
        Single.create { observer in
            let task = Task {
                // Check entitlement first — a non-consumable the user
                // already owns shouldn't prompt StoreKit's purchase sheet.
                for await result in Transaction.currentEntitlements {
                    if let transaction = Self.verifiedTransaction(from: result), transaction.productID == productId {
                        observer(.success(.alreadyOwned))
                        return
                    }
                }

                do {
                    guard let product = try await Product.products(for: [productId]).first else {
                        observer(.success(.failed(.unknown("product not found"))))
                        return
                    }
                    switch try await product.purchase() {
                    case .success(let verification):
                        guard let transaction = Self.verifiedTransaction(from: verification) else {
                            observer(.success(.failed(.verificationFailed)))
                            return
                        }
                        await transaction.finish()
                        observer(.success(.purchased))
                    case .userCancelled:
                        observer(.success(.cancelled))
                    case .pending:
                        observer(.success(.pending))
                    @unknown default:
                        observer(.success(.failed(.unknown("unrecognized purchase result"))))
                    }
                } catch StoreKitError.networkError {
                    observer(.success(.failed(.network)))
                } catch {
                    observer(.success(.failed(.unknown(error.localizedDescription))))
                }
            }
            return Disposables.create { task.cancel() }
        }
    }

    func restorePurchases() -> Completable {
        Completable.create { observer in
            let task = Task {
                do {
                    try await AppStore.sync()
                    observer(.completed)
                } catch {
                    observer(.error(error))
                }
            }
            return Disposables.create { task.cancel() }
        }
    }

    func currentEntitlements() -> Single<Set<String>> {
        Single.create { observer in
            let task = Task {
                var ids: Set<String> = []
                for await result in Transaction.currentEntitlements {
                    if let transaction = Self.verifiedTransaction(from: result) {
                        ids.insert(transaction.productID)
                    }
                }
                observer(.success(ids))
            }
            return Disposables.create { task.cancel() }
        }
    }

    // MARK: - Verification

    private static func verifiedTransaction(from result: VerificationResult<Transaction>) -> Transaction? {
        switch result {
        case .verified(let transaction): return transaction
        case .unverified:                return nil
        }
    }
}
