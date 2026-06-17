import Testing
import CoreGraphics
@testable import LetterQuest

// MARK: - Expected stroke spec for all 26 uppercase letters
//
// Each entry defines the pedagogically correct stroke count and direction sequence
// for teaching children to print the letter. Tests against this spec will fail for
// letters that currently use the single-stroke fallback, acting as a checklist for
// the remaining template implementation work.

private typealias Spec = (strokes: Int, directions: [StrokeDirection])

private let letterSpec: [Character: Spec] = [
    "A": (3, [.diagonal(angle: 45), .diagonal(angle: -45), .leftToRight]),
    "B": (2, [.topToBottom, .curved]),
    "C": (1, [.curved]),
    "D": (2, [.topToBottom, .curved]),
    "E": (4, [.topToBottom, .leftToRight, .leftToRight, .leftToRight]),
    "F": (3, [.topToBottom, .leftToRight, .leftToRight]),
    "G": (3, [.curved, .leftToRight, .topToBottom]),
    "H": (3, [.topToBottom, .topToBottom, .leftToRight]),
    "I": (1, [.topToBottom]),
    "J": (2, [.topToBottom, .curved]),
    "K": (3, [.topToBottom, .diagonal(angle: -45), .diagonal(angle: 45)]),
    "L": (2, [.topToBottom, .leftToRight]),
    "M": (4, [.topToBottom, .diagonal(angle: 45), .diagonal(angle: -45), .topToBottom]),
    "N": (3, [.topToBottom, .diagonal(angle: 45), .topToBottom]),
    "O": (1, [.curved]),
    "P": (2, [.topToBottom, .curved]),
    "Q": (2, [.curved, .diagonal(angle: 45)]),
    "R": (3, [.topToBottom, .curved, .diagonal(angle: 45)]),
    "S": (1, [.curved]),
    "T": (2, [.leftToRight, .topToBottom]),
    "U": (1, [.curved]),
    "V": (2, [.diagonal(angle: 45), .diagonal(angle: -45)]),
    "W": (4, [.diagonal(angle: 45), .diagonal(angle: -45), .diagonal(angle: 45), .diagonal(angle: -45)]),
    "X": (2, [.diagonal(angle: 45), .diagonal(angle: -45)]),
    "Y": (3, [.diagonal(angle: 45), .diagonal(angle: -45), .topToBottom]),
    "Z": (3, [.leftToRight, .diagonal(angle: -45), .leftToRight]),
]

private let allLetters = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ")

// MARK: - Structural integrity (all 26 letters must pass these)

struct StrokeTemplateStructureTests {

    @Test("Each letter returns at least one stroke template",
          arguments: allLetters)
    func hasAtLeastOneStroke(letter: Character) {
        #expect(!StrokeTemplate.templates(for: letter).isEmpty)
    }

    @Test("strokeIndex values are zero-based and sequential",
          arguments: allLetters)
    func strokeIndicesAreSequential(letter: Character) {
        let templates = StrokeTemplate.templates(for: letter)
        for (expected, template) in templates.enumerated() {
            #expect(
                template.strokeIndex == expected,
                "Letter \(letter) stroke \(expected): strokeIndex is \(template.strokeIndex)"
            )
        }
    }

    @Test("Every stroke has at least one reference point",
          arguments: allLetters)
    func strokePointsNonEmpty(letter: Character) {
        let templates = StrokeTemplate.templates(for: letter)
        for template in templates {
            #expect(
                !template.points.isEmpty,
                "Letter \(letter) stroke \(template.strokeIndex) has no points"
            )
        }
    }

    @Test("All reference points lie within the normalised 0–1 coordinate space",
          arguments: allLetters)
    func strokePointsNormalized(letter: Character) {
        let templates = StrokeTemplate.templates(for: letter)
        let tolerance = 0.01
        for template in templates {
            for point in template.points {
                #expect(
                    Double(point.x) >= -tolerance && Double(point.x) <= 1.0 + tolerance,
                    "Letter \(letter) stroke \(template.strokeIndex): x=\(point.x) is out of [0,1]"
                )
                #expect(
                    Double(point.y) >= -tolerance && Double(point.y) <= 1.0 + tolerance,
                    "Letter \(letter) stroke \(template.strokeIndex): y=\(point.y) is out of [0,1]"
                )
            }
        }
    }

    @Test("Calling templates(for:) twice returns identical point sequences",
          arguments: allLetters)
    func templateIsDeterministic(letter: Character) {
        let first  = StrokeTemplate.templates(for: letter).map(\.points)
        let second = StrokeTemplate.templates(for: letter).map(\.points)
        #expect(first == second, "Letter \(letter) templates are non-deterministic")
    }

    @Test("Every stroke has a unique id within its letter",
          arguments: allLetters)
    func strokeIdsAreUnique(letter: Character) {
        let templates = StrokeTemplate.templates(for: letter)
        let ids = templates.map(\.id)
        #expect(Set(ids).count == ids.count, "Letter \(letter) has duplicate stroke ids")
    }
}

// MARK: - Pedagogical correctness (stroke count and direction per letter)
//
// Failures here indicate either a missing template implementation (letter still uses
// the single-stroke fallback) or an incorrect direction classification.

struct StrokeTemplateCorrectnessTests {

