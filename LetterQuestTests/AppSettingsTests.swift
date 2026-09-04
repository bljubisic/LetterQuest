import Testing
import Foundation
import RxSwift
import RxBlocking
@testable import LetterQuest

// MARK: - PassDifficulty

struct PassDifficultyTests {

    @Test("passThreshold maps each case to the documented score")
    func passThresholdMapsCorrectly() {
        #expect(PassDifficulty.easy.passThreshold == 60)
        #expect(PassDifficulty.standard.passThreshold == 75)
        #expect(PassDifficulty.challenge.passThreshold == 85)
    }
}

// MARK: - AppSettings lens

struct AppSettingsLensTests {

    @Test("lensDifficulty.set replaces difficulty")
    func lensDifficultySetsField() {
        let settings = AppSettings(difficulty: .easy)
        let updated  = AppSettings.lensDifficulty.set(settings, .challenge)
        #expect(updated.difficulty == .challenge)
    }

    @Test("default settings use standard difficulty")
    func defaultIsStandard() {
        #expect(AppSettings.default.difficulty == .standard)
    }
}

// MARK: - SettingsRepository (UserDefaults-backed)

struct SettingsRepositoryTests {

    private let suiteName = "com.letterquest.tests.\(UUID().uuidString)"

    private var repository: SettingsRepository {
        SettingsRepository(userDefaults: UserDefaults(suiteName: suiteName)!)
    }

    @Test("load returns .default when nothing has been saved")
    func loadReturnsDefaultInitially() {
        #expect(loadSync(repository) == .default)
    }

    @Test("save then load round-trips the settings correctly")
    func saveAndLoadRoundTrips() {
        let repo = repository
        saveSync(repo, AppSettings(difficulty: .challenge))
        #expect(loadSync(repo).difficulty == .challenge)
    }

    @Test("saving again replaces the previous settings")
    func savingReplacesPreviousSettings() {
        let repo = repository
        saveSync(repo, AppSettings(difficulty: .easy))
        saveSync(repo, AppSettings(difficulty: .challenge))
        #expect(loadSync(repo).difficulty == .challenge)
    }
}

// MARK: - Synchronous helpers
//
// `SettingsRepository.load()`/`save()` complete synchronously (plain
// `UserDefaults` access), so a manual subscribe-and-capture is enough —
// avoids RxBlocking here after it was observed hanging the test host
// specifically for this repository.

private func loadSync(_ repository: SettingsRepository) -> AppSettings {
    var result = AppSettings.default
    repository.load().subscribe(onSuccess: { result = $0 }, onFailure: { _ in }).dispose()
    return result
}

private func saveSync(_ repository: SettingsRepository, _ settings: AppSettings) {
    repository.save(settings).subscribe().dispose()
}
