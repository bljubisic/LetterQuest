import Testing
import Foundation
import RxSwift
import RxBlocking
@testable import LetterQuest

// MARK: - Helpers

private func makeProgress(
    letterId: UUID    = UUID(),
    bestScore: Int    = 0,
    attempts: [ChildProgress.Attempt] = [],
    isUnlocked: Bool  = true,
    isCompleted: Bool = false
) -> ChildProgress {
    ChildProgress(
        letterId:    letterId,
        attempts:    attempts,
        bestScore:   bestScore,
        isUnlocked:  isUnlocked,
        isCompleted: isCompleted
    )
}

private func makeResult(score: Int) -> AssessmentResult {
    AssessmentResult(
        overallScore:     score,
        strokeOrderScore: score,
        shapeScore:       score,
        proportionScore:  score,
        smoothnessScore:  score,
        feedback:         [],
        passed:           score >= 75
    )
}

// MARK: - recording(_:) immutability

struct ChildProgressImmutabilityTests {

    @Test("recording does not mutate the original progress")
    func recordingIsImmutable() {
        let original = makeProgress(bestScore: 50)
        _ = original.recording(makeResult(score: 90))
        #expect(original.bestScore == 50)
        #expect(original.attempts.isEmpty)
        #expect(original.isCompleted == false)
    }

    @Test("recording returns a structurally distinct value")
    func recordingReturnsNewValue() {
        let original = makeProgress()
        let updated  = original.recording(makeResult(score: 80))
        #expect(updated != original)
    }
}

// MARK: - recording(_:) attempts

struct ChildProgressAttemptsTests {

    @Test("recording appends exactly one attempt")
    func recordingAppendsOneAttempt() {
        let progress = makeProgress()
        let updated  = progress.recording(makeResult(score: 70))
        #expect(updated.attempts.count == 1)
    }

    @Test("recorded attempt stores the correct score")
    func recordedAttemptHasCorrectScore() {
        let updated = makeProgress().recording(makeResult(score: 83))
        #expect(updated.attempts[0].score == 83)
    }

    @Test("recorded attempt has a timestamp close to now")
    func recordedAttemptHasRecentTimestamp() {
        let before  = Date()
        let updated = makeProgress().recording(makeResult(score: 60))
        let after   = Date()
        #expect(updated.attempts[0].timestamp >= before)
        #expect(updated.attempts[0].timestamp <= after)
    }

    @Test("multiple recordings accumulate all attempts in order")
    func multipleRecordingsAccumulateAttempts() {
        var progress = makeProgress()
        let scores = [55, 70, 82]
        for score in scores {
            progress = progress.recording(makeResult(score: score))
        }
        #expect(progress.attempts.count == 3)
        #expect(progress.attempts.map(\.score) == scores)
    }
}

// MARK: - recording(_:) bestScore

struct ChildProgressBestScoreTests {

    @Test("bestScore is updated when the new score is higher")
    func bestScoreUpdatesWhenHigher() {
        let progress = makeProgress(bestScore: 60)
        let updated  = progress.recording(makeResult(score: 90))
        #expect(updated.bestScore == 90)
    }

    @Test("bestScore is not lowered when the new score is lower")
    func bestScoreNotLoweredWhenLower() {
        let progress = makeProgress(bestScore: 80)
        let updated  = progress.recording(makeResult(score: 50))
        #expect(updated.bestScore == 80)
    }

    @Test("bestScore is unchanged when the new score equals the current best")
    func bestScoreUnchangedOnTie() {
        let progress = makeProgress(bestScore: 75)
        let updated  = progress.recording(makeResult(score: 75))
        #expect(updated.bestScore == 75)
    }

    @Test("bestScore reflects the highest score across multiple recordings")
    func bestScoreReflectsAllTimeHigh() {
        var progress = makeProgress()
        for score in [40, 85, 60, 90, 70] {
            progress = progress.recording(makeResult(score: score))
        }
        #expect(progress.bestScore == 90)
    }
}

// MARK: - recording(_:) isCompleted

struct ChildProgressCompletionTests {

    @Test("a passing result (score ≥ 75) sets isCompleted to true")
    func passingSetsCompleted() {
        let progress = makeProgress(isCompleted: false)
        #expect(progress.recording(makeResult(score: 75)).isCompleted == true)
        #expect(progress.recording(makeResult(score: 100)).isCompleted == true)
    }

    @Test("a failing result (score < 75) leaves isCompleted false")
    func failingLeavesNotCompleted() {
        let progress = makeProgress(isCompleted: false)
        #expect(progress.recording(makeResult(score: 74)).isCompleted == false)
        #expect(progress.recording(makeResult(score: 0)).isCompleted == false)
    }