    @Test("Each letter has the correct number of strokes",
          arguments: allLetters)
    func strokeCount(letter: Character) throws {
        let spec = try #require(
            letterSpec[letter],
            "No pedagogical spec defined for letter \(letter)"
        )
        let templates = StrokeTemplate.templates(for: letter)
        #expect(
            templates.count == spec.strokes,
            "Letter \(letter): expected \(spec.strokes) stroke(s), got \(templates.count)"
        )
    }

    @Test("Each stroke has the correct expected direction",
          arguments: allLetters)
    func strokeDirections(letter: Character) throws {
        let spec = try #require(letterSpec[letter])
        let templates = StrokeTemplate.templates(for: letter)

        guard templates.count == spec.strokes else {
            // Stroke-count failure already captured by strokeCount test; skip directions.
            return
        }

        for (index, (template, expected)) in zip(templates, spec.directions).enumerated() {
            #expect(
                template.direction == expected,
                "Letter \(letter) stroke \(index): expected \(expected), got \(template.direction)"
            )
        }
    }

    @Test("No letter that requires multiple strokes still uses the single-stroke fallback",
          arguments: allLetters)
    func noSpuriousFallback(letter: Character) throws {
        let spec = try #require(letterSpec[letter])
        guard spec.strokes > 1 else { return }
        let templates = StrokeTemplate.templates(for: letter)
        #expect(
            templates.count > 1,
            "Letter \(letter) should have \(spec.strokes) strokes but uses the single-stroke fallback"
        )
    }

    @Test("Single-stroke letters return exactly one template",
          arguments: allLetters.filter { letterSpec[$0]?.strokes == 1 })
    func singleStrokeLetterHasOneTemplate(letter: Character) {
        #expect(StrokeTemplate.templates(for: letter).count == 1)
    }
}

// MARK: - Specific letter shape sanity checks

struct StrokeTemplateShapeTests {

    // Vertical strokes must start near the top (y ≤ 0.2) and end near the bottom (y ≥ 0.8).
    @Test("I's vertical stroke spans the full height of the letter area")
    func verticalStrokeSpansFullHeight() throws {
        let templates = StrokeTemplate.templates(for: "I")
        try #require(!templates.isEmpty)
        let ys = templates[0].points.map(\.y)
        #expect(ys.min()! <= 0.2, "Top of I's vertical stroke is too low: \(ys.min()!)")
        #expect(ys.max()! >= 0.8, "Bottom of I's vertical stroke is too high: \(ys.max()!)")
    }

    // The O template must form a closed (or near-closed) arc.
    @Test("O's circle template starts and ends at approximately the same point")
    func circleIsNearClosed() throws {
        let templates = StrokeTemplate.templates(for: "O")
        try #require(!templates.isEmpty)
        let pts = templates[0].points
        try #require(pts.count >= 2)
        let dx = abs(pts.first!.x - pts.last!.x)
        let dy = abs(pts.first!.y - pts.last!.y)
        #expect(dx < 0.15 && dy < 0.15, "O template is not closed: gap=(\(dx), \(dy))")
    }

    // A's crossbar must be oriented horizontally (small y variance, larger x span).
    @Test("A's crossbar stroke is roughly horizontal")
    func crossbarIsHorizontal() throws {
        let templates = StrokeTemplate.templates(for: "A")
        try #require(templates.count == 3)
        let crossbar = templates[2].points
        let ys = crossbar.map(\.y)
        let xs = crossbar.map(\.x)
        let yRange = ys.max()! - ys.min()!
        let xRange = xs.max()! - xs.min()!
        #expect(xRange > yRange * 2, "A crossbar is not horizontal: xRange=\(xRange) yRange=\(yRange)")
    }

    // T's horizontal stroke must come first (strokeIndex 0) per standard print order.
    @Test("T's first stroke (index 0) is the horizontal bar")
    func tHorizontalBarIsFirst() throws {
        let templates = StrokeTemplate.templates(for: "T")
        try #require(templates.count == 2)
        let horizontal = templates[0]
        #expect(horizontal.direction == .leftToRight)
        let ys = horizontal.points.map(\.y)
        #expect(ys.max()! - ys.min()! < 0.1, "T's first stroke is not horizontal")
    }

    // V's two legs must converge at the bottom (the lowest points of each stroke should be close).
    @Test("V's two legs converge near the bottom centre")
    func vLegsConvergeAtBottom() throws {
        let templates = StrokeTemplate.templates(for: "V")
        try #require(templates.count == 2)
        let leftLeg  = templates[0].points
        let rightLeg = templates[1].points
        let leftBottom  = leftLeg.max(by: { $0.y < $1.y })!
        let rightBottom = rightLeg.max(by: { $0.y < $1.y })!
        let distance = hypot(leftBottom.x - rightBottom.x, leftBottom.y - rightBottom.y)
        #expect(distance < 0.4, "V legs don't converge: bottom gap = \(distance)")
    }

    // E's three horizontal bars each extend from the left edge (where they meet the vertical).
    @Test("E's three horizontal bars start at the left edge")
    func eHorizontalBarsStartAtLeftEdge() throws {
        let templates = StrokeTemplate.templates(for: "E")
        try #require(templates.count == 4)
        // Strokes 1, 2, 3 are the horizontal bars.
        for i in 1...3 {
            let bar = templates[i].points
            let xs = bar.map(\.x)
            #expect(xs.min()! <= 0.15,
                    "E stroke \(i) doesn't start at the left edge: min x=\(xs.min()!)")
        }
    }
}
