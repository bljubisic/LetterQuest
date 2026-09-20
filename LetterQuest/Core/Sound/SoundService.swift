import AVFoundation

/// Plays short audio cues via `AVAudioPlayer`.
///
/// All three players are preloaded on init so playback is instant with no
/// latency spike at the moment the child finishes drawing. The `.playback`
/// audio-session category is used so cues play through the iPhone silent/ring
/// switch — essential for an educational app where audio feedback is part of
/// the teaching loop.
///
/// If an audio file is missing from the bundle the corresponding player is
/// `nil` and that cue is silently skipped — the rest of the app is unaffected.
final class SoundService: SoundServiceProtocol {

    // MARK: - SoundServiceProtocol

    var isSoundEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: Self.enabledKey) }
        set { UserDefaults.standard.set(newValue, forKey: Self.enabledKey) }
    }

    // MARK: - Private

    private static let enabledKey = "letter_quest_sound_enabled_v1"

    /// Every `AVAudioSession`/`AVAudioPlayer` call is serialized on this
    /// queue — none of them are safe to call from the main thread (Apple's
    /// own runtime warning: "This method can lead to UI unresponsiveness if
    /// called on the main thread"), and routing both the init-time setup and
    /// every `play()` call through the same queue avoids a data race on the
    /// player properties themselves.
    private let audioQueue = DispatchQueue(label: "com.letterquest.sound", qos: .userInitiated)

    private var successPlayer:       AVAudioPlayer?
    private var encouragementPlayer: AVAudioPlayer?
    private var errorPlayer:         AVAudioPlayer?

    // MARK: - Init

    init() {
        // Default to enabled the first time the app runs.
        if UserDefaults.standard.object(forKey: Self.enabledKey) == nil {
            UserDefaults.standard.set(true, forKey: Self.enabledKey)
        }

        audioQueue.async { [weak self] in
            self?.configureAudioSession()
            self?.successPlayer       = self?.makePlayer(named: "sound_success")
            self?.encouragementPlayer = self?.makePlayer(named: "sound_encouragement")
            self?.errorPlayer         = self?.makePlayer(named: "sound_error")
        }
    }

    // MARK: - SoundServiceProtocol methods

    func playSuccess()       { play(\.successPlayer) }
    func playEncouragement() { play(\.encouragementPlayer) }
    func playSoftError()     { play(\.errorPlayer) }

    // MARK: - Helpers

    private func configureAudioSession() {
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    private func makePlayer(named name: String) -> AVAudioPlayer? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "caf") else {
            return nil
        }
        let player = try? AVAudioPlayer(contentsOf: url)
        player?.prepareToPlay()
        return player
    }

    private func play(_ keyPath: KeyPath<SoundService, AVAudioPlayer?>) {
        guard isSoundEnabled else { return }
        audioQueue.async { [weak self] in
            guard let self, let player = self[keyPath: keyPath] else { return }
            player.currentTime = 0
            player.play()
        }
    }
}
