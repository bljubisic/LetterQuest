import Foundation

/// The accumulated practice history for a single letter.
///
/// All properties are read-only. To produce an updated copy after an assessment,
/// use `recording(_:)` which composes the required lens operations:
/// ```swift
/// let updated = progress.recording(assessmentResult)
/// ```
///
/// For lower-level mutations, use the static lenses directly:
/// ```swift
/// let unlocked = ChildProgress.lensIsUnlocked.set(progress, true)
/// ```
struct ChildProgress: ChildProgressProtocol, Codable, Equatable {

    let letterId: UUID
    let attempts: [Attempt]
    let bestScore: Int
    let isUnlocked: Bool
    let isCompleted: Bool

    /// A single scored attempt recorded at a point in time.
    struct Attempt: Codable, Equatable {
        let timestamp: Date
        let score: Int
    }
}

// MARK: - Immutable update

extension ChildProgress {

    /// Returns a new `ChildProgress` that records the result of one assessment.
    ///
    /// Applies three lens operations in sequence:
    /// 1. Appends the new attempt.
    /// 2. Updates `bestScore` if the new score is higher.
    /// 3. Sets `isCompleted` if the attempt passed.
    ///
    /// - Parameter result: The assessment outcome to record.
    /// - Returns: A new, updated `ChildProgress` value.
    func recording(_ result: AssessmentResult) -> ChildProgress {
        let newAttempt = Attempt(timestamp: Date(), score: result.overallScore)

        return ChildProgress.lensAttempts.over(self) { $0 + [newAttempt] }
            |> ChildProgress.lensBestScore.over(_:)   { max($0, result.overallScore) }
            |> ChildProgress.lensIsCompleted.over(_:) { $0 || result.passed }
    }
}

// MARK: - Lenses

extension ChildProgress {

    /// Focuses on the list of recorded attempts.
    static let lensAttempts = Lens<ChildProgress, [Attempt]>(
        get: { $0.attempts },
        set: { whole, value in
            ChildProgress(
                letterId:    whole.letterId,
                attempts:    value,
                bestScore:   whole.bestScore,
                isUnlocked:  whole.isUnlocked,
                isCompleted: whole.isCompleted
            )
        }
    )

    /// Focuses on the highest score ever achieved.
    static let lensBestScore = Lens<ChildProgress, Int>(
        get: { $0.bestScore },
        set: { whole, value in
            ChildProgress(
                letterId:    whole.letterId,
                attempts:    whole.attempts,
                bestScore:   value,
                isUnlocked:  whole.isUnlocked,
                isCompleted: whole.isCompleted
            )
        }
    )

    /// Focuses on the unlock flag. Set to `true` to allow a child to practice the letter.
    static let lensIsUnlocked = Lens<ChildProgress, Bool>(
        get: { $0.isUnlocked },
        set: { whole, value in
            ChildProgress(
                letterId:    whole.letterId,
                attempts:    whole.attempts,
                bestScore:   whole.bestScore,
                isUnlocked:  value,
                isCompleted: whole.isCompleted
            )
        }
    )

    /// Focuses on the completion flag. Set to `true` once the child has passed.
    static let lensIsCompleted = Lens<ChildProgress, Bool>(
        get: { $0.isCompleted },
        set: { whole, value in
            ChildProgress(
                letterId:    whole.letterId,
                attempts:    whole.attempts,
                bestScore:   whole.bestScore,
                isUnlocked:  whole.isUnlocked,
                isCompleted: value
            )
        }
    )
}

// MARK: - Pipe operator

/// Left-to-right function application, used to compose lens operations readably.
///
/// `value |> f` is equivalent to `f(value)`.
infix operator |>: ForwardApplication

precedencegroup ForwardApplication {
    associativity: left
    higherThan: AssignmentPrecedence
}

func |> <A, B>(value: A, transform: (A) -> B) -> B {
    transform(value)
}
