import CryptoKit
import Foundation

/// Stable, name-based UUID generation (RFC 4122 version 3 / MD5).
///
/// `Letter.id`/`Word.id` used to be plain `UUID()`, which is randomly
/// regenerated every time the `static let` seed arrays are first evaluated —
/// i.e. on every app launch. Since `ChildProgress.letterId`/
/// `WordProgress.wordId` are persisted to `UserDefaults` and matched against
/// those ids on the *next* launch, saved progress could never actually match
/// after a real relaunch. `DeterministicID.uuid(name:)` instead derives the
/// same UUID every time from a stable name (e.g. `"letter.latin.upper.A"`),
/// so identity survives relaunches and stays unique across alphabets.
enum DeterministicID {

    /// Scopes every name-based id this app generates, so they can never
    /// collide with a UUID produced any other way. Value is arbitrary but
    /// fixed forever — changing it would regenerate every id.
    private static let namespace = UUID(uuidString: "8F2C1D0A-6B3E-4B7F-9C1A-2E5D7F8A9B10")!

    /// Returns the same `UUID` every time for the same `name`.
    static func uuid(name: String) -> UUID {
        var bytes = withUnsafeBytes(of: namespace.uuid) { Array($0) }
        bytes.append(contentsOf: Array(name.utf8))

        var digest = Array(Insecure.MD5.hash(data: Data(bytes)))
        // RFC 4122 §4.3: set the version (3) and variant bits.
        digest[6] = (digest[6] & 0x0F) | 0x30
        digest[8] = (digest[8] & 0x3F) | 0x80

        let tuple: uuid_t = (
            digest[0], digest[1], digest[2], digest[3],
            digest[4], digest[5], digest[6], digest[7],
            digest[8], digest[9], digest[10], digest[11],
            digest[12], digest[13], digest[14], digest[15]
        )
        return UUID(uuid: tuple)
    }
}
