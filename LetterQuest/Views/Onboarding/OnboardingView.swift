import SwiftUI

/// The first-launch tutorial shown as a `.fullScreenCover` over `HomeView`.
///
/// Four swipeable pages introduce the app to a parent and child together.
/// Every page has a Skip button; the final page has a "Let's go!" button.
/// Both paths call `viewModel.complete()`, which persists the flag and
/// causes the cover to dismiss reactively.
///
/// Generic over `VM: OnboardingViewModelProtocol` for preview/test flexibility.
struct OnboardingView<VM: OnboardingViewModelProtocol>: View {

    @ObservedObject var viewModel: VM
    @State private var currentPage = 0

    private let pages = OnboardingPage.allCases

    var body: some View {
        ZStack(alignment: .topTrailing) {
            TabView(selection: $currentPage) {
                ForEach(pages) { page in
                    OnboardingPageView(page: page, isLastPage: page == pages.last) {
                        viewModel.complete()
                    }
                    .tag(page.rawValue)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            Button("Skip") {
                viewModel.complete()
            }
            .font(.body.weight(.medium))
            .padding()
        }
        .background(Color(uiColor: .systemBackground))
    }
}

// MARK: - Page model

private enum OnboardingPage: Int, CaseIterable, Identifiable {
    case welcome    = 0
    case guidelines = 1
    case scoring    = 2
    case letsGo     = 3

    var id: Int { rawValue }

    var systemImage: String {
        switch self {
        case .welcome:    return "hand.draw"
        case .guidelines: return "ruler"
        case .scoring:    return "star.fill"
        case .letsGo:     return "pencil.tip"
        }
    }

    var title: String {
        switch self {
        case .welcome:    return "Welcome to LetterQuest"
        case .guidelines: return "Follow the Lines"
        case .scoring:    return "Earn Your Stars"
        case .letsGo:     return "Ready to Write?"
        }
    }

    var body: String {
        switch self {
        case .welcome:
            return "Learn to write all 26 letters — one stroke at a time!"
        case .guidelines:
            return "Four guide lines show where each part of the letter belongs. Start at the numbered dot and follow the strokes."
        case .scoring:
            return "After you draw, we check stroke order, shape, proportions, and smoothness. Tips help you improve every try."
        case .letsGo:
            return "Tap any letter to begin. Watch the demo first, then give it a try!"
        }
    }
}

// MARK: - Per-page layout

private struct OnboardingPageView: View {

    let page: OnboardingPage
    let isLastPage: Bool
    let onComplete: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: page.systemImage)
                .font(.system(size: 80, weight: .light))
                .foregroundStyle(Color.accentColor)
                .padding(32)
                .background(
                    Circle()
                        .fill(Color.accentColor.opacity(0.10))
                )

            VStack(spacing: 12) {
                Text(page.title)
                    .font(.title.bold())
                    .multilineTextAlignment(.center)

                Text(page.body)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            if isLastPage {
                Button {
                    onComplete()
                } label: {
                    Label("Let's go!", systemImage: "arrow.right")
                        .font(.title3.bold())
                        .frame(maxWidth: 280)
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 8)
            }

            Spacer()
            Spacer()
        }
        .padding(.horizontal)
    }
}

// MARK: - Preview

#Preview {
    OnboardingView(viewModel: PreviewOnboardingViewModel())
}

private final class PreviewOnboardingViewModel: OnboardingViewModelProtocol {
    @Published var showOnboarding = true
    func complete() { showOnboarding = false }
    func resetOnboarding() { showOnboarding = true }
}
