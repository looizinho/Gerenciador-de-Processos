# Repository Guidelines

#mvvm #swiftui #macos #guidelines

## Project Overview

**Gerenciador de Processos** is a native macOS menu bar app written in Swift/SwiftUI for managing local dev servers (start/stop processes, view status, persist configurations). It uses MVVM with Combine and only Apple frameworks — no external dependencies.

## Project Structure & Module Organization

```
Gerenciador de Processos/          # App source (note: path contains spaces)
├── Gerenciador_de_ProcessosApp.swift  # App entry point (@main)
├── ContentView.swift                  # Root SwiftUI view
├── Models/          # Data structures (ManagedProcess.swift, ProcessStatus)
├── ViewModels/      # @Published state & business logic (ProcessManagerViewModel.swift)
├── Views/           # SwiftUI views (ProcessListView.swift, AddProcessView.swift)
├── Services/        # ProcessService.swift (spawn/monitor), PersistenceService.swift
└── Assets.xcassets/ # Icons and colors
Gerenciador de Processos.xcodeproj/    # Xcode project config
```

Place new files in the matching group folder and add them to the Xcode target, not just the filesystem.

## Build, Test, and Development Commands

Always quote project paths (they contain spaces):

```bash
# Debug build
xcodebuild -project "Gerenciador de Processos.xcodeproj" -scheme "Gerenciador de Processos" -configuration Debug build

# Open in Xcode (preferred for UI work)
open "Gerenciador de Processos.xcodeproj"

# Release archive
xcodebuild -project "Gerenciador de Processos.xcodeproj" -scheme "Gerenciador de Processos" -configuration Release archive -archivePath build/Release.xcarchive

# Run tests
xcodebuild -project "Gerenciador de Processos.xcodeproj" -scheme "Gerenciador de Processos" test
```

## Coding Style & Naming Conventions

- **Indentation: tabs** (normalized repo-wide; commit `3c1b76f`). Match surrounding code.
- Swift API Guidelines: `PascalCase` for types/files, `camelCase` for properties/methods.
- File names mirror their primary type: `ProcessService.swift`, `ManagedProcess.swift`.
- Use `@StateObject` for owned view models, `@EnvironmentObject`/`@ObservedObject` downstream.
- No linter is configured; keep SwiftUI views small and extract subviews when a body grows large.
- Comments/UI strings are in Portuguese; code identifiers are in English.

## Testing Guidelines

- No test target exists yet. When adding one, use **XCTest**, name files `*Tests.swift`, and mirror the source structure (e.g., `Services/ProcessServiceTests.swift`).
- Test service logic (process lifecycle, persistence round-trips) without UI; validate views via manual runs/Xcode Previews until UI tests exist.

## Commit & Pull Request Guidelines

- History mixes Portuguese and English; both are acceptable. Use short imperative summaries (e.g., "Adicionar campos de caminho e ação aos processos", "Fix: Restore Start button functionality").
- Work happens on short-lived feature branches merged via PR (`implement-mvp`, `fix-start-and-edit-bugs`). Reference the issue/bug in the PR description and include a screenshot or GIF for UI changes.
- Keep PRs focused: one feature or fix per branch.
