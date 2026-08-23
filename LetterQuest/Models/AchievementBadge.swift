import Foundation

/// A single achievement awarded when a progress milestone is reached.
///
/// Unearned badges are included in the list with `isEarned == false` so the
/// UI can always show all three tiles and grey out the ones not yet unlocked.
struct AchievementBadge: Identifiable {
    let id: String
    let title: String
    let systemImage: String
    let isEarned: Bool
}
