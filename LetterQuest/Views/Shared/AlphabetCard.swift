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
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)

                Text(alphabet.nativeName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)

                Label("Active", systemImage: "checkmark.circle.fill")
                    .labelStyle(.iconOnly)
                    .foregroundStyle(.green)
                    .font(.title3)
                    .opacity(isActive ? 1 : 0)
            }
            .frame(maxWidth: .infinity, minHeight: 110)
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
