import Foundation

/// How strict the pass/fail threshold is for the handwriting assessment pipeline.
///
/// Distinct from `LetterDifficulty` (which tiers letters for unlock ordering) —
/// this controls the `overallScore` a child must reach to pass *any* letter,
/// regardless of how visually complex that letter is.
enum PassDifficulty: String, CaseIterable, Codable, Identifiable {
    case easy
    case standard
    case challenge

    var id: Self { self }

    /// The minimum `overallScore` required to pass.
    var passThreshold: Int {
        switch self {
        case .easy:      return 60
        case .standard:  return 75
        case .challenge: return 85
        }
    }

    /// User-facing label shown in the Settings screen's difficulty picker.
    var displayName: String {
        switch self {
        case .easy:      return "Easy"
        case .standard:  return "Standard"
        case .challenge: return "Challenge"
        }
    }
}
