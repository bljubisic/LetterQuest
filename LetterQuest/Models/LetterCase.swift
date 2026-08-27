import Foundation

/// Indicates whether a letter belongs to the uppercase (A–Z) or lowercase (a–z) set.
///
/// Lowercase letters are unlocked as a group after the child passes all 26 uppercase letters.
enum LetterCase: String, CaseIterable, Codable {
    case upper
    case lower
    case digit
}
