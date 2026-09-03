import Foundation

/// The recorded completion state for a single word.
///
/// Unlike `ChildProgress`, word progress has no attempt history or best score —
/// a word session always restarts at its first letter, so the only thing worth
/// persisting is whether the child has ever finished it.
///
/// ```swift
/// let completed = WordProgress.lensIsCompleted.set(progress, true)
/// ```
struct WordProgress: WordProgressProtocol, Codable, Equatable {
    let wordId: UUID
    let isCompleted: Bool
}

// MARK: - Lenses

extension WordProgress {

    /// Focuses on the completion flag. Set to `true` once every letter in the word has passed.
    static let lensIsCompleted = Lens<WordProgress, Bool>(
        get: { $0.isCompleted },
        set: { whole, value in
            WordProgress(wordId: whole.wordId, isCompleted: value)
        }
    )
}
