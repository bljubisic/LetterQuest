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

    /// Pushes a new route onto the navigation stack.
    ///
    /// - Parameter route: The destination to navigate to.
    func push(_ route: AppRoute) {
        routeRelay.accept(route)
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
}
