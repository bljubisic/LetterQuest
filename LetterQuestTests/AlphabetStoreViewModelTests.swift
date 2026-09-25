import Testing
import Foundation
import RxSwift
@testable import LetterQuest

// MARK: - Fixtures

private let fakeProductId = "com.letterquest.tests.fictional"

private let fakePaidAlphabet = Alphabet(
    id: "fictional",
    displayName: "Fictional",
    nativeName: "Fictional",
    scriptCode: "Zzzz",
    localeIdentifier: "und",
    isFree: false,
    letters: [],
    productId: fakeProductId
)

private let fakePrice = PurchasableAlphabet(id: fakeProductId, displayName: "Fictional", priceText: "$2.99")

// MARK: - Bundled pack fixtures (issue #52)

private let bundleProductId = "com.letterquest.tests.bundle"

private let bundleMemberOne = Alphabet(
    id: "bundle-one",
    displayName: "Bundle One",
    nativeName: "Bundle One",
    scriptCode: "Zzzz",
    localeIdentifier: "und",
    isFree: false,
    letters: [],
    productId: bundleProductId
)

private let bundleMemberTwo = Alphabet(
    id: "bundle-two",
    displayName: "Bundle Two",
    nativeName: "Bundle Two",
    scriptCode: "Zzzz",
    localeIdentifier: "und",
    isFree: false,
    letters: [],
    productId: bundleProductId
)

private let bundlePrice = PurchasableAlphabet(id: bundleProductId, displayName: "Bundle", priceText: "$4.99")

// MARK: - Helpers

/// Builds a view model wired to real `AlphabetRepository`/
/// `StoreKitAlphabetEntitlementProvider` instances backed by `mock`, so
/// ownership state genuinely flows end-to-end through a purchase/restore —
/// exactly like production, just without a real StoreKit call.
private func makeVM(
    catalogue: [Alphabet] = [.latin, fakePaidAlphabet],
    mock: MockPurchaseService,
    router: AppRouter = AppRouter()
) -> (AlphabetStoreViewModel, AlphabetEntitlementProviding) {
    let entitlementProvider = StoreKitAlphabetEntitlementProvider(purchaseService: mock)
    let alphabetRepository = AlphabetRepository(catalogue: catalogue, entitlementProvider: entitlementProvider)
    let vm = AlphabetStoreViewModel(
        alphabetRepository:  alphabetRepository,
        purchaseService:     mock,
        entitlementProvider: entitlementProvider,
        router:              router
    )
    return (vm, entitlementProvider)
}

/// `DispatchQueue.main.sync {}` only flushes work already enqueued on the
/// main queue at the moment it's called. `restorePurchases()`'s chain
/// completes on a background thread and then calls `load()` from within its
/// own main-queue callback — `load()`'s *own* main-queue hop is only
/// enqueued once that outer callback starts running, so it can still be
/// pending when a single `sync {}` returns. Calling it a few times in a row
/// drains each successive hop instead of assuming a fixed chain depth.
private func pumpMainQueue(times: Int = 5) {
    for _ in 0..<times { DispatchQueue.main.sync {} }
}

// MARK: - Catalogue / pricing

struct AlphabetStoreViewModelCatalogueTests {

    @Test("a free alphabet has no price and is already owned")
    func freeAlphabetIsOwnedWithNoPrice() {
        let mock = MockPurchaseService()
        let (vm, _) = makeVM(mock: mock)
        DispatchQueue.main.sync {}

        let row = vm.rows.first { $0.id == "latin" }
        #expect(row?.isOwned == true)
        #expect(row?.priceText == nil)
    }

    @Test("a paid, unentitled alphabet is locked and shows its localized price")
    func paidAlphabetIsLockedWithPrice() {
        let mock = MockPurchaseService()
        mock.products = [fakePrice]
        let (vm, _) = makeVM(mock: mock)
        DispatchQueue.main.sync {}

        let row = vm.rows.first { $0.id == "fictional" }
        #expect(row?.isOwned == false)
        #expect(row?.priceText == "$2.99")
    }
}

// MARK: - Purchase

struct AlphabetStoreViewModelPurchaseTests {

    @Test("a successful purchase flips the row to owned without a manual reload")
    func successfulPurchaseUnlocksRow() {
        let mock = MockPurchaseService()
        mock.products = [fakePrice]
        mock.purchaseOutcome = .purchased
        mock.entitlements = [fakeProductId]
        let (vm, _) = makeVM(mock: mock)
        DispatchQueue.main.sync {}

        let row = try! #require(vm.rows.first { $0.id == "fictional" })
        vm.purchase(row)
        pumpMainQueue()

        #expect(vm.rows.first { $0.id == "fictional" }?.isOwned == true)
        #expect(vm.alertMessage == nil)
    }

    @Test("purchasingAlphabetId is cleared once the purchase resolves, never left stuck")
    func purchasingAlphabetIdLifecycle() {
        let mock = MockPurchaseService()
        mock.products = [fakePrice]
        mock.purchaseOutcome = .purchased
        let (vm, _) = makeVM(mock: mock)
        DispatchQueue.main.sync {}

        let row = try! #require(vm.rows.first { $0.id == "fictional" })
        vm.purchase(row)
        DispatchQueue.main.sync {}

        #expect(vm.purchasingAlphabetId == nil)
    }

