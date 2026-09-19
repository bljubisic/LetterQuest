import SwiftUI

/// The alphabet store: browse every known alphabet pack, buy locked ones,
/// and restore previous purchases.
///
/// Generic over `VM: AlphabetStoreViewModelProtocol` so that the same view
/// works with the real `AlphabetStoreViewModel` in production and with a
/// lightweight mock during Xcode previews or tests.
struct AlphabetStoreView<VM: AlphabetStoreViewModelProtocol>: View {

    /// A commerce action pending a parental gate. Wrapping both "Buy" and
    /// "Restore Purchases" behind the same gate, per App Store Review
    /// Guideline 1.3 (Kids Category) — see issue #50.
    private enum GateAction: Identifiable {
        case buy(AlphabetStoreRow)
        case restore

        var id: String {
            switch self {
            case .buy(let row): return "buy.\(row.id)"
            case .restore:      return "restore"
            }
        }
    }

    @ObservedObject var viewModel: VM

    @State private var pendingGateAction: GateAction?

    var body: some View {
        List {
            Section {
                ForEach(viewModel.rows) { row in
                    AlphabetStoreRowView(
                        row: row,
                        isPurchasing: viewModel.purchasingAlphabetId == row.alphabet.id,
                        onBuy: { pendingGateAction = .buy(row) }
                    )
                }
            }

            Section {
                Button("Restore Purchases") {
                    pendingGateAction = .restore
                }
                .disabled(viewModel.isLoading)
                .accessibilityHint("Re-checks the App Store for alphabet packs you already bought.")
                .accessibilityIdentifier("store.restoreButton")
            }
        }
        .navigationTitle("Alphabet Store")
        .overlay {
            if viewModel.isLoading {
                ProgressView().scaleEffect(1.5)
            }
        }
        .onAppear { viewModel.load() }
        .sheet(item: $pendingGateAction) { action in
            ParentalGateView(
                onSuccess: {
                    switch action {
                    case .buy(let row): viewModel.purchase(row)
                    case .restore:      viewModel.restorePurchases()
                    }
                    pendingGateAction = nil
                },
                onCancel: { pendingGateAction = nil }
            )
        }
        .alert(
            viewModel.alertIsSuccess ? "Success" : "Purchase",
            isPresented: Binding(
                get: { viewModel.alertMessage != nil },
                set: { isPresented in
                    if !isPresented { viewModel.dismissAlert() }
                }
            )
        ) {
            Button("OK") { viewModel.dismissAlert() }
        } message: {
            Text(viewModel.alertMessage ?? "")
        }
    }
}

// MARK: - Alphabet Store Row

/// A single tappable row showing one alphabet's names, price/ownership
/// state, and (when locked) a "Buy" button.
private struct AlphabetStoreRowView: View {

    let row: AlphabetStoreRow
    let isPurchasing: Bool
    let onBuy: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(row.alphabet.displayName)
                    .font(.headline)
                Text(row.alphabet.nativeName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if row.isOwned {
                Label("Owned", systemImage: "checkmark.circle.fill")
                    .labelStyle(.iconOnly)
                    .foregroundStyle(.green)
                    .font(.title3)
            } else if isPurchasing {
                ProgressView()
            } else {
                Button(row.priceText ?? "Buy", action: onBuy)
                    .buttonStyle(.borderedProminent)
                    .accessibilityHint("Buy this alphabet pack.")
                    .accessibilityIdentifier("store.buyButton.\(row.alphabet.id)")
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(row.alphabet.displayName), \(row.alphabet.nativeName)")
        .accessibilityValue(accessibilityStatus)
        .accessibilityIdentifier("store.row.\(row.alphabet.id)")
    }

    private var accessibilityStatus: String {
        if row.isOwned { return "Owned" }
        if isPurchasing { return "Purchase in progress" }
        return "\(row.priceText ?? "Price unavailable"), not purchased"
    }
}
