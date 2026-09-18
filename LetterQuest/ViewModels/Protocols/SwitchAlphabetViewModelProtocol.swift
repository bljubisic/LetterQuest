import Foundation

/// The contract that `SwitchAlphabetView` depends on.
///
/// Keeping the view generic over `SwitchAlphabetViewModelProtocol` makes it
/// trivial to inject a mock during testing or SwiftUI previews.
protocol SwitchAlphabetViewModelProtocol: ObservableObject {

    /// Every installed alphabet (free and purchased).
    var installedAlphabets: [Alphabet] { get }

    /// The `Alphabet.id` Home currently shows.
    var activeAlphabetId: String { get }

    /// `true` while the repositories are loading data.
    var isLoading: Bool { get }

    /// Triggers a (re-)load of installed alphabets and the active-alphabet
    /// selection from the repositories.
    func load()

    /// Makes `alphabetId` the active alphabet, persists the choice, and
    /// returns to Home.
    ///
    /// - Parameter alphabetId: The `Alphabet.id` to activate.
    func selectAlphabet(_ alphabetId: String)

    /// Navigates to the alphabet store to browse alphabets not yet owned.
    func navigateToStore()
}
