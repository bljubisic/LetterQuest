import Foundation

/// The contract that `AlphabetStoreView` depends on.
///
/// Keeping the view generic over `AlphabetStoreViewModelProtocol` makes it
/// trivial to inject a mock during testing or SwiftUI previews.
protocol AlphabetStoreViewModelProtocol: ObservableObject {

    /// Every known alphabet, combined with its price (if any) and owned state.
    var rows: [AlphabetStoreRow] { get }

    /// `true` while the catalogue/pricing/restore fetch is in flight.
    var isLoading: Bool { get }

    /// The `AlphabetStoreRow.id` currently being purchased, if any — drives
    /// a per-row spinner/disabled state so only the tapped row reacts.
    var purchasingAlphabetId: String? { get }

    /// A fixed, user-facing message to show in an alert, or `nil` when no
    /// alert should be shown.
    var alertMessage: String? { get }

    /// Whether `alertMessage` describes a success (e.g. "Purchases
    /// restored!") or a failure — purely a styling hint for the view.
    var alertIsSuccess: Bool { get }

    /// Triggers a (re-)load of the alphabet catalogue, pricing, and
    /// ownership state from the repositories/services.
    func load()

    /// Buys the alphabet backing `row`, if it isn't already owned.
    func purchase(_ row: AlphabetStoreRow)

    /// Re-derives ownership from the App Store — "Restore Purchases".
    func restorePurchases()

    /// Dismisses the current alert, if any.
    func dismissAlert()
}
