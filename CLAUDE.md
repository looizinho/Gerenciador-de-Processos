# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

**Gerenciador de Processos** (Process Manager) is a macOS menu bar application for managing local development servers and services (e.g., Vite, Ollama, Hermes). The app allows users to:
- Add and manage processes with custom names, commands, and arguments
- View a list of all configured processes with their current status
- Start/stop processes with a single click
- Run entirely from the macOS menu bar for minimal UI footprint

## Project Structure

```
Gerenciador de Processos/
├── Gerenciador de Processos/          # Main app source code
│   ├── Gerenciador_de_ProcessosApp.swift  # App entry point (menu bar setup)
│   ├── Models/
│   │   └── Process.swift               # Process data model
│   ├── ViewModels/
│   │   └── ProcessManagerViewModel.swift # State & business logic
│   ├── Views/
│   │   ├── ProcessListView.swift       # Process list with start/stop buttons
│   │   └── AddProcessView.swift        # Form to add new processes
│   ├── Services/
│   │   ├── ProcessService.swift        # Process execution & monitoring
│   │   └── PersistenceService.swift    # Configuration storage
│   └── Assets.xcassets/                # App icons and images
└── Gerenciador de Processos.xcodeproj  # Xcode project configuration
```

## Architecture

The app is a menu bar application with the following core components:

### App Structure
- **Gerenciador_de_ProcessosApp.swift**: Main entry point, sets up the menu bar presence and manages app lifecycle
- **Views/**: Contains all UI views
  - `ProcessListView.swift`: Displays list of processes with start/stop buttons
  - `AddProcessView.swift`: Form for adding new processes (Name, Command, Arguments fields)
  - `MenuBarView.swift`: Menu bar status and quick actions
- **Models/**: Data structures
  - `Process.swift`: Represents a managed process with properties (name, command, arguments, status, pid)
- **ViewModels/**: State management
  - `ProcessManagerViewModel.swift`: Handles process list, add/remove processes, start/stop logic
- **Services/**: Business logic
  - `ProcessService.swift`: Executes, monitors, and terminates processes using `Process` API
  - `PersistenceService.swift`: Saves/loads process configurations (UserDefaults or JSON file)

### Key Design Patterns
- Use `@StateObject` in the app for `ProcessManagerViewModel` to manage shared state
- Use `@EnvironmentObject` to pass the view model to child views
- Implement process monitoring to detect when processes terminate unexpectedly
- Store process configurations persistently so they survive app restarts

## Building and Running

### Build the app (simulator or device)
```bash
xcodebuild -project "Gerenciador de Processos.xcodeproj" -scheme "Gerenciador de Processos" -configuration Debug
```

### Run in the default simulator
```bash
xcodebuild -project "Gerenciador de Processos.xcodeproj" -scheme "Gerenciador de Processos" -configuration Debug -arch arm64
```

### Open in Xcode for interactive development
```bash
open "Gerenciador de Processos.xcodeproj"
```

### Build for release (archive)
```bash
xcodebuild -project "Gerenciador de Processos.xcodeproj" -scheme "Gerenciador de Processos" -configuration Release archive -archivePath build/Release.xcarchive
```

## Testing

### Run unit tests
```bash
xcodebuild -project "Gerenciador de Processos.xcodeproj" -scheme "Gerenciador de Processos" test
```

### Run a specific test
```bash
xcodebuild -project "Gerenciador de Processos.xcodeproj" -scheme "Gerenciador de Processos" test -only-testing:"TARGET/TestClass/testMethod"
```

Tests should be added to a Tests/ directory once development begins. Use XCTest for unit tests and use SwiftUI's `#Preview` macro for view previews during development.

## Development Guidelines

### Menu Bar App Specifics
- Set up `NSStatusBar` to create the menu bar icon
- Use `NSWindow` with `.nivels` set appropriately for menu bar window behavior
- Ensure the app hides from Dock and App Switcher (`NSWindow.canHide`, app Info.plist settings)
- Handle window lifecycle carefully—menu bar apps should not show a window on launch, only when clicked
- Clean up processes on app termination using `.onReceive` with `AppKit` termination notifications

### Process Management
- Use `Foundation.Process` to spawn and manage child processes
- Monitor process status with `Process.terminationHandler` to detect unexpected exits
- Store process PIDs to enable stopping/killing processes
- Capture stdout/stderr if needed for logging or debugging

### SwiftUI Best Practices
- Use `@StateObject` for the main `ProcessManagerViewModel` (app-wide state)
- Use `@EnvironmentObject` to pass view model to child views
- Keep views small and focused; extract reusable components
- Use `#Preview` macro for visual feedback during development
- Bind UI state (start/stop buttons) to view model properties

### File Naming
- Swift files use PascalCase: `ProcessListView.swift`, `ProcessManagerViewModel.swift`
- Group related files by functionality (Models, Views, Services, ViewModels)

### Code Style
- Follow Swift Naming Conventions (PascalCase for types, camelCase for functions/properties)
- Use meaningful names; avoid abbreviations that reduce clarity
- Keep functions focused and under 20 lines when possible

### Persistence
- Save process configurations to `UserDefaults` or JSON file in Application Support
- Load configurations on app launch and restore process list
- Handle migration if configuration format changes

## Key Commands

| Command | Purpose |
|---------|---------|
| `xcodebuild` | Build the project |
| `xcodebuild -configuration Release` | Build release version |
| `xcodebuild test` | Run all tests |
| `open "Gerenciador de Processos.xcodeproj"` | Open in Xcode IDE |
| `open -a "Gerenciador de Processos"` | Run the built app |

## Core Features to Implement

### Phase 1: MVP
- ✅ Menu bar icon and click handling
- ✅ Main window showing process list (empty initially)
- ✅ "Add Process" window with Name, Command, Arguments fields
- ✅ Add button to save new processes
- ✅ Process list with Start/Stop buttons
- ✅ Process status display (running/stopped)
- ✅ Persist process list to disk

### Phase 2: Enhancement
- Process output logging (view logs in a panel)
- Auto-restart on unexpected termination
- Kill/Force-quit option for hung processes
- Process resource usage display (CPU, Memory)
- Ability to edit process configurations
- Keyboard shortcuts for common actions

### Phase 3: Advanced
- Process groups/categories
- Environment variable configuration per process
- Health checks and alerts
- System tray notifications on process state changes

## Dependencies

Currently, the project uses only Apple's built-in frameworks:
- **SwiftUI**: For the user interface
- **Foundation**: Standard library, includes `Process` for process management
- **AppKit**: For menu bar integration and window management (required for menu bar apps)

Recommended frameworks for future features:
- **Combine**: For reactive state management
- **os.log**: For structured logging of process events

Any new external dependencies should be added via Swift Package Manager.

## Deployment

### Local Distribution
1. Build with Release configuration: `xcodebuild -configuration Release`
2. The built `.app` can be shared directly or placed in Applications folder
3. Sign the app if distributing outside Mac App Store: `codesign -s - path/to/app`

### Mac App Store
1. Register with Apple Developer Program
2. Create an App ID and provisioning profile for macOS
3. Build archive using the Release configuration
4. Upload through Xcode Organizer or Transporter

### Notarization (required for external distribution)
1. Build and sign the app
2. Create a notarization request via Xcode or xcrun
3. Wait for Apple to notarize the app
4. Staple the notarization to the app

Ensure Info.plist is configured correctly for a menu bar app (no dock icon unless needed).
