/// A `Lens` focuses on a single `Part` inside a `Whole`, giving you both a getter
/// and an immutable setter. This lets you update deeply nested read-only structs
/// without mutation: you create a new value rather than changing the old one.
///
/// **Basic usage**
/// ```swift
/// let updated = ChildProgress.lensAttempts.over(progress) { $0 + [newAttempt] }
/// ```
///
/// **Composition** — zoom into a nested field:
/// ```swift
/// let lens = ChildProgress.lensAttempts.compose(Lens<[Attempt], Int>(
///     get: { $0.count },
///     set: { attempts, _ in attempts }   // read-only composition example
/// ))
/// ```
struct Lens<Whole, Part> {

    /// Returns the focused `Part` from a `Whole`.
    let get: (Whole) -> Part

    /// Returns a new `Whole` with the focused `Part` replaced.
    let set: (Whole, Part) -> Whole

    /// Creates a lens from explicit getter and setter closures.
    init(get: @escaping (Whole) -> Part, set: @escaping (Whole, Part) -> Whole) {
        self.get = get
        self.set = set
    }

    // MARK: - Transformations

    /// Returns a new `Whole` by applying `transform` to the focused `Part`.
    ///
    /// - Parameters:
    ///   - whole: The source value.
    ///   - transform: A function from the old part to the new part.
    /// - Returns: A new `Whole` with the transformed part.
    func over(_ whole: Whole, _ transform: (Part) -> Part) -> Whole {
        set(whole, transform(get(whole)))
    }

    /// Curried form of `over` that returns a `(Whole) -> Whole` function,
    /// for composing lens updates with the `|>` pipe operator.
    ///
    /// - Parameter transform: A function from the old part to the new part.
    /// - Returns: A function that produces an updated `Whole` from a source `Whole`.
    func over(_ transform: @escaping (Part) -> Part) -> (Whole) -> Whole {
        { whole in self.set(whole, transform(self.get(whole))) }
    }

    // MARK: - Composition

    /// Composes two lenses to produce a lens that focuses on `SubPart` inside `Whole`.
    ///
    /// - Parameter other: A lens from `Part` to `SubPart`.
    /// - Returns: A composed lens from `Whole` to `SubPart`.
    func compose<SubPart>(_ other: Lens<Part, SubPart>) -> Lens<Whole, SubPart> {
        Lens<Whole, SubPart>(
            get: { other.get(self.get($0)) },
            set: { whole, subPart in
                self.set(whole, other.set(self.get(whole), subPart))
            }
        )
    }
}
