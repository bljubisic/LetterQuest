import Foundation

/// The underlying cause of a `.failed` `PurchaseOutcome`. Never shown to the
/// user directly — `PurchaseOutcome.userMessage` maps it to a fixed,
/// child/parent-appropriate string instead.
enum PurchaseFailureReason: Equatable {
    case network
    case verificationFailed
    case unknown(String)
}

/// The result of attempting to buy an alphabet pack.
enum PurchaseOutcome: Equatable {
    /// The purchase completed and was verified.
    case purchased
    /// The user already owns this pack — checked before ever contacting
    /// StoreKit, so no duplicate purchase is attempted.
    case alreadyOwned
    /// Requires approval from a parent/guardian (e.g. Ask to Buy). Not an
    /// error — the purchase may still complete later, surfaced via
    /// `PurchaseServiceProtocol.entitlementUpdates`.
    case pending
    /// The user backed out of the purchase sheet themselves.
    case cancelled
    case failed(PurchaseFailureReason)
}

extension PurchaseOutcome {
    /// A single, consistent, child/parent-appropriate message — never raw
    /// StoreKit/network error text. `nil` when no alert should be shown:
    /// `.purchased` gets a celebration instead of an error dialog, and
    /// `.cancelled` needs nothing since the user chose to back out.
    var userMessage: String? {
        switch self {
        case .purchased, .cancelled:
            return nil
        case .alreadyOwned:
            return "You already own this alphabet pack!"
        case .pending:
            return "Ask a grown-up to approve this purchase."
        case .failed(.network):
            return "Couldn't connect to the App Store. Check your internet connection and try again."
        case .failed(.verificationFailed), .failed(.unknown):
            return "Something went wrong. Please try again."
        }
    }
}
