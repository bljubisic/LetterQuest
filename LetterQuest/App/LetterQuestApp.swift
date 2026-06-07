import SwiftUI

/// Application entry point.
///
/// Constructs the shared service layer once and passes dependencies down to each
/// screen via constructor injection. No singletons or service locators are used.
///
/// **Dependency graph:**
/// ```
/// AppRouter  ──────────────────────────┐
/// LetterRepository ────────────────────┤─► HomeViewModel     ─► HomeView
/// ProgressRepository ─────────────────┘
///
/// AppRouter  ──────────────────────────┐
/// LetterRepository ────────────────────┤─► PracticeViewModel ─► PracticeView
/// ProgressRepository ──────────────────┤
/// HandwritingAssessor ─────────────────┘
/// ```
@main
struct LetterQuestApp: App {

    @StateObject private var router = AppRouter()

    // Shared service instances — one per app lifetime.
    private let letterRepository:   LetterRepositoryProtocol   = LetterRepository()
    private let progressRepository: ProgressRepositoryProtocol = ProgressRepository()
    private let assessor:           HandwritingAssessing        = HandwritingAssessor()

    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $router.path) {
                HomeView(viewModel: makeHomeViewModel())
                    .navigationDestination(for: AppRoute.self) { route in
                        destination(for: route)
                    }
            }
            .environmentObject(router)
        }
    }

    // MARK: - Route → destination mapping

    /// Maps each `AppRoute` case to its corresponding view.
    ///
    /// New screens should be added here alongside their route case in `AppRoute`.
    @ViewBuilder
    private func destination(for route: AppRoute) -> some View {
        switch route {
        case .home:
            HomeView(viewModel: makeHomeViewModel())

        case .practice(let letterId):
            PracticeView(viewModel: PracticeViewModel(
                letterId:           letterId,
                letterRepository:   letterRepository,
                progressRepository: progressRepository,
                assessor:           assessor,
                router:             router
            ))

        case .progress:
            Text("Progress — coming soon")
                .font(.largeTitle)

        case .celebration(_, _):
            CelebrationView(onContinue: router.popToRoot)
        }
    }

    // MARK: - Factory helpers

    private func makeHomeViewModel() -> HomeViewModel {
        HomeViewModel(
            letterRepository:   letterRepository,
            progressRepository: progressRepository,
            router:             router
        )
    }
}
