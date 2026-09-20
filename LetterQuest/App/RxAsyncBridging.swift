import Foundation
import RxSwift

// MARK: - Async bridging
//
// Small, self-contained Single/Completable → async bridges so callers don't
// depend on a specific RxSwift version's own concurrency bridging. Shared by
// `ScreenshotDemo` and `E2ETestSupport`, which both need to seed repository
// data from an `async` launch-time hook.

func awaitSingle<T>(_ single: Single<T>) async -> T? {
    await withCheckedContinuation { continuation in
        var didResume = false
        _ = single.subscribe(
            onSuccess: { value in
                guard !didResume else { return }
                didResume = true
                continuation.resume(returning: value)
            },
            onFailure: { _ in
                guard !didResume else { return }
                didResume = true
                continuation.resume(returning: nil)
            }
        )
    }
}

func awaitCompletable(_ completable: Completable) async {
    await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
        var didResume = false
        _ = completable.subscribe(
            onCompleted: {
                guard !didResume else { return }
                didResume = true
                continuation.resume()
            },
            onError: { _ in
                guard !didResume else { return }
                didResume = true
                continuation.resume()
            }
        )
    }
}
