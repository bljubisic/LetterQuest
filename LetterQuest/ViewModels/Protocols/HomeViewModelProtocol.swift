import Foundation

/// The contract that `HomeView` depends on.
///
/// Keeping the view generic over `HomeViewModelProtocol` makes it trivial
/// to inject a mock during testing or SwiftUI previews:
/// ```swift
/// HomeView(viewModel: MockHomeViewModel())
/// ```
protocol HomeViewModelProtocol: ObservableObject {

    /// All letters in alphabetical order.
    var letters: [Letter] { get }

    /// Maps each letter's `id` to its progress record.
    /// Letters that have never been attempted are absent from this dictionary.
    var progressMap: [UUID: ChildProgress] { get }

    /// `true` while the repositories are loading data.
    var isLoading: Bool { get }

    /// Triggers a (re-)load of letters and progress from the repositories.
    func load()

    /// Navigates to the practice screen for the given letter.
    ///
    /// - Parameter letter: The letter the child tapped on.
    func selectLetter(_ letter: Letter)
}
