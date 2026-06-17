# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

LetterQuest is an iPad app that teaches children to write uppercase letters using finger or Apple Pencil. The child draws on a PencilKit canvas; a four-signal scoring pipeline evaluates the drawing and gives feedback.

- **Platform**: iPad only (iOS 17+), Swift 5.9, SwiftUI
- **Dependency manager**: Swift Package Manager (resolved inside the Xcode project)
- **Only external dependency**: RxSwift 6.10.2 (RxSwift, RxCocoa, RxRelay)
- **Project file generator**: XcodeGen (`project.yml` → `LetterQuest.xcodeproj`)

## Build & Run

Open `LetterQuest.xcodeproj` in Xcode and run on an iPad simulator or device. There is no CLI build target; all building happens inside Xcode.

To regenerate the Xcode project after editing `project.yml`:

```bash
xcodegen generate
```

There are no automated tests yet. The Swift Testing framework (`import Testing`) is the target framework for new tests when they are added.

## Architecture

### Pattern: MVVM + Protocol-Oriented DI

Every layer exposes a protocol; concrete types are injected at construction time in `LetterQuestApp.swift`. No singletons or service locators are used.

```
LetterQuestApp (entry point)
  └── AppRouter          — owns NavigationPath; pushes routes via RxRelay
  └── LetterRepository   — in-memory, returns Letter.alphabet as a Single
  └── ProgressRepository — UserDefaults-backed, JSON-encoded ChildProgress
  └── HandwritingAssessor — four-signal scoring pipeline
        ├── DTWMatcher          (35 %) — stroke path via Dynamic Time Warping
        ├── ShapeAnalyzer       (35 %) — bitmap IoU against a template CGImage
        ├── ProportionChecker   (20 %) — guideline geometry
        └── SmoothnessAnalyzer  (10 %) — angular jitter / speed variance
```

### Navigation

`AppRoute` (enum, `Hashable`) defines all screens. `AppRouter` owns the `NavigationPath`. ViewModels call `router.push(_:)` / `router.popToRoot()` via the injected `AppRouter`. New screens require: a new `AppRoute` case, a `navigationDestination` branch in `LetterQuestApp`, and a ViewModel + View pair.

### Reactive layer (RxSwift)

- Repositories return `Single<T>` / `Completable`.
- `AppRouter` receives route pushes through a `PublishRelay<AppRoute>`.
- `PracticeViewModel` wires strokes → letter → assessor via `flatMapLatest`.
- All UI updates are dispatched on `MainScheduler.instance`.

### Immutability & Lenses

All models (`Letter`, `StrokeTemplate`, `ChildProgress`) are read-only structs. Updates go through `Lens<Whole, Part>` values defined as `static let` on each type. The `|>` (pipe) operator is defined in `ChildProgress.swift` for composing lens operations.

```swift
let updated = progress.recording(result)         // high-level
let unlocked = ChildProgress.lensIsUnlocked.set(progress, true)  // low-level
```

### Stroke templates

`StrokeTemplate.templates(for:)` returns the reference strokes for each uppercase letter. All coordinates are normalised to the **0–1 unit square**. Letters without hand-authored templates fall back to a single vertical stroke. The current branch is actively completing templates for all 26 letters.

Pass threshold: `overallScore >= 75`.

## Directory Structure

```
LetterQuest/
  App/                    — entry point (LetterQuestApp.swift)
  Navigation/             — AppRoute, AppRouter
  Models/                 — Letter, StrokeTemplate, AssessmentResult, ChildProgress
    Protocols/            — LetterProtocol, StrokeTemplateProtocol, etc.
  ViewModels/             — HomeViewModel, PracticeViewModel
    Protocols/            — HomeViewModelProtocol, PracticeViewModelProtocol
  Views/
    Home/                 — HomeView
    Practice/             — PracticeView, CanvasView
    Shared/               — CelebrationView, ScorePanel, ScorePill
  Core/
    Assessment/           — HandwritingAssessor + four scorer classes
    Repositories/         — LetterRepository, ProgressRepository
      Protocols/          — LetterRepositoryProtocol, ProgressRepositoryProtocol
    Lenses/               — Lens<Whole, Part> generic type
  Resources/              — Info.plist
```

## Key Conventions

- Views are generic over their ViewModel protocol (`struct PracticeView<VM: PracticeViewModelProtocol>`), keeping them testable without the real VM.
- `CanvasView` is a `UIViewRepresentable` wrapping `PKCanvasView`; stroke updates flow out via a closure callback.
- `ProgressRepository` persists to `UserDefaults` under the key `letter_quest_progress_v1`.
- Template images are loaded from the asset catalogue by name `template_<CHAR>` (e.g. `template_A`). Missing assets are handled gracefully — `templateImage` returns `nil`.
- The `GuideLines` view draws four horizontal rules at fixed proportions (20 %, 45 %, 70 %, 85 % of canvas height).
