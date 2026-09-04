import Foundation

/// The contract that `SettingsView` depends on.
///
/// `SettingsView` is generic over this protocol so that the real
/// `SettingsViewModel` and a preview/test mock are interchangeable.
protocol SettingsViewModelProtocol: ObservableObject {

    /// Whether audio cues play after each assessment.
    var isSoundEnabled: Bool { get }

    /// Whether tactile feedback plays after each assessment.
    var isHapticsEnabled: Bool { get }

    /// The current pass-threshold strictness.
    var difficulty: PassDifficulty { get }

    /// `true` while the "Reset All Progress" confirmation alert is showing.
    var showResetConfirmation: Bool { get }

    /// Enables or disables sound effects.
    func setSoundEnabled(_ enabled: Bool)

    /// Enables or disables haptic feedback.
    func setHapticsEnabled(_ enabled: Bool)

    /// Changes the scoring pass threshold.
    func setDifficulty(_ difficulty: PassDifficulty)

    /// Shows the reset-progress confirmation alert.
    func requestResetProgress()

    /// Confirms the reset: erases all letter and word progress.
    func confirmResetProgress()

    /// Dismisses the confirmation alert without resetting anything.
    func cancelResetProgress()
}
