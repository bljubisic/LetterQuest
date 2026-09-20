# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

LetterQuest is a universal iPhone/iPad app that teaches children to write uppercase letters using finger or Apple Pencil. The child draws on a PencilKit canvas; a four-signal scoring pipeline evaluates the drawing and gives feedback.

- **Platform**: Universal — iPhone and iPad (iOS 17+), Swift 5.9 (main target), Swift 6.0 (test target)
- **Dependency manager**: Swift Package Manager (resolved inside the Xcode project)
- **External dependencies**: RxSwift 6.10.2 (RxSwift, RxCocoa, RxRelay) + RxBlocking (tests only)
- **Project file generator**: XcodeGen (`project.yml` → `LetterQuest.xcodeproj`)

## Build & Run

Open `LetterQuest.xcodeproj` in Xcode and run on an iPad simulator or device. There is no CLI build target; all building happens inside Xcode.

To regenerate the Xcode project after editing `project.yml`:

```bash
xcodegen generate
```

Tests use the Swift Testing framework (`import Testing`) with `@Test` and `#expect`. Run them in Xcode via Product → Test or ⌘U.

## Architecture

### Pattern: MVVM + Protocol-Oriented DI

Every layer exposes a protocol; concrete types are injected at construction time in `LetterQuestApp.swift`. No singletons or service locators are used.

```
LetterQuestApp (entry point)
  └── AppRouter          — @StateObject; owns NavigationPath; drives via PublishRelay<AppRoute>
  └── LetterRepository   — in-memory, returns Letter.alphabet as a Single
  └── ProgressRepository — UserDefaults-backed, JSON-encoded [UUID: ChildProgress]
  └── HandwritingAssessor — four-signal scoring pipeline (runs on .userInitiated QoS)
        ├── DTWMatcher          (35 %) — stroke path via Dynamic Time Warping
        ├── ShapeAnalyzer       (35 %) — bitmap IoU against a template CGImage
        ├── ProportionChecker   (20 %) — guideline geometry
        └── SmoothnessAnalyzer  (10 %) — angular jitter / speed variance
```

### Navigation

`AppRoute` (enum, `Hashable`) defines four screens:

```swift
case home                                  // letter-grid
case practice(letterId: UUID)             // drawing canvas
case progress                              // coming soon placeholder
case celebration(score: Int, letterId: UUID) // full-screen pass celebration
```

`AppRouter` owns `NavigationPath`. ViewModels call `router.push(_:)` / `router.popToRoot()` via the injected `AppRouter`. Adding a screen requires: a new `AppRoute` case, a `navigationDestination` branch in `LetterQuestApp`, and a ViewModel + View pair. `PracticeView` uses `.id(letterId)` to force a fresh view tree (including PKCanvasView) when navigating between letters.

### Reactive layer (RxSwift)

- Repositories return `Single<T>` / `Completable`.
- `AppRouter` receives route pushes through a `PublishRelay<AppRoute>`.
- `PracticeViewModel` wires strokes → letter → assessor via `flatMapLatest`.
- All UI updates are dispatched on `MainScheduler.instance`.
- Scoring runs on `DispatchQueue.global(qos: .userInitiated)` inside `Single.create`.

### Immutability & Lenses

All models (`Letter`, `StrokeTemplate`, `AssessmentResult`, `ChildProgress`) are read-only structs. Updates go through `Lens<Whole, Part>` values defined as `static let` on each type. The `|>` (pipe-forward) operator is defined in `ChildProgress.swift` for composing lens operations.

```swift
let updated = progress.recording(result)                          // high-level
let unlocked = ChildProgress.lensIsUnlocked.set(progress, true)  // low-level lens
```

### Stroke templates

`StrokeTemplate.templates(for:)` returns the ordered reference strokes for each uppercase letter. All coordinates are normalised to the **0–1 unit square** (y grows downward, matching screen conventions). Stroke ordering matches the pedagogical print order taught to children.

Path-building helpers in a private extension: `line`, `curveThrough`, `bezier`, `circleArc`, `ellipticalArc`.

Unknown characters fall back to a single top-to-bottom vertical so the scoring pipeline always has something to compare against.

Pass threshold: `overallScore >= 75`. Feedback is generated for any signal below 60.

### Letter difficulty tiers

| Range | Difficulty |
|-------|-----------|
| A–E   | `.easy`   |
| F–O   | `.medium` |
| P–Z   | `.hard`   |

## Directory Structure

```
LetterQuest/
  App/                    — LetterQuestApp.swift (entry point + DI root)
  Navigation/             — AppRoute.swift, AppRouter.swift
  Models/                 — Letter, StrokeTemplate, AssessmentResult, ChildProgress
    Protocols/            — LetterProtocol, StrokeTemplateProtocol, AssessmentResultProtocol, ChildProgressProtocol
  ViewModels/             — HomeViewModel, PracticeViewModel
    Protocols/            — HomeViewModelProtocol, PracticeViewModelProtocol
  Views/
    Home/                 — HomeView
    Practice/             — PracticeView, CanvasView, LetterStrokeAnimation, StrokeGuideOverlay
    Shared/               — CelebrationView, ScorePanel, ScorePill
  Core/
    Assessment/           — HandwritingAssessor + DTWMatcher, ShapeAnalyzer, ProportionChecker, SmoothnessAnalyzer
    Repositories/         — LetterRepository, ProgressRepository
      Protocols/          — LetterRepositoryProtocol, ProgressRepositoryProtocol
    Lenses/               — Lens<Whole, Part> generic type
  Resources/              — Info.plist

LetterQuestTests/
  ChildProgressTests.swift
  DTWMatcherTests.swift
  LensTests.swift
  LetterRepositoryTests.swift
  StrokeTemplateTests.swift
```

## Key Conventions

- Views are generic over their ViewModel protocol (`struct PracticeView<VM: PracticeViewModelProtocol>`), keeping them testable without the real VM.
- `CanvasView` is a `UIViewRepresentable` wrapping `PKCanvasView`; stroke updates flow out via a closure callback.
- `ProgressRepository` persists to `UserDefaults` under the key `letter_quest_progress_v1` as a JSON-encoded `[UUID: ChildProgress]` dictionary.
- Template images are loaded from the asset catalogue by name `template_<CHAR>` (e.g. `template_A`). Missing assets are handled gracefully — `templateImage` returns `nil`.
- `StrokeGuideOverlay` draws dotted centrelines and numbered start-point circles per stroke, layered beneath the transparent PKCanvasView. Colors cycle through a 4-color palette (blue, orange, green, purple) by stroke index.
- `LetterStrokeAnimation` shows an animated demonstration of each stroke in the header using `.trim(from:to:)`. It auto-plays on `onAppear` and replays on tap.
- `GuideLines` draws four horizontal rules at fixed proportions (20 %, 45 %, 70 %, 85 % of canvas height), matching the `ProportionChecker` thresholds.
- The `|>` (pipe-forward) operator is defined globally in `ChildProgress.swift` and is used throughout the codebase for readable lens composition.
- `StrokeTemplateTests.swift` contains a full pedagogical spec (`letterSpec`) for all 26 letters (stroke count + direction sequence), used as a test oracle.
