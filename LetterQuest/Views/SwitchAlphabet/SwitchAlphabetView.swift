import SwiftUI

/// Lets the child pick which installed alphabet becomes active on Home, and
/// surfaces a link to the Alphabet Store for alphabets they don't own yet.
///
/// Generic over `VM: SwitchAlphabetViewModelProtocol` so that the same view
/// works with the real `SwitchAlphabetViewModel` in production and with a
/// lightweight mock during Xcode previews or tests.
struct SwitchAlphabetView<VM: SwitchAlphabetViewModelProtocol>: View {

    @ObservedObject var viewModel: VM

    private let columns = [GridItem(.adaptive(minimum: 130), spacing: 16)]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(viewModel.installedAlphabets) { alphabet in
                    AlphabetCard(
                        alphabet: alphabet,
                        isActive: alphabet.id == viewModel.activeAlphabetId,
                        onTap:    { viewModel.selectAlphabet(alphabet.id) }
                    )
                }

                Button(action: viewModel.navigateToStore) {
                    VStack(spacing: 10) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title)
                        Text("Get more alphabets")
                            .font(.subheadline.bold())
                    }
                    .foregroundStyle(Color.accentColor)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(color: .black.opacity(0.08), radius: 6, y: 3)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Get more alphabets")
                .accessibilityHint("Opens the Alphabet Store.")
                .accessibilityIdentifier("switchAlphabet.storeCard")
            }
            .padding()
        }
        .navigationTitle("Switch Alphabet")
        .overlay {
            if viewModel.isLoading {
                ProgressView().scaleEffect(1.5)
            }
        }
        .onAppear { viewModel.load() }
    }
}
