import CoreHaptics

/// Plays tactile feedback patterns via the Taptic Engine using Core Haptics.
///
/// Three distinct patterns map to the same outcome bands as `SoundService`.
/// On devices without a Taptic Engine (`isSupported == false`) every call is
/// a no-op — no crash, no observable side effect.
///
/// The engine can be stopped by the system (e.g. when the app backgrounds).
/// The `resetHandler` restarts it automatically so the next play call works
/// without the caller needing to know it was ever interrupted.
final class HapticsService: HapticsServiceProtocol {

    // MARK: - HapticsServiceProtocol

    var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: Self.enabledKey) }
        set { UserDefaults.standard.set(newValue, forKey: Self.enabledKey) }
    }

    // MARK: - Private

    private static let enabledKey = "letter_quest_haptics_enabled_v1"

    private let isSupported: Bool
    private var engine: CHHapticEngine?

    // MARK: - Init

    init() {
        isSupported = CHHapticEngine.capabilitiesForHardware().supportsHaptics

        // First launch: default to enabled only when the hardware supports it.
        if UserDefaults.standard.object(forKey: Self.enabledKey) == nil {
            UserDefaults.standard.set(isSupported, forKey: Self.enabledKey)
        }

        if isSupported { startEngine() }
    }

    // MARK: - HapticsServiceProtocol methods

    /// Three ascending sharp pulses — celebratory "tada" burst.
    func playSuccess() {
        play(events: [
            makeEvent(time: 0.00, intensity: 0.50, sharpness: 0.8, duration: 0.10),
            makeEvent(time: 0.15, intensity: 0.75, sharpness: 0.9, duration: 0.10),
            makeEvent(time: 0.35, intensity: 1.00, sharpness: 1.0, duration: 0.15)
        ])
    }

    /// One medium soft pulse — warm encouraging nudge.
    func playEncouragement() {
        play(events: [
            makeEvent(time: 0.0, intensity: 0.5, sharpness: 0.4, duration: 0.15)
        ])
    }

    /// One short low-intensity thud — gentle, non-alarming bump.
    func playSoftError() {
        play(events: [
            makeEvent(time: 0.0, intensity: 0.3, sharpness: 0.1, duration: 0.10)
        ])
    }

    // MARK: - Engine management

    private func startEngine() {
        do {
            let engine = try CHHapticEngine()
            // Restart automatically after the system stops the engine.
            engine.resetHandler = { [weak engine] in
                try? engine?.start()
            }
            engine.stoppedHandler = { _ in }
            try engine.start()
            self.engine = engine
        } catch {
            engine = nil
        }
    }

    // MARK: - Playback helpers

    private func makeEvent(
        time: TimeInterval,
        intensity: Float,
        sharpness: Float,
        duration: TimeInterval
    ) -> CHHapticEvent {
        CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
            ],
            relativeTime: time,
            duration: duration
        )
    }

    private func play(events: [CHHapticEvent]) {
        guard isEnabled, isSupported, let engine else { return }
        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player  = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            // Haptic failure is non-fatal — the rest of the experience continues.
        }
    }
}
