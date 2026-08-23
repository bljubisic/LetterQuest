import Foundation
import RxSwift

/// Drives `ProgressScreen` by loading all letters and progress, then
/// deriving the summary counts and achievement badges.
final class ProgressViewModel: ProgressViewModelProtocol {

    // MARK: - ProgressViewModelProtocol

    @Published private(set) var letters:        [Letter]                = []
    @Published private(set) var progressMap:    [UUID: ChildProgress]   = [:]
    @Published private(set) var completedCount: Int                     = 0
    @Published private(set) var badges:         [AchievementBadge]      = []
    @Published private(set) var isLoading:      Bool                    = false
    let totalCount = 26

    // MARK: - Private

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
            let map           = Dictionary(uniqueKeysWithValues: progressList.map { ($0.letterId, $0) })
            let completed     = progressList.filter { $0.isCompleted }.count
            self.isLoading    = false
            self.letters      = letters
            self.progressMap  = map
            self.completedCount = completed
            self.badges       = Self.makeBadges(completedCount: completed)
        })
        .disposed(by: disposeBag)
    }

    private static func makeBadges(completedCount: Int) -> [AchievementBadge] {
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
}
