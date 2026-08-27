import Foundation
import RxSwift

/// Drives `ProgressScreen` by loading all letters and progress, then
/// deriving the summary counts and achievement badges.
///
/// `selectedCase` controls which set (upper or lower) is shown in the letter
/// list and reflected in `completedCount`. Achievement badges are always
/// anchored to uppercase completion regardless of `selectedCase`.
final class ProgressViewModel: ProgressViewModelProtocol {

    // MARK: - ProgressViewModelProtocol

    /// Letters for the currently selected case.
    var letters: [Letter] { allLetters.filter { $0.letterCase == selectedCase } }

    @Published private(set) var progressMap: [UUID: ChildProgress] = [:]
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var selectedCase: LetterCase = .upper

    var totalCount: Int {
        switch selectedCase {
        case .digit: return 10
        default:     return 26
        }
    }

    var completedCount: Int {
        letters.filter { progressMap[$0.id]?.isCompleted == true }.count
    }

    var badges: [AchievementBadge] {
        let completed = completedCount
        switch selectedCase {
        case .digit:  return Self.makeDigitBadges(completedCount: completed)
        default:
            let uppercaseCompleted = allLetters
                .filter { $0.letterCase == .upper && progressMap[$0.id]?.isCompleted == true }
                .count
            return Self.makeLetterBadges(completedCount: uppercaseCompleted)
        }
    }

    // MARK: - Private

    @Published private var allLetters: [Letter] = []

    private let letterRepository:   LetterRepositoryProtocol
    private let progressRepository: ProgressRepositoryProtocol
    private let disposeBag = DisposeBag()

    // MARK: - Init

    init(
        letterRepository:   LetterRepositoryProtocol,
        progressRepository: ProgressRepositoryProtocol
    ) {
        self.letterRepository   = letterRepository
        self.progressRepository = progressRepository
        load()
    }

    // MARK: - ProgressViewModelProtocol inputs

    func selectCase(_ letterCase: LetterCase) {
        selectedCase = letterCase
    }

    // MARK: - Private helpers

    private func load() {
        isLoading = true
        Observable.zip(
            letterRepository.fetchAll().asObservable(),
            progressRepository.loadAll().asObservable()
        )
        .observe(on: MainScheduler.instance)
        .subscribe(onNext: { [weak self] letters, progressList in
            guard let self else { return }
            self.isLoading   = false
            self.allLetters  = letters
            self.progressMap = Dictionary(uniqueKeysWithValues: progressList.map { ($0.letterId, $0) })
        })
        .disposed(by: disposeBag)
    }

    private static func makeLetterBadges(completedCount: Int) -> [AchievementBadge] {
        [
            AchievementBadge(
                id:          "first_letter",
                title:       "First Letter!",
                systemImage: "star.fill",
                isEarned:    completedCount >= 1
            ),
            AchievementBadge(
                id:          "halfway",
                title:       "Halfway There!",
                systemImage: "star.leadinghalf.filled",
                isEarned:    completedCount >= 13
            ),
            AchievementBadge(
                id:          "champion",
                title:       "Alphabet Champion!",
                systemImage: "trophy.fill",
                isEarned:    completedCount == 26
            )
        ]
    }

    private static func makeDigitBadges(completedCount: Int) -> [AchievementBadge] {
        [
            AchievementBadge(
                id:          "first_number",
                title:       "First Number!",
                systemImage: "star.fill",
                isEarned:    completedCount >= 1
            ),
            AchievementBadge(
                id:          "halfway_numbers",
                title:       "Halfway There!",
                systemImage: "star.leadinghalf.filled",
                isEarned:    completedCount >= 5
            ),
            AchievementBadge(
                id:          "number_master",
                title:       "Number Master!",
                systemImage: "trophy.fill",
                isEarned:    completedCount == 10
            )
        ]
    }
}
