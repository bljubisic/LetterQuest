import Foundation

/// App-wide preferences persisted independently of letter/word progress.
///
/// ```swift
/// let updated = AppSettings.lensDifficulty.set(settings, .challenge)
/// ```
struct AppSettings: AppSettingsProtocol, Codable, Equatable {
    let difficulty: PassDifficulty
}

// MARK: - Default

extension AppSettings {
    /// Used the first time the app runs, before anything has been saved.
    static let `default` = AppSettings(difficulty: .standard)
}

// MARK: - Lenses

extension AppSettings {

    /// Focuses on `difficulty`. Use to change the scoring pass threshold.
    static let lensDifficulty = Lens<AppSettings, PassDifficulty>(
        get: { $0.difficulty },
        set: { whole, value in AppSettings(difficulty: value) }
    )
}
