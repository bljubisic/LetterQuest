import Foundation

/// A randomly generated multiplication problem used to gate commerce (and
/// any future outbound links) behind an action a young child can't easily
/// perform, per App Store Review Guideline 1.3 (Kids Category).
///
/// Deliberately a pure, dependency-free value type: trivial to unit test,
/// and regenerated fresh every time a gate is presented so the same problem
/// can't be memorized or guessed around.
struct ParentalGateChallenge: Equatable {

    let firstFactor: Int
    let secondFactor: Int

    var answer: Int { firstFactor * secondFactor }

    var prompt: String { "\(firstFactor) × \(secondFactor) = ?" }

    /// Whether `input` matches `answer`, ignoring surrounding whitespace.
    /// Non-numeric input is always incorrect rather than throwing.
    func isCorrect(_ input: String) -> Bool {
        guard let value = Int(input.trimmingCharacters(in: .whitespacesAndNewlines)) else { return false }
        return value == answer
    }

    /// Factors are drawn from 6...9 so every product is two digits —
    /// straightforward for an adult, deliberately not for a preschooler.
    static func random() -> ParentalGateChallenge {
        ParentalGateChallenge(firstFactor: .random(in: 6...9), secondFactor: .random(in: 6...9))
    }
}
