import Foundation
import RxSwift

/// Seeds realistic demo data and jumps straight to a specific screen, driven
/// entirely by launch environment variables — used to produce deterministic,
/// reproducible App Store screenshots without needing to draw real letters
/// by hand for every capture.
///
/// Every entry point here is gated behind `LQ_SCREENSHOT_DEMO=1`, so this has
/// zero effect on a normal app launch. Nothing here is reachable unless a
/// caller explicitly sets that environment variable (e.g. via
/// `xcrun simctl launch <device> <bundle-id> -e LQ_SCREENSHOT_DEMO=1 ...`).
enum ScreenshotDemo {

    /// Which set of `ChildProgress`/`WordProgress` records to seed.
    enum Profile: String {
        /// A handful of uppercase letters completed, one in progress, the
        /// rest untouched — for screens that show a "partway through" state
        /// (home grid, progress screen, a single practice session).
        case partial
        /// Every letter completed and a couple of words finished — for
        /// screens that only make sense once word mode is unlocked.
        case complete
    }

    /// Which screen to land on once seeding completes.
    enum Route: String {
        case home
        case practice
        case score
        case celebration
        case progress
        case words
    }

    static var isEnabled: Bool {
        ProcessInfo.processInfo.environment["LQ_SCREENSHOT_DEMO"] == "1"
    }

    static var profile: Profile {
        Profile(rawValue: ProcessInfo.processInfo.environment["LQ_SCREENSHOT_PROFILE"] ?? "") ?? .partial
    }

    static var route: Route {
        Route(rawValue: ProcessInfo.processInfo.environment["LQ_SCREENSHOT_ROUTE"] ?? "") ?? .home
    }

    /// A canned high (but honest-looking) score, used only for the `.score`
    /// route so the score panel has something to show without a real
    /// submission. See `PracticeViewModel.init(demoResult:)`.
    static let previewAssessmentResult = AssessmentResult(
        overallScore:     94,
        strokeOrderScore: 96,
        shapeScore:       92,
        proportionScore:  95,
        smoothnessScore:  90,
        feedback:         [FeedbackItem(type: .encouragement, message: "Amazing work! Keep it up!")],
        passed:           true
    )

    /// Seeds progress data for `profile` and pushes `route` onto `router`.
    /// Safe to call unconditionally — it's a no-op unless `isEnabled`.
    @MainActor
    static func run(
        letterRepository: LetterRepositoryProtocol,
        wordRepository: WordRepositoryProtocol,
        progressRepository: ProgressRepositoryProtocol,
        wordProgressRepository: WordProgressRepositoryProtocol,
        router: AppRouter
    ) async {
        guard isEnabled else { return }

        let letters = await awaitSingle(letterRepository.fetchAll()) ?? []
        let uppercase = letters.filter { $0.letterCase == .upper }
        let lowercase = letters.filter { $0.letterCase == .lower }

        switch profile {
        case .partial:
            let scores = [92, 88, 95, 79, 90, 85, 98, 91, 87, 93]
            for (letter, score) in zip(uppercase.prefix(10), scores) {
                await save(completedFor: letter, score: score, into: progressRepository)
            }
            if let inProgress = uppercase.dropFirst(10).first {
                await save(inProgressFor: inProgress, score: 45, into: progressRepository)
            }

        case .complete:
            for letter in uppercase {
                await save(completedFor: letter, score: Int.random(in: 85...98), into: progressRepository)
            }
            for letter in lowercase {
                await save(completedFor: letter, score: Int.random(in: 85...98), into: progressRepository)
            }
            let words = await awaitSingle(wordRepository.fetchAll()) ?? []
            for word in words.prefix(2) {
                await awaitCompletable(wordProgressRepository.save(WordProgress(wordId: word.id, isCompleted: true)))
            }
        }

        switch route {
        case .home:
            break

        case .practice:
            if let target = uppercase.dropFirst(10).first {
                router.push(.practice(letterId: target.id))
            }

        case .score:
            if let target = uppercase.first {
                router.push(.practice(letterId: target.id))
            }

        case .celebration:
            // Pushes the same `.practice` route as `.score` — `destination(for:)`
            // in `LetterQuestApp` checks `ScreenshotDemo.route` itself and adds
            // `demoShowCelebration: true`, so the celebration overlay appears
            // layered over a real practice scene instead of an empty background.
            if let target = uppercase.first {
                router.push(.practice(letterId: target.id))
            }

        case .progress:
            router.push(.progress)

        case .words:
            router.push(.words)
        }
    }

    // MARK: - Seeding helpers

    private static func save(
        completedFor letter: Letter,
        score: Int,
        into repository: ProgressRepositoryProtocol
    ) async {
        let progress = ChildProgress(
            letterId:    letter.id,
            attempts:    [ChildProgress.Attempt(timestamp: Date(), score: score)],
            bestScore:   score,
            isUnlocked:  true,
            isCompleted: true
        )
        await awaitCompletable(repository.save(progress))
    }

    private static func save(
        inProgressFor letter: Letter,
        score: Int,
        into repository: ProgressRepositoryProtocol
    ) async {
        let progress = ChildProgress(
            letterId:    letter.id,
            attempts:    [ChildProgress.Attempt(timestamp: Date(), score: score)],
            bestScore:   score,
            isUnlocked:  true,
            isCompleted: false
        )
        await awaitCompletable(repository.save(progress))
    }
}

// MARK: - Async bridging
//
// Small, self-contained Single/Completable → async bridges so this file
// doesn't depend on a specific RxSwift version's own concurrency bridging.

private func awaitSingle<T>(_ single: Single<T>) async -> T? {
    await withCheckedContinuation { continuation in
        var didResume = false
        _ = single.subscribe(
            onSuccess: { value in
                guard !didResume else { return }
                didResume = true
                continuation.resume(returning: value)
            },
            onFailure: { _ in
                guard !didResume else { return }
                didResume = true
                continuation.resume(returning: nil)
            }
        )
    }
}

private func awaitCompletable(_ completable: Completable) async {
    await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
        var didResume = false
        _ = completable.subscribe(
            onCompleted: {
                guard !didResume else { return }
                didResume = true
                continuation.resume()
            },
            onError: { _ in
                guard !didResume else { return }
                didResume = true
                continuation.resume()
            }
        )
    }
}
