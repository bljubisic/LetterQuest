import SwiftUI

/// The full progress and achievements screen reached via the home toolbar.
///
/// Shows a summary header, three achievement badges, and a per-letter list
/// with best score, attempt count, and first-completion date.
///
/// Named `ProgressScreen` (not `ProgressView`) to avoid shadowing
/// SwiftUI's built-in `ProgressView` loading indicator.
struct ProgressScreen<VM: ProgressViewModelProtocol>: View {

    @ObservedObject var viewModel: VM

    var body: some View {
        List {
            summarySection
            badgesSection
            lettersSection
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Progress")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Picker(
                    "Letters",
                    selection: Binding(
                        get: { viewModel.selectedCase },
                        set: { viewModel.selectCase($0) }
                    )
                ) {
                    Text("ABC").tag(LetterCase.upper)
                    Text("abc").tag(LetterCase.lower)
                }
                .pickerStyle(.segmented)
                .frame(width: 150)
            }
        }
        .overlay {
            if viewModel.isLoading {
                SwiftUI.ProgressView()
                    .scaleEffect(1.5)
            }
        }
    }

    // MARK: - Sections

    private var summarySection: some View {
        Section {
            VStack(spacing: 12) {
                Text("\(viewModel.completedCount) / \(viewModel.totalCount)")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.accentColor)

                Text("letters completed")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                ProgressView(
                    value: Double(viewModel.completedCount),
                    total: Double(viewModel.totalCount)
                )
                .tint(viewModel.completedCount == viewModel.totalCount ? .green : .accentColor)
                .padding(.horizontal)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .listRowBackground(Color.clear)
        .listRowInsets(.init())
    }

    private var badgesSection: some View {
        Section("Achievements") {
            HStack(spacing: 12) {
                ForEach(viewModel.badges) { badge in
                    BadgeTile(badge: badge)
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var lettersSection: some View {
        Section("Letters") {
            ForEach(viewModel.letters) { letter in
                LetterProgressRow(
                    letter:   letter,
                    progress: viewModel.progressMap[letter.id]
                )
            }
        }
    }
}

// MARK: - Badge tile

private struct BadgeTile: View {

    let badge: AchievementBadge

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(badge.isEarned ? Color.accentColor : Color.secondary.opacity(0.15))
                    .frame(width: 56, height: 56)

                Image(systemName: badge.systemImage)
                    .font(.title2)
                    .foregroundStyle(badge.isEarned ? .white : Color.secondary.opacity(0.4))
            }

            Text(badge.title)
                .font(.caption2.weight(.medium))
                .multilineTextAlignment(.center)
                .foregroundStyle(badge.isEarned ? .primary : .secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
        .opacity(badge.isEarned ? 1 : 0.6)
    }
}

// MARK: - Per-letter row

private struct LetterProgressRow: View {

    let letter:   Letter
    let progress: ChildProgress?

    var body: some View {
        HStack(spacing: 14) {
            // Character glyph
            Text(String(letter.character))
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundStyle(statusColor)
                .frame(width: 48, alignment: .center)

            // Detail text
            VStack(alignment: .leading, spacing: 3) {
                Text(statusLabel)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(statusColor)

                if let progress {
                    Text("\(progress.attempts.count) attempt\(progress.attempts.count == 1 ? "" : "s")  ·  Best \(progress.bestScore)%")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if progress.isCompleted, let date = firstCompletionDate {
                        Text("Completed \(date, format: .dateTime.day().month().year())")
                            .font(.caption2)
                            .foregroundStyle(.green)
                    }
                }
            }

            Spacer()

            // Score ring or lock icon
            if let progress {
                scoreRing(score: progress.bestScore)
            } else {
                Image(systemName: "lock.fill")
                    .foregroundStyle(.tertiary)
                    .font(.title3)
            }
        }
        .padding(.vertical, 2)
    }

    // MARK: - Helpers

    private var statusLabel: String {
        guard let progress else { return letter.character == "A" ? "Not started" : "Locked" }
        if progress.isCompleted { return "Completed ⭐" }
        return progress.attempts.isEmpty ? "Not started" : "In progress"
    }

    private var statusColor: Color {
        guard let progress else { return .secondary }
        if progress.isCompleted { return .green }
        return progress.attempts.isEmpty ? .secondary : .accentColor
    }

    private var firstCompletionDate: Date? {
        progress?.attempts.first { $0.score >= 75 }?.timestamp
    }

    private func scoreRing(score: Int) -> some View {
        ZStack {
            Circle()
                .stroke(statusColor.opacity(0.2), lineWidth: 4)
            Circle()
                .trim(from: 0, to: CGFloat(score) / 100)
                .stroke(statusColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(score)")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(statusColor)
        }
        .frame(width: 40, height: 40)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ProgressScreen(viewModel: PreviewProgressViewModel())
    }
}

private final class PreviewProgressViewModel: ProgressViewModelProtocol {
    let letters      = Letter.alphabet
    let totalCount   = 26
    let isLoading    = false
    let completedCount = 3
    let selectedCase: LetterCase = .upper
    func selectCase(_ letterCase: LetterCase) {}
    let progressMap: [UUID: ChildProgress] = {
        let completed = Letter.alphabet.prefix(3).map { letter in
            ChildProgress(
                letterId:    letter.id,
                attempts:    [
                    .init(timestamp: Date().addingTimeInterval(-86400), score: 60),
                    .init(timestamp: Date(), score: 82)
                ],
                bestScore:   82,
                isUnlocked:  true,
                isCompleted: true
            )
        }
        return Dictionary(uniqueKeysWithValues: completed.map { ($0.letterId, $0) })
    }()
    let badges = [
        AchievementBadge(id: "first_letter", title: "First Letter!",      systemImage: "star.fill",                isEarned: true),
        AchievementBadge(id: "halfway",       title: "Halfway There!",     systemImage: "star.leadinghalf.filled",  isEarned: false),
        AchievementBadge(id: "champion",      title: "Alphabet Champion!", systemImage: "trophy.fill",              isEarned: false)
    ]
}
