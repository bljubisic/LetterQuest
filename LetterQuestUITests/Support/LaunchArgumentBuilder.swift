import Foundation

/// Fluent builder for the launch environment `E2ETestSupport` reads to seed
/// data and control app behavior for a single XCUITest launch. Keeps each
/// test's `app.launch()` call declarative instead of hand-building a
/// dictionary of magic string keys inline.
struct LaunchArgumentBuilder {

    private struct SeedPayload: Encodable {
        let character: String
        let isUpper: Bool
        let completed: Bool
        let score: Int
    }

    private var environment: [String: String] = ["LQ_E2E_TEST": "1"]
    private var seeds: [SeedPayload] = []

    /// Clears prior `ChildProgress`/`WordProgress`/onboarding state before
    /// this launch's seeding runs, so the test starts from a known slate
    /// regardless of what a previous run left behind.
    func resettingState() -> Self {
        var copy = self
        copy.environment["LQ_E2E_RESET"] = "1"
        return copy
    }

    /// Marks onboarding as already complete, so the app lands straight on Home.
    func skippingOnboarding() -> Self {
        var copy = self
        copy.environment["LQ_E2E_SKIP_ONBOARDING"] = "1"
        return copy
    }

    /// The next real "Check!" submission during this launch is substituted
    /// with a high passing score instead of running the real scorer.
    func autoPassing() -> Self {
        var copy = self
        copy.environment["LQ_E2E_AUTO_PASS"] = "1"
        return copy
    }

    /// Seeds one letter's `ChildProgress` state.
    func seedingLetter(_ character: Character, isUpper: Bool = true, completed: Bool, score: Int) -> Self {
        var copy = self
        copy.seeds.append(SeedPayload(character: String(character), isUpper: isUpper, completed: completed, score: score))
        return copy
    }

    /// Finalizes the environment, encoding any seeded letters into
    /// `LQ_E2E_SEED_JSON`. Pass the result to `XCUIApplication.launchEnvironment`.
    func build() -> [String: String] {
        var env = environment
        if !seeds.isEmpty,
           let data = try? JSONEncoder().encode(seeds),
           let json = String(data: data, encoding: .utf8) {
            env["LQ_E2E_SEED_JSON"] = json
        }
        return env
    }
}
