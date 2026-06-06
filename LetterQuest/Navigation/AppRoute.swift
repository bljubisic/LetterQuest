import Foundation

enum AppRoute: Hashable {
    case home
    case practice(letterId: UUID)
    case progress
    case celebration(score: Int, letterId: UUID)
}
