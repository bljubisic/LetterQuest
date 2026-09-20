import SwiftUI

/// A blocking "Parents Only" challenge shown before commerce (and any future
/// outbound links), per App Store Review Guideline 1.3 (Kids Category).
///
/// Presented as a sheet. `onCancel` always leaves the caller's state
/// untouched; `onSuccess` fires only once the typed answer matches the
/// current `ParentalGateChallenge`. A wrong answer never dismisses the
/// gate — it shows an error and swaps in a fresh challenge, so there's no
/// way to bypass it short of solving one.
struct ParentalGateView: View {

    let onSuccess: () -> Void
    let onCancel: () -> Void

    @State private var challenge = ParentalGateChallenge.random()
    @State private var answerText = ""
    @State private var showsError = false

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 48))
                .foregroundStyle(Color.accentColor)

            Text("Parents Only")
                .font(.title2.bold())

            Text("Solve this to continue:")
                .foregroundStyle(.secondary)

            Text(challenge.prompt)
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .accessibilityIdentifier("parentalGate.prompt")

            TextField("Answer", text: $answerText)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .font(.title2)
                .textFieldStyle(.roundedBorder)
                .frame(width: 120)
                .accessibilityIdentifier("parentalGate.answerField")
                .accessibilityLabel("Answer")
                .accessibilityHint("Enter the answer to the multiplication problem above.")

            if showsError {
                Text("That's not quite right. Try this one instead.")
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .accessibilityIdentifier("parentalGate.errorMessage")
            }

            HStack(spacing: 16) {
                Button("Cancel", role: .cancel, action: onCancel)
                    .buttonStyle(.bordered)
                    .accessibilityIdentifier("parentalGate.cancelButton")

                Button("Continue", action: submit)
                    .buttonStyle(.borderedProminent)
                    .disabled(answerText.trimmingCharacters(in: .whitespaces).isEmpty)
                    .accessibilityIdentifier("parentalGate.continueButton")
            }
            .padding(.top, 8)
        }
        .padding(32)
    }

    private func submit() {
        if challenge.isCorrect(answerText) {
            onSuccess()
        } else {
            showsError = true
            answerText = ""
            challenge = .random()
        }
    }
}
