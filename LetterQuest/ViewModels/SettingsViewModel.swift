import Foundation
import RxSwift

/// Drives `SettingsView`.
///
/// Sound and haptics toggles read/write straight through to the already-shared
/// `SoundServiceProtocol`/`HapticsServiceProtocol` instances (each owns its own
/// persisted flag) and are mirrored into `@Published` properties for SwiftUI —
/// neither service exposes its flag reactively. Difficulty is the one setting
/// that doesn't already have a home, so it round-trips through `AppSettings`
/// via `SettingsRepositoryProtocol`.
final class SettingsViewModel: SettingsViewModelProtocol {

    // MARK: - SettingsViewModelProtocol outputs

    @Published private(set) var isSoundEnabled: Bool
    @Published private(set) var isHapticsEnabled: Bool
    @Published private(set) var difficulty: PassDifficulty = .standard
    @Published private(set) var showResetConfirmation = false

    // MARK: - Private

    private let soundService: SoundServiceProtocol
    private let hapticsService: HapticsServiceProtocol
    private let settingsRepository: SettingsRepositoryProtocol
    private let progressRepository: ProgressRepositoryProtocol
    private let wordProgressRepository: WordProgressRepositoryProtocol
    private let disposeBag = DisposeBag()

    // MARK: - Init

    /// - Parameters:
    ///   - soundService: Owns the persisted sound-enabled flag.
    ///   - hapticsService: Owns the persisted haptics-enabled flag.
    ///   - settingsRepository: Persists the scoring difficulty.
    ///   - progressRepository: Cleared by "Reset All Progress".
    ///   - wordProgressRepository: Cleared by "Reset All Progress".
    init(
        soundService: SoundServiceProtocol,
        hapticsService: HapticsServiceProtocol,
        settingsRepository: SettingsRepositoryProtocol,
        progressRepository: ProgressRepositoryProtocol,
        wordProgressRepository: WordProgressRepositoryProtocol
    ) {
        self.soundService           = soundService
        self.hapticsService         = hapticsService
        self.settingsRepository     = settingsRepository
        self.progressRepository     = progressRepository
        self.wordProgressRepository = wordProgressRepository

        self.isSoundEnabled   = soundService.isSoundEnabled
        self.isHapticsEnabled = hapticsService.isEnabled

        settingsRepository.load()
            .observe(on: MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] settings in
                self?.difficulty = settings.difficulty
            })
            .disposed(by: disposeBag)
    }

    // MARK: - SettingsViewModelProtocol inputs

    func setSoundEnabled(_ enabled: Bool) {
        soundService.isSoundEnabled = enabled
        isSoundEnabled = enabled
    }

    func setHapticsEnabled(_ enabled: Bool) {
        hapticsService.isEnabled = enabled
        isHapticsEnabled = enabled
    }

    func setDifficulty(_ difficulty: PassDifficulty) {
        self.difficulty = difficulty
        settingsRepository.save(AppSettings(difficulty: difficulty))
            .subscribe()
            .disposed(by: disposeBag)
    }

    func requestResetProgress() {
        showResetConfirmation = true
    }

    func confirmResetProgress() {
        Completable.zip(progressRepository.resetAll(), wordProgressRepository.resetAll())
            .observe(on: MainScheduler.instance)
            .subscribe(onCompleted: { [weak self] in
                self?.showResetConfirmation = false
            })
            .disposed(by: disposeBag)
    }

    func cancelResetProgress() {
        showResetConfirmation = false
    }
}
