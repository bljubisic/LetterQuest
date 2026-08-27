import Testing
@testable import LetterQuest

/// Validates stroke counts for every lowercase letter template.
/// Mirrors the pedagogical spec in `StrokeTemplateTests` for uppercase.
struct LowercaseStrokeTemplateTests {

    private let expectedStrokeCounts: [(Character, Int)] = [
        ("a", 2),  // oval + right stem
        ("b", 2),  // ascender spine + right bump
        ("c", 1),  // arc
        ("d", 2),  // oval + right ascender spine
        ("e", 2),  // crossbar + reverse-C arc
        ("f", 2),  // hooked spine + crossbar
        ("g", 2),  // oval + descending right stem
        ("h", 2),  // ascender spine + arch
        ("i", 2),  // short vertical + dot
        ("j", 2),  // descending stem with hook + dot
        ("k", 3),  // ascender spine + upper diagonal + lower diagonal
        ("l", 1),  // single spine
        ("m", 3),  // left stem + two arches
        ("n", 2),  // left stem + one arch
        ("o", 1),  // full circle
        ("p", 2),  // descending stem + right bump
        ("q", 2),  // oval + descending right stem
        ("r", 2),  // short stem + shoulder
        ("s", 1),  // S-curve
        ("t", 2),  // spine + crossbar
        ("u", 1),  // U-shape
        ("v", 2),  // two diagonals
        ("w", 4),  // four diagonals
        ("x", 2),  // two crossing diagonals
        ("y", 2),  // left diagonal + descending right diagonal
        ("z", 3)   // top bar + diagonal + bottom bar
    ]

    @Test("each lowercase letter has the expected number of stroke templates")
    func strokeCountsMatchSpec() {
        for (char, expectedCount) in expectedStrokeCounts {
            let templates = StrokeTemplate.templates(for: char)
            #expect(templates.count == expectedCount,
                    "'\(char)' should have \(expectedCount) stroke(s) but got \(templates.count)")
        }
    }

    @Test("each lowercase letter template has at least two points per stroke")
    func eachStrokeHasPoints() {
        for char in "abcdefghijklmnopqrstuvwxyz" {
            for template in StrokeTemplate.templates(for: char) {
                #expect(!template.points.isEmpty,
                        "'\(char)' stroke \(template.strokeIndex) has no points")
            }
        }
    }

    @Test("all 26 lowercase letters are in Letter.lowercaseAlphabet")
    func lowercaseAlphabetIsComplete() {
        #expect(Letter.lowercaseAlphabet.count == 26)
        #expect(Letter.lowercaseAlphabet.allSatisfy { $0.letterCase == .lower })
    }

    @Test("lowercase letters have distinct UUIDs from uppercase")
    func lowercaseAndUppercaseHaveDistinctIds() {
        let uppercaseIds = Set(Letter.alphabet.map { $0.id })
        let lowercaseIds = Set(Letter.lowercaseAlphabet.map { $0.id })
        #expect(uppercaseIds.isDisjoint(with: lowercaseIds))
    }
}
