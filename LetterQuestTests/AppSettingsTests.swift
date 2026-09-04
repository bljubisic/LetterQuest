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
    func loadReturnsDefaultInitially() throws {
        let settings = try repository.load().toBlocking().single()
        #expect(settings == .default)
    }

    @Test("save then load round-trips the settings correctly")
    func saveAndLoadRoundTrips() throws {
        let repo = repository
        try repo.save(AppSettings(difficulty: .challenge)).toBlocking().first()
        let loaded = try repo.load().toBlocking().single()
        #expect(loaded.difficulty == .challenge)
    }

    @Test("saving again replaces the previous settings")
    func savingReplacesPreviousSettings() throws {
        let repo = repository
        try repo.save(AppSettings(difficulty: .easy)).toBlocking().first()
        try repo.save(AppSettings(difficulty: .challenge)).toBlocking().first()
        let loaded = try repo.load().toBlocking().single()
        #expect(loaded.difficulty == .challenge)
    }
}
