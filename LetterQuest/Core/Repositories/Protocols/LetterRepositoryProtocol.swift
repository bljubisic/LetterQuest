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

    /// Returns the letter immediately following `id` in the alphabet sequence,
    /// or `nil` when `id` is the final letter (or not found).
    ///
    /// Used by `PracticeViewModel` to drive sequential unlock + auto-advance
    /// after a passing score.
    ///
    /// - Parameter id: The stable `UUID` of the current letter.
    /// - Returns: A `Single` emitting an optional next `Letter`.
    func fetchNext(after id: UUID) -> Single<Letter?>
}
