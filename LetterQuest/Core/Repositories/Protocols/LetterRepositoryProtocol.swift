import Foundation
import RxSwift

/// Provides access to the letter catalogue.
///
/// The production implementation (`LetterRepository`) returns the static in-memory
/// alphabet. A test double can return any subset of letters.
protocol LetterRepositoryProtocol {

    /// Returns all letters in alphabetical order.
    ///
    /// - Returns: A `Single` that emits the full `[Letter]` array then completes.
    func fetchAll() -> Single<[Letter]>

    /// Returns the letter with the given `id`, or `nil` when not found.
    ///
    /// - Parameter id: The stable `UUID` of the target letter.
    /// - Returns: A `Single` emitting an optional `Letter`.
    func fetch(by id: UUID) -> Single<Letter?>
}
