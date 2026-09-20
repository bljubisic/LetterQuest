import SwiftUI

/// Application entry point.
///
/// Constructs the shared service layer once and passes dependencies down to each
/// screen via constructor injection. No singletons or service locators are used.
///
/// **Dependency graph:**
/// ```
/// (UserDefaults) ───────────────────────► OnboardingViewModel ─► OnboardingView
///
/// AppRouter  ──────────────────────────┐
/// AlphabetRepository ───────────────────┤
/// ProgressRepository ───────────────────┤
/// SettingsRepository ───────────────────┤─► HomeViewModel     ─► HomeView
/// WordRepository ───────────────────────┤    (letters + words, bottom-tabbed)
/// WordProgressRepository ─────────────┘
///
/// AppRouter  ──────────────────────────┐
/// LetterRepository ────────────────────┘─► LearnViewModel    ─► LearnView
///
/// AppRouter  ──────────────────────────┐
/// LetterRepository ────────────────────┤─► PracticeViewModel ─► PracticeView
/// ProgressRepository ──────────────────┤
/// HandwritingAssessor ─────────────────┘
///
/// AlphabetRepository ───────────────────┐
/// ProgressRepository ───────────────────┤
/// SettingsRepository ───────────────────┤─► ProgressViewModel ─► ProgressScreen
/// WordRepository ───────────────────────┤    (letters + words)
/// WordProgressRepository ─────────────┘
///
/// AppRouter  ──────────────────────────┐
/// WordRepository ───────────────────────┤
/// LetterRepository ─────────────────────┤
/// ProgressRepository ───────────────────┤─► WordPracticeViewModel ─► WordPracticeView
/// WordProgressRepository ───────────────┤    (builds a PracticeViewModel per letter)
/// HandwritingAssessor ──────────────────┘
///
/// SoundService  ─────────────────────────┐
/// HapticsService  ────────────────────────┤
/// SettingsRepository ─────────────────────┤─► SettingsViewModel ─► SettingsView
/// ProgressRepository ─────────────────────┤
/// WordProgressRepository ─────────────────┘
///
/// AlphabetRepository ─────────────────────┐
/// PurchaseService ─────────────────────────┤─► AlphabetStoreViewModel ─► AlphabetStoreView
/// AppRouter  ──────────────────────────────┤
/// entitlementProvider ─────────────────────┘
///
/// AppRouter  ──────────────────────────┐
/// AlphabetRepository ───────────────────┤─► SwitchAlphabetViewModel ─► SwitchAlphabetView
/// SettingsRepository ──────────────────┘
/// ```
@main
struct LetterQuestApp: App {

    @StateObject private var router             = AppRouter()
    @StateObject private var onboardingViewModel = OnboardingViewModel()

    /// Gates the real UI until startup finishes: entitlements are always
    /// refreshed from StoreKit first (see `entitlementProvider`), and
    /// `ScreenshotDemo`/`E2ETestSupport` seeding also needs to complete
    /// before `HomeViewModel`/`ProgressViewModel`/etc. read progress data.
    @State private var isReadyToShowContent = false

    // Shared service instances — one per app lifetime.
    private let progressRepository:     ProgressRepositoryProtocol     = ProgressRepository()
    private let assessor:               HandwritingAssessing
    private let soundService:           SoundServiceProtocol           = SoundService()
    private let hapticsService:         HapticsServiceProtocol         = HapticsService()
    private let wordRepository:         WordRepositoryProtocol         = WordRepository()
    private let wordProgressRepository: WordProgressRepositoryProtocol = WordProgressRepository()
    private let settingsRepository:     SettingsRepositoryProtocol
    private let purchaseService:        PurchaseServiceProtocol
    private let entitlementProvider:    AlphabetEntitlementProviding
    private let alphabetRepository:     AlphabetRepositoryProtocol
    private let letterRepository:       LetterRepositoryProtocol

