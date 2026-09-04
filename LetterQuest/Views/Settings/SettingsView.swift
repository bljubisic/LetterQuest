import SwiftUI

/// The Settings screen: sound/haptics toggles, difficulty picker, and reset progress.
///
/// Generic over `VM: SettingsViewModelProtocol` so that the real
/// `SettingsViewModel` and a preview/test mock are interchangeable.
struct SettingsView<VM: SettingsViewModelProtocol>: View {

    @ObservedObject var viewModel: VM

    var body: some View {
        Form {
            Section("Feedback") {
                Toggle("Sound Effects", isOn: Binding(
                    get: { viewModel.isSoundEnabled },
                    set: { viewModel.setSoundEnabled($0) }
                ))
                Toggle("Haptic Feedback", isOn: Binding(
                    get: { viewModel.isHapticsEnabled },
                    set: { viewModel.setHapticsEnabled($0) }
                ))
            }

            Section {
                Picker(
                    "Difficulty",
                    selection: Binding(
                        get: { viewModel.difficulty },
                        set: { viewModel.setDifficulty($0) }
                    )
                ) {
                    ForEach(PassDifficulty.allCases) { difficulty in
                        Text(difficulty.displayName).tag(difficulty)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityHint("Changes how strict scoring is.")
            } header: {
                Text("Difficulty")
            } footer: {
                Text("Controls how strict scoring is — pass at \(viewModel.difficulty.passThreshold)%.")
            }

            Section {
                Button("Reset All Progress", role: .destructive) {
                    viewModel.requestResetProgress()
                }
                .accessibilityHint("Erases progress for every letter and word. This can't be undone.")
            }
        }
        .navigationTitle("Settings")
        .alert(
            "Reset All Progress?",
            isPresented: Binding(
                get: { viewModel.showResetConfirmation },
                set: { isPresented in
                    if !isPresented { viewModel.cancelResetProgress() }
                }
            )
        ) {
            Button("Cancel", role: .cancel) { viewModel.cancelResetProgress() }
            Button("Reset", role: .destructive) { viewModel.confirmResetProgress() }
        } message: {
            Text("This erases progress for every letter and word. This can't be undone.")
        }
    }
}
