import Foundation

/// App-wide preferences persisted independently of letter/word progress.
///
/// ```swift
/// let updated = AppSettings.lensDifficulty.set(settings, .challenge)
/// ```
struct AppSettings: AppSettingsProtocol, Codable, Equatable {
    let difficulty: PassDifficulty
    let activeAlphabetId: String?
}

// MARK: - Default

extension AppSettings {
    /// Used the first time the app runs, before anything has been saved.
    /// `activeAlphabetId` is `nil` until the child explicitly switches
    /// alphabets — callers fall back to the first installed alphabet.
    static let `default` = AppSettings(difficulty: .standard, activeAlphabetId: nil)
}

// MARK: - Lenses

extension AppSettings {

    /// Focuses on `difficulty`. Use to change the scoring pass threshold.
    static let lensDifficulty = Lens<AppSettings, PassDifficulty>(
        get: { $0.difficulty },
        set: { whole, value in AppSettings(difficulty: value, activeAlphabetId: whole.activeAlphabetId) }
    )

    /// Focuses on `activeAlphabetId`. Use when the child switches which
    /// alphabet's letters Home shows.
    static let lensActiveAlphabetId = Lens<AppSettings, String?>(
        get: { $0.activeAlphabetId },
        set: { whole, value in AppSettings(difficulty: whole.difficulty, activeAlphabetId: value) }
    )
}
