import SwiftUI

/// The alphabet store: browse every known alphabet pack, buy locked ones,
/// and restore previous purchases.
///
/// Generic over `VM: AlphabetStoreViewModelProtocol` so that the same view
/// works with the real `AlphabetStoreViewModel` in production and with a
/// lightweight mock during Xcode previews or tests.
struct AlphabetStoreView<VM: AlphabetStoreViewModelProtocol>: View {

    @ObservedObject var viewModel: VM

    var body: some View {
        List {
            Section {
                ForEach(viewModel.rows) { row in
                    AlphabetStoreRowView(
                        row: row,
                        isPurchasing: viewModel.purchasingAlphabetId == row.alphabet.id,
                        onBuy: { viewModel.purchase(row) }
                    )
                }
            }

            Section {
                Button("Restore Purchases") {
                    viewModel.restorePurchases()
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

/// A single tappable row showing one alphabet's (or bundled pack's) names,
/// price/ownership state, and (when locked) a "Buy" button.
private struct AlphabetStoreRowView: View {

    let row: AlphabetStoreRow
    let isPurchasing: Bool
    let onBuy: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(row.displayName)
                    .font(.headline)
                if let nativeName = row.nativeName {
                    Text(nativeName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
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
                    .accessibilityIdentifier("store.buyButton.\(row.id)")
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(row.nativeName.map { "\(row.displayName), \($0)" } ?? row.displayName)
        .accessibilityValue(accessibilityStatus)
        .accessibilityIdentifier("store.row.\(row.id)")
    }

    private var accessibilityStatus: String {
        if row.isOwned { return "Owned" }
        if isPurchasing { return "Purchase in progress" }
        return "\(row.priceText ?? "Price unavailable"), not purchased"
    }
}
