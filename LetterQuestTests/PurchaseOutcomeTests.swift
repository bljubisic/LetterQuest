import Testing
import Foundation
@testable import LetterQuest

struct PurchaseOutcomeTests {

    @Test("purchased and cancelled need no user-facing message")
    func successAndCancelNeedNoMessage() {
        #expect(PurchaseOutcome.purchased.userMessage == nil)
        #expect(PurchaseOutcome.cancelled.userMessage == nil)
    }

    @Test("every other outcome has a non-empty, child-appropriate message")
    func otherOutcomesHaveMessages() {
        let outcomes: [PurchaseOutcome] = [
            .alreadyOwned,
            .pending,
            .failed(.network),
            .failed(.verificationFailed),
            .failed(.unknown("raw StoreKit error text"))
        ]
        for outcome in outcomes {
            #expect(outcome.userMessage?.isEmpty == false, "expected a message for \(outcome)")
        }
    }

    @Test("a failure's user message never leaks the raw underlying reason")
    func failureMessageNeverLeaksRawReason() {
        let rawReason = "NSURLErrorDomain -1009 the internet connection appears to be offline"
        let message = PurchaseOutcome.failed(.unknown(rawReason)).userMessage
        #expect(message?.contains(rawReason) == false)
    }
}
