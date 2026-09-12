import Testing
import Foundation
import RxSwift
import RxBlocking
@testable import LetterQuest

struct StoreKitAlphabetEntitlementProviderTests {

    private let cyrillicProductId = "com.persukibo.letterquest.alphabet.cyrillic_sr"

    @Test("isEntitled is false before refresh() has run")
    func startsUnentitled() {
        let mock = MockPurchaseService()
        let provider = StoreKitAlphabetEntitlementProvider(purchaseService: mock)
        #expect(provider.isEntitled(to: cyrillicProductId) == false)
    }

    @Test("refresh() populates entitlements from currentEntitlements()")
    func refreshPopulatesEntitlements() throws {
        let mock = MockPurchaseService()
        mock.entitlements = [cyrillicProductId]
        let provider = StoreKitAlphabetEntitlementProvider(purchaseService: mock)
        try provider.refresh().toBlocking().first()
        #expect(provider.isEntitled(to: cyrillicProductId))
    }

    @Test("an unrelated product id is never entitled")
    func unrelatedProductIsNotEntitled() throws {
        let mock = MockPurchaseService()
        mock.entitlements = [cyrillicProductId]
        let provider = StoreKitAlphabetEntitlementProvider(purchaseService: mock)
        try provider.refresh().toBlocking().first()
        #expect(provider.isEntitled(to: "com.persukibo.letterquest.alphabet.other") == false)
    }

    @Test("a live entitlement update grants access without calling refresh() again")
    func liveUpdateGrantsEntitlement() {
        let mock = MockPurchaseService()
        let provider = StoreKitAlphabetEntitlementProvider(purchaseService: mock)
        #expect(provider.isEntitled(to: cyrillicProductId) == false)
        mock.simulateEntitlementUpdate(productId: cyrillicProductId)
        #expect(provider.isEntitled(to: cyrillicProductId))
    }
}
