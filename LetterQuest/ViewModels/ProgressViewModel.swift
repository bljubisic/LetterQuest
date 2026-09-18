import Foundation
import RxSwift

/// Drives `ProgressScreen` by loading the active alphabet and progress, then
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

    var totalCount: Int { letters.count }

    var completedCount: Int {
        letters.filter { progressMap[$0.id]?.isCompleted == true }.count
    }

    @Published private(set) var words: [Word] = []
    @Published private(set) var wordProgressMap: [UUID: WordProgress] = [:]

    var completedWordsCount: Int {
        words.filter { wordProgressMap[$0.id]?.isCompleted == true }.count
    }

    /// `true` once every uppercase and lowercase letter of the active
    /// alphabet has been completed — mirrors `HomeViewModel.isWordModeUnlocked`.
    var isWordSectionVisible: Bool {
        !allLetters.isEmpty && allLetters.allSatisfy { progressMap[$0.id]?.isCompleted == true }
    }

    var badges: [AchievementBadge] {
        let uppercaseLetters = allLetters.filter { $0.letterCase == .upper }
        let uppercaseCompleted = uppercaseLetters
            .filter { progressMap[$0.id]?.isCompleted == true }
            .count
        var badges = Self.makeLetterBadges(completedCount: uppercaseCompleted, totalCount: uppercaseLetters.count)
        badges.append(
            AchievementBadge(
                id:          "wordsmith",
                title:       "Wordsmith!",
                systemImage: "text.book.closed.fill",
                isEarned:    isWordSectionVisible && completedWordsCount == words.count && !words.isEmpty
            )
        )
        return badges
    }

    // MARK: - Private

    /// The active alphabet's letters — resolved the same way as
    /// `HomeViewModel`'s `activeAlphabet`, so Progress always reflects
    /// whichever alphabet Home is currently showing.
    @Published private var allLetters: [Letter] = []

    private let alphabetRepository: AlphabetRepositoryProtocol
    private let progressRepository: ProgressRepositoryProtocol
    private let settingsRepository: SettingsRepositoryProtocol
    private let wordRepository: WordRepositoryProtocol
    private let wordProgressRepository: WordProgressRepositoryProtocol
    private let disposeBag = DisposeBag()

    // MARK: - Init

    init(
        alphabetRepository: AlphabetRepositoryProtocol,
        progressRepository: ProgressRepositoryProtocol,
        settingsRepository: SettingsRepositoryProtocol,
        wordRepository: WordRepositoryProtocol,
        wordProgressRepository: WordProgressRepositoryProtocol
    ) {
        self.alphabetRepository     = alphabetRepository
        self.progressRepository     = progressRepository
        self.settingsRepository     = settingsRepository
        self.wordRepository         = wordRepository
        self.wordProgressRepository = wordProgressRepository
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
            alphabetRepository.fetchInstalled().asObservable(),
            progressRepository.loadAll().asObservable(),
            settingsRepository.load().asObservable(),
            wordRepository.fetchAll().asObservable(),
            wordProgressRepository.loadAll().asObservable()
        )
        .observe(on: MainScheduler.instance)
        .subscribe(onNext: { [weak self] alphabets, progressList, settings, words, wordProgressList in
            guard let self else { return }
            self.isLoading   = false
            let activeAlphabet = alphabets.first { $0.id == settings.activeAlphabetId } ?? alphabets.first
            self.allLetters  = activeAlphabet?.letters ?? []
            self.progressMap = Dictionary(uniqueKeysWithValues: progressList.map { ($0.letterId, $0) })
            self.words           = words.filter { $0.alphabetId == activeAlphabet?.id }
            self.wordProgressMap = Dictionary(uniqueKeysWithValues: wordProgressList.map { ($0.wordId, $0) })
        })
        .disposed(by: disposeBag)
    }

    private static func makeLetterBadges(completedCount: Int, totalCount: Int) -> [AchievementBadge] {
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
                isEarned:    completedCount >= (totalCount + 1) / 2
            ),
            AchievementBadge(
                id:          "champion",
                title:       "Alphabet Champion!",
                systemImage: "trophy.fill",
                isEarned:    totalCount > 0 && completedCount == totalCount
            )
        ]
    }
}
