import Foundation

/// The contract that `WordPracticeView` depends on.
///
/// `WordPracticeView` is generic over this protocol so that the real
/// `WordPracticeViewModel` and a preview/test mock are interchangeable.
protocol WordPracticeViewModelProtocol: ObservableObject {

    /// The word being practiced. Populated asynchronously after init.
    var word: Word? { get }

    /// The index, within `word.characters`, of the letter currently being practiced.
    var currentIndex: Int { get }

    /// `true` once the child has passed every letter in the word.
    var isWordCompleted: Bool { get }

    /// Builds a fresh `PracticeViewModel` for the letter at `currentIndex`, wired
    /// so that a passing score advances the word sequence instead of navigating
    /// via the router. Returns `nil` until `word` has loaded.
    func makeLetterViewModel() -> PracticeViewModel?

    /// Navigates back to the home screen after the word-completion celebration.
    func finish()
}
