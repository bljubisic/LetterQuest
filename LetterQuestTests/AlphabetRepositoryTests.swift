import Testing
import Foundation
import RxSwift
import RxBlocking
@testable import LetterQuest

// MARK: - Fixtures

private struct MockEntitlementProvider: AlphabetEntitlementProviding {
    let entitledIds: Set<String>
    func isEntitled(to productId: String) -> Bool { entitledIds.contains(productId) }
}

private let fakePaidAlphabet = Alphabet(
    id: "fictional",
    displayName: "Fictional",
    nativeName: "Fictional",
    scriptCode: "Zzzz",
    localeIdentifier: "und",
    isFree: false,
    letters: [],
    productId: "com.letterquest.tests.fictional"
)

struct AlphabetRepositoryTests {

    @Test("fetchAvailable includes the built-in Latin alphabet")
    func fetchAvailableIncludesLatin() throws {
        let repository = AlphabetRepository()
        let available = try repository.fetchAvailable().toBlocking().single()
        #expect(available.contains { $0.id == "latin" })
    }

    @Test("fetchInstalled includes free alphabets by default")
    func fetchInstalledIncludesFreeAlphabets() throws {
        let repository = AlphabetRepository()
        let installed = try repository.fetchInstalled().toBlocking().single()
        #expect(installed.contains { $0.id == "latin" && $0.isFree })
    }

    @Test("fetchAvailable includes a non-free alphabet even without entitlement")
    func fetchAvailableIncludesUnownedPaidAlphabet() throws {
        let repository = AlphabetRepository(catalogue: [.latin, fakePaidAlphabet])
        let available = try repository.fetchAvailable().toBlocking().single()
        #expect(available.contains { $0.id == "fictional" })
    }

    @Test("fetchInstalled excludes a non-free alphabet the user isn't entitled to")
    func fetchInstalledExcludesUnownedPaidAlphabet() throws {
        let repository = AlphabetRepository(
            catalogue: [.latin, fakePaidAlphabet],
            entitlementProvider: MockEntitlementProvider(entitledIds: [])
        )
        let installed = try repository.fetchInstalled().toBlocking().single()
        #expect(installed.contains { $0.id == "latin" })
        #expect(!installed.contains { $0.id == "fictional" })
    }

    @Test("fetchInstalled includes a non-free alphabet once entitled")
    func fetchInstalledIncludesOwnedPaidAlphabet() throws {
        let repository = AlphabetRepository(
            catalogue: [.latin, fakePaidAlphabet],
            entitlementProvider: MockEntitlementProvider(entitledIds: ["com.letterquest.tests.fictional"])
        )
        let installed = try repository.fetchInstalled().toBlocking().single()
        #expect(installed.contains { $0.id == "fictional" })
    }

    @Test("StubAlphabetEntitlementProvider denies every alphabet")
    func stubProviderDeniesEverything() {
        let stub = StubAlphabetEntitlementProvider()
        #expect(stub.isEntitled(to: "latin") == false)
        #expect(stub.isEntitled(to: "anything") == false)
    }
}
