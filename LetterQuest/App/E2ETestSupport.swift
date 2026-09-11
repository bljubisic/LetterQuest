import Foundation
import RxSwift

/// Seeds `ChildProgress` data and clears prior state for `LetterQuestUITests`,
/// driven entirely by launch environment variables — mirrors `ScreenshotDemo`'s
/// "seed inside the running process" approach so seeded records use the real,
/// in-process `Letter` UUIDs (which are freshly generated on every launch and
/// can't be predicted from outside the process).
///
/// Every entry point here is gated behind `LQ_E2E_TEST=1`, so this has zero
/// effect on a normal app launch or on `ScreenshotDemo`'s own screenshot runs.
enum E2ETestSupport {

    /// One letter's seeded state, decoded from `LQ_E2E_SEED_JSON`.
    struct LetterSeed: Codable {
        /// The letter's character as a single-character string (JSON has no
        /// `Character` type), e.g. `"A"`.
        let character: String
        let isUpper: Bool
        let completed: Bool
        let score: Int
    }

    static var isEnabled: Bool {
        ProcessInfo.processInfo.environment["LQ_E2E_TEST"] == "1"
    }

    /// When `true`, clears prior `ChildProgress`/`WordProgress`/onboarding
    /// state before seeding — so every test starts from a known slate
    /// regardless of what a previous test run left in the simulator.
    static var shouldReset: Bool {
        ProcessInfo.processInfo.environment["LQ_E2E_RESET"] == "1"
    }

    /// When `true`, the onboarding cover is marked complete before the UI
    /// renders, so tests that don't care about onboarding land straight on
    /// Home. Flows that specifically test onboarding (e.g. tapping "Skip")
    /// leave this unset.
    static var skipOnboarding: Bool {
        ProcessInfo.processInfo.environment["LQ_E2E_SKIP_ONBOARDING"] == "1"
    }

    /// When `true`, the next `PracticeView` reached during this launch
    /// auto-passes via `PracticeViewModel`'s `injectedResult` — see
    /// `passingResult`. Lets a test verify the pass/unlock/celebration flow
    /// without simulating a pixel-perfect PencilKit stroke.
    static var autoPass: Bool {
        ProcessInfo.processInfo.environment["LQ_E2E_AUTO_PASS"] == "1"
    }

    /// Decoded from `LQ_E2E_SEED_JSON`, a compact array of per-letter states.
    /// Empty when the variable is absent or fails to decode.
    static var seeds: [LetterSeed] {
        guard let json = ProcessInfo.processInfo.environment["LQ_E2E_SEED_JSON"],
              let data = json.data(using: .utf8),
              let decoded = try? JSONDecoder().decode([LetterSeed].self, from: data) else {
            return []
        }
        return decoded
    }

    /// A high, honest-looking passing result fed through the real
    /// `handle(result:)` pipeline when `autoPass` is set. See
    /// `PracticeViewModel.init(injectedResult:)`.
    static let passingResult = AssessmentResult(
        overallScore:     92,
        strokeOrderScore: 94,
        shapeScore:       90,
        proportionScore:  93,
        smoothnessScore:  88,
        feedback:         [FeedbackItem(type: .encouragement, message: "Amazing work! Keep it up!")],
        passed:           true
    )

    /// Resets prior state (when `shouldReset`) and applies `seeds` using the
    /// live `Letter` catalogue. Safe to call unconditionally — a no-op unless
    /// `isEnabled`.
    @MainActor
    static func run(
        letterRepository: LetterRepositoryProtocol,
        progressRepository: ProgressRepositoryProtocol,
        wordProgressRepository: WordProgressRepositoryProtocol,
        onboardingViewModel: OnboardingViewModel
    ) async {
        guard isEnabled else { return }

        if shouldReset {
            await awaitCompletable(progressRepository.resetAll())
            await awaitCompletable(wordProgressRepository.resetAll())
            onboardingViewModel.resetOnboarding()
        }

        if skipOnboarding {
            onboardingViewModel.complete()
        }

        let pendingSeeds = seeds
        guard !pendingSeeds.isEmpty else { return }

        let letters = await awaitSingle(letterRepository.fetchAll()) ?? []

        for seed in pendingSeeds {
            guard let character = seed.character.first else { continue }
            let targetCase: LetterCase = seed.isUpper ? .upper : .lower
            guard let letter = letters.first(where: { $0.character == character && $0.letterCase == targetCase }) else {
                continue
            }

            let progress = ChildProgress(
                letterId:    letter.id,
                attempts:    [ChildProgress.Attempt(timestamp: Date(), score: seed.score)],
                bestScore:   seed.score,
                isUnlocked:  true,
                isCompleted: seed.completed
            )
            await awaitCompletable(progressRepository.save(progress))
        }
    }
}
