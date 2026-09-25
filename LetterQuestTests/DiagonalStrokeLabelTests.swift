import Testing
import CoreGraphics
@testable import LetterQuest

/// `DTWMatcher` scores a `.diagonal(angle:)` stroke by its slope: a positive
/// angle means "\" (x and y grow together, y pointing down), a negative one
/// means "/". Every template's label must agree with its actual points, or a
/// correctly drawn stroke would be marked as the wrong slope. It must also
/// be steep/shallow enough that `DTWMatcher` recognises it as a diagonal.
struct DiagonalStrokeLabelTests {

    private static let allAlphabets: [Alphabet] = [.latin, .cyrillicSr, .german, .spanish, .swedish, .croatian, .french]

    @Test("every diagonal template's angle sign matches the slope of its points",
          arguments: allAlphabets.map(\.id))
    func diagonalLabelsMatchSlope(alphabetId: String) {
        let alphabet = Self.allAlphabets.first { $0.id == alphabetId }!
        for letter in alphabet.letters {
            for template in letter.strokeTemplates {
                guard case .diagonal(let angle) = template.direction,
                      let start = template.points.first, let end = template.points.last else { continue }
                let dx = end.x - start.x, dy = end.y - start.y
                let slopeIsBackslash = dx * dy > 0
                #expect(slopeIsBackslash == (angle > 0),
                        "\(letter.character) stroke \(template.strokeIndex): angle \(angle) doesn't match its points")
                #expect(min(abs(dx), abs(dy)) >= DTWMatcher.minimumDiagonalAxisRatio * max(abs(dx), abs(dy)),
                        "\(letter.character) stroke \(template.strokeIndex): too close to horizontal/vertical to score as a diagonal")
            }
        }
    }
}
