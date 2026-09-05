import Testing
import Foundation
import RxSwift
@testable import LetterQuest

// MARK: - Mocks

private final class MockSoundService: SoundServiceProtocol {
    var isSoundEnabled = true
    func playSuccess() {}
    func playEncouragement() {}
    func playSoftError() {}
}

private final class MockHapticsService: HapticsServiceProtocol {
    var isEnabled = true
    func playSuccess() {}
    func playEncouragement() {}
    func playSoftError() {}
}

private final class MockSettingsRepository: SettingsRepositoryProtocol {
    private(set) var saved: [AppSettings] = []
    var stored: AppSettings
    init(stored: AppSettings = .default) { self.stored = stored }
    func load() -> Single<AppSettings> { .just(stored) }
    func save(_ settings: AppSettings) -> Completable {
        saved.append(settings)
        stored = settings
        return .empty()
    }
}

private final class MockProgressRepository: ProgressRepositoryProtocol {
    private(set) var resetAllCallCount = 0
    func loadAll() -> Single<[ChildProgress]> { .just([]) }
    func save(_ progress: ChildProgress) -> Completable { .empty() }
    func resetAll() -> Completable {
        resetAllCallCount += 1
        return .empty()
    }
}

private final class MockWordProgressRepository: WordProgressRepositoryProtocol {
    private(set) var resetAllCallCount = 0
    func loadAll() -> Single<[WordProgress]> { .just([]) }
    func save(_ progress: WordProgress) -> Completable { .empty() }
    func resetAll() -> Completable {
        resetAllCallCount += 1
        return .empty()
    }
}

// MARK: - Helpers

private struct Fixture {
    let vm: SettingsViewModel
    let soundService: MockSoundService
    let hapticsService: MockHapticsService
    let settingsRepository: MockSettingsRepository
    let progressRepository: MockProgressRepository
    let wordProgressRepository: MockWordProgressRepository
}

private func makeFixture(
    stored: AppSettings = .default,
    soundEnabled: Bool = true,
    hapticsEnabled: Bool = true
) -> Fixture {
    let soundService           = MockSoundService()
    soundService.isSoundEnabled = soundEnabled
    let hapticsService         = MockHapticsService()
    hapticsService.isEnabled    = hapticsEnabled
    let settingsRepository     = MockSettingsRepository(stored: stored)
    let progressRepository     = MockProgressRepository()
    let wordProgressRepository = MockWordProgressRepository()
    let vm = SettingsViewModel(
        soundService:           soundService,
        hapticsService:         hapticsService,
        settingsRepository:     settingsRepository,
        progressRepository:     progressRepository,
        wordProgressRepository: wordProgressRepository
    )
    return Fixture(
        vm: vm,
        soundService: soundService,
        hapticsService: hapticsService,
        settingsRepository: settingsRepository,
        progressRepository: progressRepository,
        wordProgressRepository: wordProgressRepository
    )
}

// MARK: - Tests

struct SettingsViewModelTests {

    @Test("isSoundEnabled and isHapticsEnabled reflect the injected services on init")
    func initialTogglesReflectServices() {
        let fixture = makeFixture(soundEnabled: false, hapticsEnabled: false)
        #expect(fixture.vm.isSoundEnabled == false)
        #expect(fixture.vm.isHapticsEnabled == false)
    }

    @Test("difficulty loads asynchronously from the settings repository")
    func difficultyLoadsFromRepository() {
        let fixture = makeFixture(stored: AppSettings(difficulty: .challenge))
        DispatchQueue.main.sync {}
        #expect(fixture.vm.difficulty == .challenge)
    }

    @Test("setSoundEnabled writes through to the sound service and updates published state")
    func setSoundEnabledWritesThrough() {
        let fixture = makeFixture()
        fixture.vm.setSoundEnabled(false)
        #expect(fixture.vm.isSoundEnabled == false)
        #expect(fixture.soundService.isSoundEnabled == false)
    }

    @Test("setHapticsEnabled writes through to the haptics service and updates published state")
    func setHapticsEnabledWritesThrough() {
        let fixture = makeFixture()
        fixture.vm.setHapticsEnabled(false)
        #expect(fixture.vm.isHapticsEnabled == false)
        #expect(fixture.hapticsService.isEnabled == false)
    }

    @Test("setDifficulty updates published state and persists via the settings repository")
    func setDifficultyPersists() {
        let fixture = makeFixture()
        // Let the init-time async load settle first — otherwise its
        // main-thread completion can race with `setDifficulty` below and
        // overwrite `.easy` back to the loaded default under heavy parallel
        // test load (flaky only under full-suite runs, not in isolation).
        DispatchQueue.main.sync {}
        fixture.vm.setDifficulty(.easy)
        #expect(fixture.vm.difficulty == .easy)
        #expect(fixture.settingsRepository.saved.last?.difficulty == .easy)
    }

    @Test("requestResetProgress shows the confirmation alert")
    func requestResetShowsConfirmation() {
        let fixture = makeFixture()
        fixture.vm.requestResetProgress()
        #expect(fixture.vm.showResetConfirmation == true)
    }

    @Test("cancelResetProgress dismisses the alert without touching progress")
    func cancelResetDoesNotClearProgress() {
        let fixture = makeFixture()
        fixture.vm.requestResetProgress()
        fixture.vm.cancelResetProgress()
        #expect(fixture.vm.showResetConfirmation == false)
        #expect(fixture.progressRepository.resetAllCallCount == 0)
        #expect(fixture.wordProgressRepository.resetAllCallCount == 0)
    }

    @Test("confirmResetProgress clears both progress repositories and dismisses the alert")
    func confirmResetClearsProgress() {
        let fixture = makeFixture()
        fixture.vm.requestResetProgress()
        fixture.vm.confirmResetProgress()
        DispatchQueue.main.sync {}
        #expect(fixture.vm.showResetConfirmation == false)
        #expect(fixture.progressRepository.resetAllCallCount == 1)
        #expect(fixture.wordProgressRepository.resetAllCallCount == 1)
    }
}
