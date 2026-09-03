import Foundation

/// The contract that `WordsListView` depends on.
///
/// Keeping the view generic over `WordsListViewModelProtocol` makes it trivial
/// to inject a mock during testing or SwiftUI previews.
protocol WordsListViewModelProtocol: ObservableObject {

    /// The curated word list.
    var words: [Word] { get }

    /// Maps each word's `id` to its progress record.
    /// Words that have never been completed are absent from this dictionary.
    var progressMap: [UUID: WordProgress] { get }

    /// `true` while the repositories are loading data.
    var isLoading: Bool { get }

    /// Triggers a (re-)load of words and progress from the repositories.
    func load()

    /// Navigates to the practice screen for the given word.
    ///
    /// - Parameter word: The word the child tapped on.
    func selectWord(_ word: Word)
}