    // `assessor` reads the current difficulty from `settingsRepository` and
    // needs `letterRepository`'s real entitlement-aware letter set for its
    // recognition gate (not a disconnected default) — and `letterRepository`
    // needs `alphabetRepository` needs `entitlementProvider` needs
    // `purchaseService`. None of these chains can be independent inline
    // property defaults, hence the explicit init. Every other property above
    // keeps its own inline default; only these need to be assigned here.
    init() {
        let settingsRepository = SettingsRepository()
        self.settingsRepository = settingsRepository

        let purchaseService = StoreKitPurchaseService()
        self.purchaseService = purchaseService
        // E2E/screenshot runs must be deterministically Latin-only regardless
        // of whatever real StoreKit test purchases happen to already be
        // present in the simulator's local purchase history (e.g. left over
        // from manually testing the Alphabet Store) — otherwise a UI test
        // written against the single-alphabet Home layout starts seeing the
        // multi-alphabet picker instead, with no way for the test itself to
        // control or reset that state.
        let entitlementProvider: AlphabetEntitlementProviding =
            (E2ETestSupport.isEnabled || ScreenshotDemo.isEnabled)
            ? StubAlphabetEntitlementProvider()
            : StoreKitAlphabetEntitlementProvider(purchaseService: purchaseService)
        self.entitlementProvider = entitlementProvider
        let alphabetRepository = AlphabetRepository(entitlementProvider: entitlementProvider)
        self.alphabetRepository = alphabetRepository
        let letterRepository = LetterRepository(alphabetRepository: alphabetRepository)
        self.letterRepository = letterRepository

        self.assessor = HandwritingAssessor(settingsRepository: settingsRepository, letterRepository: letterRepository)
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if isReadyToShowContent {
                    NavigationStack(path: $router.path) {
                        HomeView(viewModel: makeHomeViewModel())
                            .navigationDestination(for: AppRoute.self) { route in
                                destination(for: route)
                            }
                    }
                    .environmentObject(router)
                    .fullScreenCover(isPresented: Binding(
                        get: { onboardingViewModel.showOnboarding },
                        set: { _ in }
                    )) {
                        OnboardingView(viewModel: onboardingViewModel)
                    }
                    // Gates every `AppRoute.requiresParentalGate` route
                    // (currently just the Alphabet Store) before it's ever
                    // pushed, regardless of which screen requested it — see
                    // `AppRouter.push(_:)`. Root-level so it can't be missed
                    // by a future entry point the way per-view gating was.
                    .sheet(item: $router.pendingGateRoute) { _ in
                        ParentalGateView(
                            onSuccess: router.confirmPendingGate,
                            onCancel: router.cancelPendingGate
                        )
                    }
                } else {
                    Color(uiColor: .systemBackground).ignoresSafeArea()
                }
            }
            .task {
                // Always primed first, so the very first `LetterRepository`/
                // `AlphabetRepository` read already reflects real StoreKit
                // entitlements — never a flash of "locked" that unlocks a
                // moment later.
                await awaitCompletable(entitlementProvider.refresh())

                if ScreenshotDemo.isEnabled {
                    onboardingViewModel.complete()
                    await ScreenshotDemo.run(
                        letterRepository:       letterRepository,
                        wordRepository:         wordRepository,
                        progressRepository:     progressRepository,
                        wordProgressRepository: wordProgressRepository,
                        router:                 router
                    )
                } else if E2ETestSupport.isEnabled {
                    await E2ETestSupport.run(
                        letterRepository:       letterRepository,
                        progressRepository:     progressRepository,
                        wordProgressRepository: wordProgressRepository,
                        onboardingViewModel:    onboardingViewModel
                    )
                }
                isReadyToShowContent = true
            }
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
            let overrides = practiceDemoOverrides
            PracticeView(viewModel: PracticeViewModel(
                letterId:           letterId,
                letterRepository:   letterRepository,
                progressRepository: progressRepository,
                assessor:           assessor,
                soundService:       soundService,
                hapticsService:     hapticsService,
                router:             router,
                previewResult:           overrides.previewResult,
                previewShowsCelebration: overrides.previewShowsCelebration,
                injectedResult:          overrides.injectedResult
            ))
            // Force a fully fresh view tree (including the PencilKit canvas)
            // when navigating from one letter to another.
            .id(letterId)

        case .learn(let letterId):
            LearnView(viewModel: LearnViewModel(
                letterId:         letterId,
                letterRepository: letterRepository,
                router:           router
            ))
            .id(letterId)

        case .progress:
            ProgressScreen(viewModel: ProgressViewModel(
                alphabetRepository:     alphabetRepository,
                progressRepository:     progressRepository,
                settingsRepository:     settingsRepository,
                wordRepository:         wordRepository,
                wordProgressRepository: wordProgressRepository
            ))

        case .celebration(_, _):
            CelebrationView(onContinue: router.popToRoot)

        case .word(let wordId):
            WordPracticeView(viewModel: WordPracticeViewModel(
                wordId:                 wordId,
                wordRepository:         wordRepository,
                letterRepository:       letterRepository,
                progressRepository:     progressRepository,
                wordProgressRepository: wordProgressRepository,
                assessor:               assessor,
                soundService:           soundService,
                hapticsService:         hapticsService,
                router:                 router
            ))
            .id(wordId)

        case .settings:
            SettingsView(viewModel: SettingsViewModel(
                soundService:           soundService,
                hapticsService:         hapticsService,
                settingsRepository:     settingsRepository,
                progressRepository:     progressRepository,
                wordProgressRepository: wordProgressRepository
            ))

        case .alphabetStore:
            AlphabetStoreView(viewModel: AlphabetStoreViewModel(
                alphabetRepository:  alphabetRepository,
                purchaseService:     purchaseService,
                entitlementProvider: entitlementProvider,
                router:              router
            ))

        case .switchAlphabet:
            SwitchAlphabetView(viewModel: SwitchAlphabetViewModel(
                alphabetRepository: alphabetRepository,
                settingsRepository: settingsRepository,
                router:             router
            ))
        }
    }

    // MARK: - Screenshot/E2E-test support

    /// Screenshot/E2E-test only. Returns the demo values to feed into a
    /// freshly constructed `PracticeViewModel` for the `.practice` route, or
    /// all-`nil`/`false` on a normal launch. See `ScreenshotDemo` and
    /// `E2ETestSupport`, and `PracticeViewModel.init(previewResult:previewShowsCelebration:injectedResult:)`
    /// for what each one does.
    private var practiceDemoOverrides: (
        previewResult: AssessmentResult?,
        previewShowsCelebration: Bool,
        injectedResult: AssessmentResult?
    ) {
        if ScreenshotDemo.isEnabled {
            switch ScreenshotDemo.route {
            case .score:       return (ScreenshotDemo.previewAssessmentResult, false, nil)
            case .celebration: return (ScreenshotDemo.previewAssessmentResult, true, nil)
            default:           return (nil, false, nil)
            }
        }
        if E2ETestSupport.isEnabled && E2ETestSupport.autoPass {
            return (nil, false, E2ETestSupport.passingResult)
        }
        return (nil, false, nil)
    }

    // MARK: - Factory helpers

    private func makeHomeViewModel() -> HomeViewModel {
        HomeViewModel(
            alphabetRepository:     alphabetRepository,
            progressRepository:     progressRepository,
            settingsRepository:     settingsRepository,
            wordRepository:         wordRepository,
            wordProgressRepository: wordProgressRepository,
            router:                 router
        )
    }
}
