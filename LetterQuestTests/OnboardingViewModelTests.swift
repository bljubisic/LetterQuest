import Testing
import Foundation
@testable import LetterQuest

// MARK: - Helpers

/// Creates an isolated UserDefaults suite so tests never touch .standard.
private func makeSuite(name: String = #function) -> UserDefaults {
    let suite = UserDefaults(suiteName: name)!
    suite.removePersistentDomain(forName: name)
    return suite
}

// MARK: - Tests

struct OnboardingViewModelTests {

    @Test("showOnboarding is true on first launch")
    func showOnboardingIsTrueOnFirstLaunch() {
        let vm = OnboardingViewModel(userDefaults: makeSuite())
        #expect(vm.showOnboarding == true)
    }

    @Test("showOnboarding is false after complete()")
    func showOnboardingIsFalseAfterComplete() {
        let vm = OnboardingViewModel(userDefaults: makeSuite())
        vm.complete()
        #expect(vm.showOnboarding == false)
    }

    @Test("completion flag persists across ViewModel instances")
    func completePersistsAcrossInstances() {
        let suite = makeSuite()
        let first = OnboardingViewModel(userDefaults: suite)
        first.complete()

        let second = OnboardingViewModel(userDefaults: suite)
        #expect(second.showOnboarding == false)
    }

    @Test("resetOnboarding() shows onboarding again")
    func resetOnboardingShowsOnboardingAgain() {
        let vm = OnboardingViewModel(userDefaults: makeSuite())
        vm.complete()
        vm.resetOnboarding()
        #expect(vm.showOnboarding == true)
    }

    @Test("reset clears the persisted flag for the next launch")
    func resetClearsFlagForNextLaunch() {
        let suite = makeSuite()
        let first = OnboardingViewModel(userDefaults: suite)
        first.complete()
        first.resetOnboarding()

        let second = OnboardingViewModel(userDefaults: suite)
        #expect(second.showOnboarding == true)
    }
}
