import Foundation

/// The contract that `OnboardingView` depends on.
///
/// `OnboardingView` is generic over this protocol so the real `OnboardingViewModel`
/// and a preview/test mock are interchangeable at compile time.
protocol OnboardingViewModelProtocol: ObservableObject {

    /// `true` while the onboarding cover should be visible.
    ///
    /// Starts `true` on first launch; becomes `false` after `complete()` is called.
    /// Can return to `true` if `resetOnboarding()` is called from Settings.
    var showOnboarding: Bool { get }

    /// Marks onboarding as complete and dismisses the cover.
    func complete()

    /// Clears the completion flag so onboarding is shown again on the next launch.
    ///
    /// Intended for a future Settings screen that lets a parent replay the tutorial.
    func resetOnboarding()
}
