import Testing
@testable import LetterQuest

/// Validates stroke counts for every lowercase Serbian Cyrillic letter
/// template. Mirrors `LowercaseStrokeTemplateTests`'s asymmetry relative to
/// the uppercase spec in `CyrillicStrokeTemplateTests` — counts only, no
/// direction oracle.
struct CyrillicLowercaseStrokeTemplateTests {

    private let expectedStrokeCounts: [(Character, Int)] = [
        ("а", 2), ("б", 3), ("в", 2), ("г", 2), ("д", 4), ("ђ", 3),
        ("е", 2), ("ж", 5), ("з", 1), ("и", 3), ("ј", 1), ("к", 3),
        ("л", 2), ("љ", 4), ("м", 4), ("н", 3), ("њ", 4), ("о", 1),
        ("п", 3), ("р", 2), ("с", 1), ("т", 2), ("ћ", 3), ("у", 2),
        ("ф", 2), ("х", 2), ("ц", 2), ("ч", 2), ("џ", 2), ("ш", 4)
    ]

    @Test("each lowercase letter has the expected number of stroke templates")
    func strokeCountsMatchSpec() {
        for (char, expectedCount) in expectedStrokeCounts {
            let templates = StrokeTemplate.templates(for: char)
            #expect(templates.count == expectedCount,
                    "'\(char)' should have \(expectedCount) stroke(s) but got \(templates.count)")
        }
    }

    @Test("each lowercase letter template has at least one point per stroke")
    func eachStrokeHasPoints() {
        for char in "абвгдђежзијклљмнњопрстћуфхцчџш" {
            for template in StrokeTemplate.templates(for: char) {
                #expect(!template.points.isEmpty,
                        "'\(char)' stroke \(template.strokeIndex) has no points")
            }
        }
    }

    @Test("all 30 lowercase letters are in Alphabet.cyrillicSr")
    func lowercaseAlphabetIsComplete() {
        let lowercase = Alphabet.cyrillicSr.letters.filter { $0.letterCase == .lower }
        #expect(lowercase.count == 30)
        #expect(lowercase.allSatisfy { $0.letterCase == .lower })
    }

    @Test("lowercase letters have distinct UUIDs from uppercase")
    func lowercaseAndUppercaseHaveDistinctIds() {
        let uppercaseIds = Set(Alphabet.cyrillicSr.letters.filter { $0.letterCase == .upper }.map(\.id))
        let lowercaseIds = Set(Alphabet.cyrillicSr.letters.filter { $0.letterCase == .lower }.map(\.id))
        #expect(uppercaseIds.isDisjoint(with: lowercaseIds))
    }
}
