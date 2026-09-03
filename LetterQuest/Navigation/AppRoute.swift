import Foundation

/// All navigable destinations in the app.
///
/// `AppRoute` conforms to `Hashable` so it can be used as the element type of
/// `NavigationPath` in `NavigationStack`. Associated values are value types,
/// so synthesis of `Hashable` is automatic.
enum AppRoute: Hashable {
    /// The letter-grid home screen.
    case home

    /// The drawing practice screen for the letter identified by `letterId`.
    case practice(letterId: UUID)

    /// The child's overall progress/achievements screen.
    case progress

    /// The animated "Watch me draw" demonstration screen shown before practice.
    ///
    /// - Parameter letterId: The letter whose strokes will be demonstrated.
    case learn(letterId: UUID)

    /// A full-screen celebration shown after passing a letter.
    ///
    /// - Parameters:
    ///   - score: The final composite score that triggered the celebration.
    ///   - letterId: The letter that was just completed.
    case celebration(score: Int, letterId: UUID)

    /// The word-practice list/grid screen. Reachable once the child has
    /// completed both the uppercase and lowercase alphabets.
    case words

    /// The word-practice screen for the word identified by `wordId`, tracing
    /// its letters in sequence via the existing single-letter practice flow.
    case word(wordId: UUID)
}