    @Test("cancelling the purchase sheet shows no alert", arguments: [PurchaseOutcome.cancelled])
    func cancelledShowsNoAlert(outcome: PurchaseOutcome) {
        let mock = MockPurchaseService()
        mock.products = [fakePrice]
        mock.purchaseOutcome = outcome
        let (vm, _) = makeVM(mock: mock)
        DispatchQueue.main.sync {}

        let row = try! #require(vm.rows.first { $0.id == "fictional" })
        vm.purchase(row)
        DispatchQueue.main.sync {}

        #expect(vm.alertMessage == nil)
    }

    @Test(
        "a non-purchased outcome surfaces its fixed user message",
        arguments: [
            PurchaseOutcome.alreadyOwned,
            .pending,
            .failed(.network),
            .failed(.verificationFailed)
        ]
    )
    func nonPurchasedOutcomeShowsAlert(outcome: PurchaseOutcome) {
        let mock = MockPurchaseService()
        mock.products = [fakePrice]
        mock.purchaseOutcome = outcome
        let (vm, _) = makeVM(mock: mock)
        DispatchQueue.main.sync {}

        let row = try! #require(vm.rows.first { $0.id == "fictional" })
        vm.purchase(row)
        DispatchQueue.main.sync {}

        #expect(vm.alertMessage == outcome.userMessage)
    }
}

// MARK: - Restore

struct AlphabetStoreViewModelRestoreTests {

    @Test("a successful restore re-syncs ownership and shows a success alert")
    func successfulRestoreUnlocksOwnedRows() {
        let mock = MockPurchaseService()
        mock.products = [fakePrice]
        let (vm, _) = makeVM(mock: mock)
        DispatchQueue.main.sync {}
        #expect(vm.rows.first { $0.id == "fictional" }?.isOwned == false)

        mock.entitlements = [fakeProductId]
        vm.restorePurchases()
        pumpMainQueue()

        #expect(vm.rows.first { $0.id == "fictional" }?.isOwned == true)
        #expect(vm.alertIsSuccess == true)
        #expect(vm.alertMessage != nil)
    }
}

// MARK: - Bundled packs (issue #52)

struct AlphabetStoreViewModelBundledPackTests {

    @Test("alphabets sharing a product id collapse into one row")
    func sharedProductIdCollapsesIntoOneRow() {
        let mock = MockPurchaseService()
        mock.products = [bundlePrice]
        let (vm, _) = makeVM(catalogue: [.latin, bundleMemberOne, bundleMemberTwo], mock: mock)
        DispatchQueue.main.sync {}

        #expect(vm.rows.count == 2) // English + one bundled row
        let bundleRow = try! #require(vm.rows.first { $0.id != "latin" })
        #expect(bundleRow.alphabets.count == 2)
        #expect(bundleRow.priceText == "$4.99")
        #expect(bundleRow.displayName == "Bundle One, Bundle Two") // no name registered for this test product id
    }

    @Test("a registered pack product id uses its marketing display name")
    func registeredPackUsesMarketingName() {
        let extendedLatin = Alphabet(
            id: "german", displayName: "German", nativeName: "Deutsch",
            scriptCode: "Latn", localeIdentifier: "de", isFree: false, letters: [],
            productId: Alphabet.extendedLatinProductId
        )
        let mock = MockPurchaseService()
        mock.products = [PurchasableAlphabet(id: Alphabet.extendedLatinProductId, displayName: "Extended Latin Pack", priceText: "$2.99")]
        let (vm, _) = makeVM(catalogue: [.latin, extendedLatin], mock: mock)
        DispatchQueue.main.sync {}

        let row = try! #require(vm.rows.first { $0.alphabets.contains { $0.id == "german" } })
        #expect(row.displayName == "Extended Latin Pack")
    }

    @Test("purchasing a bundled row marks every member alphabet owned")
    func purchasingBundleUnlocksAllMembers() {
        let mock = MockPurchaseService()
        mock.products = [bundlePrice]
        mock.purchaseOutcome = .purchased
        mock.entitlements = [bundleProductId]
        let (vm, _) = makeVM(catalogue: [.latin, bundleMemberOne, bundleMemberTwo], mock: mock)
        DispatchQueue.main.sync {}

        let row = try! #require(vm.rows.first { $0.id != "latin" })
        vm.purchase(row)
        pumpMainQueue()

        let updated = try! #require(vm.rows.first { $0.id != "latin" })
        #expect(updated.isOwned == true)
    }

    @Test("a lone, unbundled alphabet keeps its own name and id, unaffected by grouping")
    func unbundledAlphabetIsUnaffected() {
        let mock = MockPurchaseService()
        mock.products = [fakePrice]
        let (vm, _) = makeVM(mock: mock)
        DispatchQueue.main.sync {}

        let row = try! #require(vm.rows.first { $0.id == "fictional" })
        #expect(row.alphabets.count == 1)
        #expect(row.displayName == "Fictional")
        #expect(row.nativeName == "Fictional")
    }
}
