import Testing
import Foundation
@testable import LetterQuest

// MARK: - Test fixture

private struct Box: Equatable {
    let value: Int
    let label: String
}

private let valueLens = Lens<Box, Int>(
    get: { $0.value },
    set: { whole, new in Box(value: new, label: whole.label) }
)

private let labelLens = Lens<Box, String>(
    get: { $0.label },
    set: { whole, new in Box(value: whole.value, label: new) }
)

// MARK: - Basic get / set

struct LensGetSetTests {

    @Test("get extracts the focused field")
    func getExtractsField() {
        let box = Box(value: 42, label: "hello")
        #expect(valueLens.get(box) == 42)
        #expect(labelLens.get(box) == "hello")
    }

    @Test("set returns a new whole with the part replaced")
    func setReplacesField() {
        let original = Box(value: 1, label: "a")
        let updated  = valueLens.set(original, 99)
        #expect(updated.value == 99)
        #expect(updated.label == "a")
    }

    @Test("set does not mutate the original value")
    func setDoesNotMutateOriginal() {
        let original = Box(value: 10, label: "x")
        _ = valueLens.set(original, 0)
        #expect(original.value == 10)
    }

    @Test("setting a field to its existing value returns an equal whole")
    func setToSameValueReturnsEqual() {
        let box = Box(value: 5, label: "y")
        let same = valueLens.set(box, 5)
        #expect(same == box)
    }
}

// MARK: - over (transform)

struct LensOverTests {

    @Test("over applies a transform and returns a new whole")
    func overAppliesTransform() {
        let original = Box(value: 10, label: "x")
        let doubled  = valueLens.over(original) { $0 * 2 }
        #expect(doubled.value == 20)
        #expect(original.value == 10)
    }

    @Test("over with identity transform returns an equal whole")
    func overIdentityReturnsEqual() {
        let box    = Box(value: 7, label: "z")
        let result = valueLens.over(box) { $0 }
        #expect(result == box)
    }

    @Test("curried over returns a (Whole) -> Whole function")
    func curriedOverReturnsFunction() {
        let increment = valueLens.over { $0 + 1 }
        let original  = Box(value: 5, label: "y")
        let result    = increment(original)
        #expect(result.value == 6)
    }

    @Test("curried over works with the |> pipe operator")
    func curriedOverWithPipeOperator() {
        let original  = Box(value: 3, label: "p")
        let addTen    = valueLens.over { $0 + 10 }
        let addHundred = valueLens.over { $0 + 100 }
        let result    = original |> addTen |> addHundred
        #expect(result.value == 113)
    }
}

// MARK: - Composition

struct LensComposeTests {

    @Test("compose creates a lens that focuses on a nested field")
    func composeFocusesOnNestedField() {
        struct Outer: Equatable { let inner: Box }
        let outerLens = Lens<Outer, Box>(
            get: { $0.inner },
            set: { _, new in Outer(inner: new) }
        )
        let deepLens = outerLens.compose(valueLens)
        let outer    = Outer(inner: Box(value: 7, label: "z"))

        #expect(deepLens.get(outer) == 7)

        let updated = deepLens.set(outer, 99)
        #expect(updated.inner.value == 99)
        #expect(updated.inner.label == "z")
    }

    @Test("composed lens does not mutate the outer value")
    func composedLensIsImmutable() {
        struct Outer: Equatable { let inner: Box }
        let outerLens = Lens<Outer, Box>(
            get: { $0.inner },
            set: { _, new in Outer(inner: new) }
        )
        let deepLens = outerLens.compose(valueLens)
        let original = Outer(inner: Box(value: 1, label: "a"))
        _ = deepLens.set(original, 42)
        #expect(original.inner.value == 1)
    }
}

// MARK: - Pipe operator (|>)

struct PipeOperatorTests {

    @Test("|> applies a function to a value")
    func pipeAppliesFunction() {
        let result = 5 |> { $0 * 2 }
        #expect(result == 10)
    }

    @Test("|> is left-associative")
    func pipeIsLeftAssociative() {
        let result = 1 |> { $0 + 1 } |> { $0 * 3 }
        // (1 + 1) * 3 = 6
        #expect(result == 6)
    }
}
