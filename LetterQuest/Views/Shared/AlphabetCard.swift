import SwiftUI

/// A single tappable tile representing an installed alphabet.
///
/// Shared by `SwitchAlphabetView` (the only place this app lets you pick an
/// alphabet, since Home always shows one specific alphabet's letters).
struct AlphabetCard: View {

    let alphabet: Alphabet
    let isActive: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 10) {
                Text(alphabet.displayName)
                    .font(.title2.bold())
                    .foregroundStyle(Color.accentColor)

                Text(alphabet.nativeName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if isActive {
                    Label("Active", systemImage: "checkmark.circle.fill")
                        .labelStyle(.iconOnly)
                        .foregroundStyle(.green)
                        .font(.title3)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.08), radius: 6, y: 3)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(alphabet.displayName)
        .accessibilityValue(isActive ? "Active" : "")
        .accessibilityIdentifier("switchAlphabet.card.\(alphabet.id)")
    }
}
