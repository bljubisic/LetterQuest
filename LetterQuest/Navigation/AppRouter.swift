import Foundation
import SwiftUI
import RxSwift
import RxRelay

/// Owns the `NavigationPath` that drives the app's `NavigationStack`.
///
/// View models interact with the router by calling `push(_:)`, `pop()`, or
/// `popToRoot()`. Internally, route pushes go through an `RxRelay` so that
/// view models can emit navigation events reactively without needing a direct
/// reference to `@Published` state.
///
/// `AppRouter` is injected as an `@StateObject` at the app level and passed
/// down to each view model at construction time.
final class AppRouter: ObservableObject {

    /// The current navigation stack. Bound directly to `NavigationStack(path:)`.
    @Published var path = NavigationPath()

    /// Set by `push(_:)` when the requested route needs a parental gate
    /// first. The app root shows `ParentalGateView` as a `.sheet(item:)`
    /// bound to this; a correct answer calls `confirmPendingGate()`, which
    /// actually performs the push. Living here (not in per-view `@State`)
    /// is what makes the gate un-bypassable — see `AppRoute.requiresParentalGate`.
    @Published var pendingGateRoute: AppRoute?

    private let routeRelay = PublishRelay<AppRoute>()
    private let disposeBag = DisposeBag()

    init() {
        // Observe route pushes on the main thread to keep @Published updates safe.
        routeRelay
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] route in
                self?.path.append(route)
            })
            .disposed(by: disposeBag)
    }

    // MARK: - Navigation actions

    /// Pushes a new route onto the navigation stack — unless it requires a
    /// parental gate, in which case the push is deferred until
    /// `confirmPendingGate()` is called after a correct answer.
    ///
    /// - Parameter route: The destination to navigate to.
    func push(_ route: AppRoute) {
        guard route.requiresParentalGate else {
            routeRelay.accept(route)
            return
        }
        pendingGateRoute = route
    }

    /// Performs the push that was deferred behind `pendingGateRoute`. Called
    /// by the parental gate sheet's `onSuccess`.
    func confirmPendingGate() {
        guard let route = pendingGateRoute else { return }
        pendingGateRoute = nil
        routeRelay.accept(route)
    }

    /// Discards the deferred push. Called by the parental gate sheet's `onCancel`.
    func cancelPendingGate() {
        pendingGateRoute = nil
    }

    /// Pops the top route from the stack, returning to the previous screen.
    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    /// Pops all routes and returns to the home screen.
    func popToRoot() {
        path = NavigationPath()
    }

    /// Replaces the entire navigation stack with a single route in one synchronous
    /// step. Use this when advancing between sibling screens (e.g. letter A's
    /// practice → letter B's practice) so the stack doesn't briefly flash an
    /// empty home screen, and the previous view is fully torn down.
    func replaceStack(with route: AppRoute) {
        var newPath = NavigationPath()
        newPath.append(route)
        path = newPath
    }
}
