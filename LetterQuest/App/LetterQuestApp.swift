import SwiftUI

@main
struct LetterQuestApp: App {

    private let router             = AppRouter()
    private let letterRepository   = LetterRepository()
    private let progressRepository = ProgressRepository()
    private let assessor           = HandwritingAssessor()

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

    @ViewBuilder
    private func destination(for route: AppRoute) -> some View {
        switch route {
        case .home:
            HomeView(viewModel: makeHomeViewModel())

        case .practice(let letterId):
            PracticeView(viewModel: PracticeViewModel(
                letterId: letterId,
                letterRepository: letterRepository,
                progressRepository: progressRepository,
                assessor: assessor,
                router: router
            ))

        case .progress:
            Text("Progress — coming soon")

        case .celebration(let score, _):
            CelebrationView(onContinue: router.popToRoot)
        }
    }

    private func makeHomeViewModel() -> HomeViewModel {
        HomeViewModel(
            letterRepository: letterRepository,
            progressRepository: progressRepository,
            router: router
        )
    }
}