    @Test("once completed, a failing result does not revert isCompleted")
    func completionIsSticky() {
        let completed = makeProgress(isCompleted: true)
        let updated   = completed.recording(makeResult(score: 30))
        #expect(updated.isCompleted == true)
    }
}

// MARK: - Lenses

struct ChildProgressLensTests {

    @Test("lensAttempts.get extracts the attempts array")
    func lensAttemptsGet() {
        let attempt  = ChildProgress.Attempt(timestamp: Date(), score: 77)
        let progress = makeProgress(attempts: [attempt])
        #expect(ChildProgress.lensAttempts.get(progress).count == 1)
    }

    @Test("lensAttempts.set returns a new progress with replaced attempts")
    func lensAttemptsSet() {
        let original = makeProgress()
        let newAttempts = [ChildProgress.Attempt(timestamp: Date(), score: 88)]
        let updated  = ChildProgress.lensAttempts.set(original, newAttempts)
        #expect(updated.attempts.count == 1)
        #expect(original.attempts.isEmpty)
    }

    @Test("lensBestScore.set updates only bestScore, leaving other fields intact")
    func lensBestScorePreservesOtherFields() {
        let original = makeProgress(bestScore: 10, isCompleted: false)
        let updated  = ChildProgress.lensBestScore.set(original, 95)
        #expect(updated.bestScore == 95)
        #expect(updated.isCompleted == original.isCompleted)
        #expect(updated.letterId == original.letterId)
    }

    @Test("lensIsCompleted.set updates only isCompleted")
    func lensIsCompletedPreservesOtherFields() {
        let original = makeProgress(bestScore: 42, isCompleted: false)
        let updated  = ChildProgress.lensIsCompleted.set(original, true)
        #expect(updated.isCompleted == true)
        #expect(updated.bestScore == 42)
    }

    @Test("lensIsUnlocked.over toggles the unlock flag")
    func lensIsUnlockedOver() {
        let locked   = makeProgress(isUnlocked: false)
        let unlocked = ChildProgress.lensIsUnlocked.over(locked) { !$0 }
        #expect(unlocked.isUnlocked == true)
        #expect(locked.isUnlocked == false)
    }
}

// MARK: - ProgressRepository (UserDefaults-backed)

struct ProgressRepositoryTests {

    private let suiteName = "com.letterquest.tests.\(UUID().uuidString)"

    private var repository: ProgressRepository {
        ProgressRepository(userDefaults: UserDefaults(suiteName: suiteName)!)
    }

    @Test("loadAll returns an empty array when no progress has been saved")
    func loadAllInitiallyEmpty() throws {
        let repo = repository
        let all = try repo.loadAll().toBlocking().single()
        #expect(all.isEmpty)
    }

    @Test("save then loadAll round-trips a ChildProgress record correctly")
    func saveAndLoadRoundTrips() throws {
        let repo     = repository
        let progress = makeProgress(letterId: UUID(), bestScore: 82, isCompleted: true)
        try repo.save(progress).toBlocking().first()
        let all = try repo.loadAll().toBlocking().single()
        #expect(all.count == 1)
        #expect(all[0].letterId == progress.letterId)
        #expect(all[0].bestScore == 82)
        #expect(all[0].isCompleted == true)
    }

    @Test("saving a progress record for the same letter replaces the previous record")
    func savingReplacesSameLetter() throws {
        let repo     = repository
        let letterId = UUID()
        let first    = makeProgress(letterId: letterId, bestScore: 50)
        let second   = makeProgress(letterId: letterId, bestScore: 90)
        try repo.save(first).toBlocking().first()
        try repo.save(second).toBlocking().first()
        let all = try repo.loadAll().toBlocking().single()
        #expect(all.count == 1)
        #expect(all[0].bestScore == 90)
    }

    @Test("saving progress records for different letters keeps all of them")
    func savingDifferentLettersKeepsAll() throws {
        let repo = repository
        let a    = makeProgress(letterId: UUID(), bestScore: 60)
        let b    = makeProgress(letterId: UUID(), bestScore: 70)
        try repo.save(a).toBlocking().first()
        try repo.save(b).toBlocking().first()
        let all = try repo.loadAll().toBlocking().single()
        #expect(all.count == 2)
    }

    @Test("resetAll erases every stored record")
    func resetAllErasesEveryRecord() throws {
        let repo = repository
        try repo.save(makeProgress(letterId: UUID(), bestScore: 60)).toBlocking().first()
        try repo.save(makeProgress(letterId: UUID(), bestScore: 70)).toBlocking().first()
        try repo.resetAll().toBlocking().first()
        let all = try repo.loadAll().toBlocking().single()
        #expect(all.isEmpty)
    }
}
