import Foundation

/// Describes the app-wide preferences that persist independently of any
/// single letter or word — currently just the scoring difficulty.
///
/// Sound and haptics enablement are intentionally *not* part of this model:
/// `SoundServiceProtocol`/`HapticsServiceProtocol` already own persisted,
/// gettable/settable flags for those, so `AppSettings` only holds state that
/// doesn't already have a home.
protocol AppSettingsProtocol {
    /// The pass/fail strictness applied by `HandwritingAssessor`.
    var difficulty: PassDifficulty { get }
}
