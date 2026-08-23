import Foundation

/// Drives `OnboardingView` and persists the completion flag across launches.
///
/// Accepts a `UserDefaults` instance at init so unit tests can pass an isolated
/// suite without touching `.standard`.
final class OnboardingViewModel: OnboardingViewModelProtocol {

    // MARK: - OnboardingViewModelProtocol

    @Published private(set) var showOnboarding: Bool

    // MARK: - Private

    private static let completedKey = "letter_quest_onboarding_complete_v1"
    private let userDefaults: UserDefaults

    // MARK: - Init

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        // Show onboarding unless the flag has been set by a previous launch.
        showOnboarding = !userDefaults.bool(forKey: Self.completedKey)
    }

    // MARK: - OnboardingViewModelProtocol methods

    func complete() {
        userDefaults.set(true, forKey: Self.completedKey)
        showOnboarding = false
    }

    func resetOnboarding() {
        userDefaults.set(false, forKey: Self.completedKey)
        showOnboarding = true
    }
}
