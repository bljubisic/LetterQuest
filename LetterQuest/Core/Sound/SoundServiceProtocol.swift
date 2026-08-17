import Foundation

/// Contract for the audio feedback layer.
///
/// Three distinct cues map to the three outcome bands produced by the
/// assessment pipeline. `isSoundEnabled` is persisted so a future Settings
/// screen can toggle audio without touching any ViewModel.
protocol SoundServiceProtocol: AnyObject {

    /// Whether audio cues are active. Backed by `UserDefaults`; defaults to `true`.
    var isSoundEnabled: Bool { get set }

    /// Plays the success chime — score ≥ 75 (passed).
    func playSuccess()

    /// Plays the encouraging sound — score 50–74 (keep trying).
    func playEncouragement()

    /// Plays the soft error sound — score < 50.
    func playSoftError()
}
