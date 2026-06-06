import Foundation
import UIKit

struct Letter: Identifiable, Equatable {
    let id: UUID
    let character: Character
    let strokeTemplates: [StrokeTemplate]
    let difficulty: Difficulty
    let templateImageName: String?

    var templateImage: CGImage? {
        guard let name = templateImageName else { return nil }
        return UIImage(named: name)?.cgImage
    }

    enum Difficulty: Int, CaseIterable {
        case easy = 1
        case medium = 2
        case hard = 3
    }

    static func == (lhs: Letter, rhs: Letter) -> Bool { lhs.id == rhs.id }
}

extension Letter {
    static let alphabet: [Letter] = "ABCDEFGHIJKLMNOPQRSTUVWXYZ".enumerated().map { index, char in
        Letter(
            id: UUID(),
            character: char,
            strokeTemplates: StrokeTemplate.templates(for: char),
            difficulty: index < 5 ? .easy : index < 15 ? .medium : .hard,
            templateImageName: "template_\(char)"
        )
    }
}
