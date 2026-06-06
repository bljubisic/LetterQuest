import SwiftUI

struct HomeView: View {

    @ObservedObject var viewModel: HomeViewModel

    private let columns = [GridItem(.adaptive(minimum: 130), spacing: 16)]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(viewModel.letters) { letter in
                    LetterCard(
                        letter: letter,
                        progress: viewModel.progressMap[letter.id],
                        onTap: { viewModel.selectLetter(letter) }
                    )
                }
            }
            .padding()
        }
        .navigationTitle("Letter Quest ✏️")
        .overlay {
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
            }
        }
        .onAppear { viewModel.load() }
    }
}

// MARK: - Letter Card

struct LetterCard: View {

    let letter: Letter
    let progress: ChildProgress?
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 10) {
                Text(String(letter.character))
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .foregroundStyle(isUnlocked ? Color.accentColor : .gray)

                if let progress {
                    VStack(spacing: 4) {
                        ProgressView(value: Double(progress.bestScore), total: 100)
                            .tint(progress.isCompleted ? .green : .accentColor)
                            .padding(.horizontal, 8)

                        Text(progress.isCompleted ? "⭐ Done!" : "\(progress.bestScore)%")
                            .font(.caption.bold())
                            .foregroundStyle(progress.isCompleted ? .green : .secondary)
                    }
                } else {
                    Text(isUnlocked ? "Tap to start" : "🔒 Locked")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(isUnlocked ? 0.08 : 0), radius: 6, y: 3)
        }
        .disabled(!isUnlocked)
        .buttonStyle(.plain)
    }

    private var isUnlocked: Bool {
        progress?.isUnlocked ?? (letter.character == "A")
    }

    private var cardBackground: some ShapeStyle {
        isUnlocked ? AnyShapeStyle(Color.white) : AnyShapeStyle(Color.gray.opacity(0.08))
    }
}
