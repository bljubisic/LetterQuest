import Foundation
import SwiftUI
import RxSwift
import RxRelay

final class AppRouter: ObservableObject {

    @Published var path = NavigationPath()

    private let routeRelay = PublishRelay<AppRoute>()
    private let disposeBag = DisposeBag()

    init() {
        routeRelay
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] route in
                self?.path.append(route)
            })
            .disposed(by: disposeBag)
    }

    func push(_ route: AppRoute) {
        routeRelay.accept(route)
    }

    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    func popToRoot() {
        path = NavigationPath()
    }
}
