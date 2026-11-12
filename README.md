# Flutter Second Screen

A Clean Architecture Flutter package for secondary screens, dual displays, and cross-screen communication — built for customer-facing displays, POS terminals, kiosks, and presenter views. Available today on **macOS** and **Windows**, with architectural blueprints for upcoming **Android** and **iOS** support.

No third-party window or display packages: secondary windows, display detection, and messaging are handled by the package's own native plugin.

---

## 🌟 Key Features

- **Multi-Display Detection**: List connected monitors with name, size, usable area, position, and primary flag. Plugging in a monitor is picked up on the next call.
- **Secondary Window Lifecycle**: Open, place, full-screen, focus, and close a secondary window on the second display.
- **Bi-Directional Messaging**: Send cart data, signatures, ads, or status updates between windows with an event bus.
- **One-Line Bootstrapping**: `FlutterSecondScreen.run` wires the main and secondary entry points for you.
- **Developer-Friendly Widgets**: `SecondScreenListenerMixin`, `SecondScreenEventListener`, and `SecondScreenEventBuilder` for reactive UI updates without boilerplate.
- **Clean Architecture & SOLID**: Domain, Data, and Presentation layers with dependency inversion and a pluggable `PlatformInterface`.

---

## 🖥 Platform Support

| Platform | Status | Mechanism |
| :--- | :---: | :--- |
| **macOS** | ✅ Available | Built-in AppKit plugin, one Flutter engine per window |
| **Windows** | ✅ Available | Built-in Win32 plugin, one Flutter engine per window |
| **Android** | ⏳ In development | `android.app.Presentation` + `DisplayManager` |
| **iOS** | ⏳ In development | `UIScreen` external displays + `UIWindow` |
| **Linux** | 📋 Planned | Desktop multi-window & display detection |

---

## 🚀 Quick Start

### 1. Add the dependency

```yaml
dependencies:
  flutter_second_screen: ^2.0.0
```

### 2. Platform setup (one time)

Each secondary window runs its own Flutter engine. Tell the plugin how to register your app's plugins on those engines — this is the only native change required.

<details open>
<summary><b>macOS</b> — <code>macos/Runner/MainFlutterWindow.swift</code></summary>

```swift
import Cocoa
import FlutterMacOS
import flutter_second_screen

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)
    // Register plugins on every secondary window engine as well.
    FlutterSecondScreenPlugin.registerGeneratedPlugins = { registry in
      RegisterGeneratedPlugins(registry: registry)
    }

    super.awakeFromNib()
  }
}
```

</details>

<details open>
<summary><b>Windows</b> — <code>windows/runner/flutter_window.cpp</code></summary>

```cpp
#include <flutter_second_screen/flutter_second_screen_plugin_c_api.h>

#include "flutter/generated_plugin_registrant.h"

bool FlutterWindow::OnCreate() {
  // ...
  RegisterPlugins(flutter_controller_->engine());
  // Register plugins on every secondary window engine as well.
  FlutterSecondScreenPluginSetRegisterPluginsCallback(
      [](FlutterDesktopEngineRef engine) {
        flutter_second_screen::EnginePluginRegistry registry(engine);
        RegisterPlugins(&registry);
      });
  // ...
}
```

</details>

After changing native files, do a full rebuild (not a hot restart).

### 3. Entry point

```dart
import 'package:flutter/material.dart';
import 'package:flutter_second_screen/flutter_second_screen.dart';

void main(List<String> args) => FlutterSecondScreen.run(
      args,
      mainApp: () => const CashierApp(),
      secondaryApp: () => const CustomerDisplayApp(),
      config: const SecondScreenConfig(title: 'Customer Display'),
    );
```

`run` initializes the binding and the plugin, then:
- in the **main window**, runs `mainApp`;
- in the **secondary window**, places the window on the second display using `config` and runs `secondaryApp`. If no second display is connected, the secondary window closes itself.

Need setup before `runApp` (dependency injection, storage, ...)? Use `beforeRunApp`:

```dart
void main(List<String> args) => FlutterSecondScreen.run(
      args,
      beforeRunApp: (isSecondary) async {
        await configureDependencies();
      },
      mainApp: () => const CashierApp(),
      secondaryApp: () => const CustomerDisplayApp(),
    );
```

<details>
<summary>Manual entry point (without <code>run</code>)</summary>

```dart
void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterSecondScreen.ensureInitialized(args);

  if (FlutterSecondScreen.isSecondaryScreen(args)) {
    final initialized = await FlutterSecondScreen.instance.initSecondaryDisplay(
      const SecondScreenConfig(title: 'Customer Display'),
    );
    if (initialized) runApp(const CustomerDisplayApp());
  } else {
    runApp(const CashierApp());
  }
}
```

</details>

### 4. Open the secondary screen

```dart
final secondScreen = FlutterSecondScreen.instance;

if (await secondScreen.isSecondaryDisplayAvailable()) {
  await secondScreen.openSecondaryScreen();
}
```

A complete, runnable app lives in [`example/`](example/lib/main.dart) (`cd example && flutter run -d macos` or `-d windows`).

---

## 💡 Usage

### Detecting displays

```dart
final secondScreen = FlutterSecondScreen.instance;

final displays = await secondScreen.getDisplays();     // primary first
final primary = await secondScreen.getPrimaryDisplay();
final secondary = await secondScreen.getSecondaryDisplay(); // null if none
final hasSecond = await secondScreen.hasSecondaryDisplay();

for (final display in displays) {
  print('${display.name}: ${display.size} at ${display.position}'
      ' (usable ${display.visibleSize} at ${display.visiblePosition})');
}
```

All values are logical pixels, measured from the top-left corner of the primary display. Displays are read fresh on every call.

### Sending events between screens

```dart
// Main → secondary
await secondScreen.sendEventToSecondary('cartUpdate', {
  'items': [
    {'name': 'Sneakers', 'price': 89.99},
  ],
  'total': 89.99,
});

// Secondary → main
await secondScreen.sendEventToMain('signatureApproved', signatureData);
```

Payloads can be any value supported by Flutter's standard message codec (`null`, `bool`, `num`, `String`, `List`, `Map`, typed data). Sending to a window that isn't open is a no-op, so you don't need to check `isSecondaryScreenOpen()` before every update.

### Listening with `SecondScreenListenerMixin`

```dart
class _CustomerDisplayState extends State<CustomerDisplay>
    with SecondScreenListenerMixin {
  Map<String, dynamic>? cart;

  @override
  Map<String, void Function(dynamic)> getSecondScreenEventListeners() => {
        'cartUpdate': (data) => setState(() => cart = Map.from(data as Map)),
        'reset': (_) => setState(() => cart = null),
      };

  @override
  Widget build(BuildContext context) => cart == null
      ? const Center(child: Text('Welcome!'))
      : Text('Total: \$${cart!['total']}');
}
```

The mixin also provides `sendEventToSecondaryScreen` and `sendEventToMainScreen`.

### Listening with widgets

```dart
// Side effects
SecondScreenEventListener(
  eventName: 'cartUpdate',
  onEvent: (data) => debugPrint('Cart: $data'),
  child: const CartView(),
);

// Rebuild on each event
SecondScreenEventBuilder<Map<dynamic, dynamic>>(
  eventName: 'cartUpdate',
  builder: (context, cart) => Text('Items: ${cart?['items']?.length ?? 0}'),
);
```

### Listening with streams

```dart
secondScreen.on<String>('signatureApproved').listen((signature) { ... });
secondScreen.eventStream.listen((event) => print('${event.name} from ${event.fromWindowId}'));
```

### Window control

```dart
await secondScreen.isSecondaryScreenOpen();
await secondScreen.focusSecondaryScreen();
await secondScreen.closeSecondaryScreen();
await secondScreen.closeAllScreens(); // closes every window, including main
```

### Handling errors

```dart
try {
  await secondScreen.openSecondaryScreen();
} on SecondScreenException catch (e) {
  if (e.code == SecondScreenException.setupRequired) {
    // The platform setup step is missing in the app runner.
  }
  debugPrint(e.message);
}
```

---

## 📚 API Reference

### `FlutterSecondScreen`

| Member | Description |
| :--- | :--- |
| `FlutterSecondScreen.run(args, mainApp:, secondaryApp:, config:, beforeRunApp:)` | Boots the right app for the current window. |
| `FlutterSecondScreen.ensureInitialized(args)` | Binds this engine to its window. Optional; `run` calls it for you. |
| `FlutterSecondScreen.isSecondaryScreen(args)` / `isMainScreen(args)` | Whether this engine was launched as the secondary window. |
| `FlutterSecondScreen.instance` | Singleton facade for all operations below. |
| `getDisplays()` / `getPrimaryDisplay()` / `getSecondaryDisplay()` / `hasSecondaryDisplay()` | Display detection. |
| `isSecondaryDisplayAvailable()` | A second display exists **and** the secondary window is not open. |
| `openSecondaryScreen({arguments})` | Creates the secondary window. Throws `SecondScreenException` if setup is missing. |
| `initSecondaryDisplay([config])` | Called **in the secondary window** to place and show it. Returns `false` (and closes the window) without a second display. |
| `isSecondaryScreenOpen()` / `focusSecondaryScreen()` / `closeSecondaryScreen()` / `closeAllScreens()` | Window lifecycle. |
| `sendEventToSecondary(name, [data])` / `sendEventToMain(name, [data])` / `sendEventToWindow(id, name, [data])` | Messaging. |
| `eventStream` / `on<T>(name)` / `addEventListener` / `removeEventListener` | Receiving events. |

Window IDs: the main window is `0`, the secondary window is `1`.

### `SecondScreenConfig`

| Option | Default | Description |
| :--- | :--- | :--- |
| `title` | `'Customer Display'` | Window title. |
| `fullScreen` | `true` | macOS: native full screen. Windows: borderless window covering the display. |
| `maximize` | `true` | Maximize on the target display. Ignored when `fullScreen` is `true`. |
| `size` | second display's usable size | Window size in logical pixels. |
| `position` | second display's usable top-left | Window position in logical pixels (top-left of the primary display is `0,0`). |
| `center` | `true` | Center on the target display when no position can be resolved. |
| `resizable` | `false` | Whether the user can resize the window. |
| `alwaysOnTop` | `false` | Keep the window above other windows. |
| `skipTaskbar` | `false` | Windows: hide the taskbar button. macOS: hides the app's Dock icon (app-wide). |
| `backgroundColor` | transparent | Window background (macOS). |
| `routeArguments` | `['second-screen']` | Informational; pass launch arguments to `openSecondaryScreen(arguments:)`. |

---

## 🩺 Troubleshooting

| Symptom | Cause & fix |
| :--- | :--- |
| `SecondScreenException(setup-required)` when opening | The platform setup step is missing. Add it to `MainFlutterWindow.swift` / `flutter_window.cpp` and do a full rebuild. |
| Secondary window never appears | Only one display is connected (`initSecondaryDisplay` returns `false` and closes the window), or the secondary entry point never calls `initSecondaryDisplay` (use `FlutterSecondScreen.run`). |
| Plugin errors (`MissingPluginException`) inside the secondary window | The setup callback is missing, so other plugins are not registered on the secondary engine. |
| Events not received | Both windows must listen/send with the same event name; the listener must be registered (e.g. mixin `State` is mounted) before the event arrives. |
| `isSecondaryScreenOpen()` stays `true` | Closing is asynchronous; query again after the window has closed. |

---

## 🔄 Migrating from 1.0.x to 2.0.0

1.0.x depended on `window_manager_plus` and `screen_retriever`. Both are gone.

1. Remove `WindowManagerPlusPlugin.RegisterGeneratedPlugins = ...` / `WindowManagerPlusPluginSetWindowCreatedCallback(...)` from your runner **unless your app still uses `window_manager_plus` directly**, and add the [platform setup](#2-platform-setup-one-time) above.
2. On macOS, references to `WindowManagerPlusFlutterWindow` (e.g. in `AppDelegate.applicationShouldTerminateAfterLastWindowClosed`) no longer apply; secondary windows are plain `NSWindow`s.
3. `ScreenDisplayModel.fromScreenRetriever` was removed; use `ScreenDisplayModel.fromMap` or the `ScreenDisplay` entities returned by `getDisplays()`.
4. Optionally replace your `main()` with `FlutterSecondScreen.run`.

---

## 🏛 Architecture Overview

`flutter_second_screen` strictly adheres to **Clean Architecture** and **SOLID** principles, ensuring decoupling between UI, business rules, and platform-specific window managers.

### 🌳 Architectural Component Tree

```text
flutter_second_screen
├── 📱 Presentation Layer (Flutter Widgets & Mixins)
│   ├── Main Screen View (Cashier / POS UI)
│   ├── Secondary Screen View (Customer Display UI)
│   ├── SecondScreenListenerMixin (State mixin for reactive events)
│   ├── SecondScreenEventListener (Callback-based event listener widget)
│   └── SecondScreenEventBuilder (Builder widget reacting to stream events)
│
├── 🎯 Unified Facade (Public API Entry Point)
│   └── FlutterSecondScreen (Singleton & factory for all operations)
│
├── 🧠 Domain Layer (Pure Dart Business Logic - Zero External Dependencies)
│   ├── 📦 Entities
│   │   ├── ScreenDisplay (Display ID, resolution, position offset, isPrimary)
│   │   ├── SecondScreenEvent<T> (Cross-screen typed messaging model)
│   │   ├── SecondScreenConfig (Secondary window title, size, position, flags)
│   │   ├── SecondScreenException (Typed setup / window errors)
│   │   └── SecondScreenStatus (Window lifecycle state)
│   │
│   ├── ⚙️ Use Cases (Single Responsibility)
│   │   ├── Display Management
│   │   │   ├── GetDisplaysUseCase
│   │   │   └── IsSecondaryDisplayAvailableUseCase
│   │   ├── Window Lifecycle
│   │   │   ├── InitSecondaryDisplayUseCase
│   │   │   ├── OpenSecondaryScreenUseCase
│   │   │   ├── CloseSecondaryScreenUseCase
│   │   │   └── IsSecondaryScreenOpenUseCase
│   │   └── Cross-Screen Messaging
│   │       ├── SendEventToSecondaryUseCase
│   │       ├── SendEventToMainUseCase
│   │       └── ListenSecondaryScreenEventsUseCase
│   │
│   └── 📋 Repository Contracts (Interface Segregation)
│       ├── SecondScreenDisplayManager (Display detection contract)
│       ├── SecondScreenWindowManager (Window lifecycle contract)
│       ├── SecondScreenMessenger (Cross-screen messaging contract)
│       └── SecondScreenRepository (Aggregated domain interface)
│
└── 💾 Data Layer (Infrastructure & Platform Implementations)
    ├── 🔄 Repository Implementation
    │   └── SecondScreenRepositoryImpl (Implements Domain Repository via DIP)
    │
    ├── 📦 Data Models (Adapters & Serialization)
    │   ├── ScreenDisplayModel (Adapts platform displays to domain entities)
    │   ├── SecondScreenConfigModel (Serializes window config for the native plugin)
    │   └── SecondScreenEventModel (JSON serialization for cross-screen events)
    │
    └── 🔌 Platform Data Sources (Platform Interface Pattern)
        └── SecondScreenPlatform (Federated platform interface)
            ├── DesktopSecondScreenPlatform (Windows & macOS multi-window core)
            │   ├── WindowsSecondScreenPlatform (Windows desktop plugin class)
            │   └── MacosSecondScreenPlatform (macOS desktop plugin class)
            ├── AndroidSecondScreenPlatform (Android Presentation API blueprint)
            └── IosSecondScreenPlatform (iOS UIScreen & UIWindow blueprint)
```

### 📂 Codebase File & Folder Structure

```text
lib/
├── flutter_second_screen.dart             # Public export library entrypoint
└── src/
    ├── flutter_second_screen.dart         # FlutterSecondScreen facade class
    ├── presentation/                      # Presentation Layer
    │   ├── presentation.dart
    │   ├── mixins/
    │   │   └── second_screen_listener_mixin.dart
    │   └── widgets/
    │       └── second_screen_event_listener.dart
    ├── domain/                            # Domain Layer (Pure Dart)
    │   ├── domain.dart
    │   ├── entities/
    │   │   ├── entities.dart
    │   │   ├── screen_display.dart
    │   │   ├── second_screen_config.dart
    │   │   ├── second_screen_event.dart
    │   │   ├── second_screen_exception.dart
    │   │   └── second_screen_status.dart
    │   ├── repositories/
    │   │   ├── repositories.dart
    │   │   ├── second_screen_display_manager.dart
    │   │   ├── second_screen_window_manager.dart
    │   │   ├── second_screen_messenger.dart
    │   │   └── second_screen_repository.dart
    │   └── usecases/
    │       ├── usecases.dart
    │       ├── get_displays_usecase.dart
    │       ├── is_secondary_display_available_usecase.dart
    │       ├── init_secondary_display_usecase.dart
    │       ├── open_secondary_screen_usecase.dart
    │       ├── close_secondary_screen_usecase.dart
    │       ├── is_secondary_screen_open_usecase.dart
    │       ├── send_event_to_secondary_usecase.dart
    │       ├── send_event_to_main_usecase.dart
    │       └── listen_secondary_screen_events_usecase.dart
    └── data/                              # Data Layer
        ├── data.dart
        ├── datasources/
        │   ├── datasources.dart
        │   ├── second_screen_platform.dart
        │   ├── desktop_second_screen_platform.dart
        │   ├── windows_second_screen_platform.dart
        │   ├── macos_second_screen_platform.dart
        │   ├── android_second_screen_platform.dart
        │   └── ios_second_screen_platform.dart
        ├── models/
        │   ├── models.dart
        │   ├── screen_display_model.dart
        │   ├── second_screen_config_model.dart
        │   └── second_screen_event_model.dart
        └── repositories/
            ├── repositories.dart
            └── second_screen_repository_impl.dart

macos/                                     # Native macOS plugin (Swift, SPM + CocoaPods)
├── flutter_second_screen.podspec
└── flutter_second_screen/
    ├── Package.swift
    └── Sources/flutter_second_screen/
        └── FlutterSecondScreenPlugin.swift
windows/                                   # Native Windows plugin (C++)
├── CMakeLists.txt
├── include/flutter_second_screen/
│   └── flutter_second_screen_plugin_c_api.h
├── flutter_second_screen_plugin.{h,cpp}   # Channel handler, displays, window registry
└── second_screen_window.{h,cpp}           # Win32 host window for secondary engines
```

### 🔄 Data & Control Flow Diagram

```mermaid
flowchart TD
    subgraph UI ["Presentation Layer (Flutter UI)"]
        ScreenA["Main Screen View"]
        ScreenB["Secondary Screen View"]
        Mixin["SecondScreenListenerMixin"]
        Widget["SecondScreenEventListener"]
    end

    subgraph Facade ["Unified Facade"]
        FSS["FlutterSecondScreen"]
    end

    subgraph Domain ["Domain Layer (Pure Dart)"]
        direction TB
        UseCases["Use Cases (Open, Close, Init, SendEvent, etc.)"]
        Contracts["Repository Contracts (DisplayManager, WindowManager, Messenger)"]
        Entities["Entities (ScreenDisplay, SecondScreenEvent, SecondScreenConfig)"]
        UseCases --> Contracts
        UseCases -.-> Entities
    end

    subgraph Data ["Data Layer"]
        RepoImpl["SecondScreenRepositoryImpl"]
        PI["SecondScreenPlatform (Interface)"]
        
        subgraph Implementations ["Platform Drivers"]
            DeskPlat["DesktopSecondScreenPlatform"]
            WinPlat["WindowsSecondScreenPlatform"]
            MacPlat["MacosSecondScreenPlatform"]
            AndPlat["AndroidSecondScreenPlatform (Blueprint)"]
            IosPlat["IosSecondScreenPlatform (Blueprint)"]
        end
    end

    UI --> Facade
    Facade --> UseCases
    RepoImpl -.->|implements (DIP)| Contracts
    RepoImpl --> PI
    PI --> DeskPlat
    DeskPlat --> WinPlat
    DeskPlat --> MacPlat
    PI --> AndPlat
    PI --> IosPlat
```

### SOLID Principles Applied:
- **Single Responsibility Principle (SRP)**: Display queries (`SecondScreenDisplayManager`), window lifecycle management (`SecondScreenWindowManager`), and inter-screen messaging (`SecondScreenMessenger`) are decoupled into focused, dedicated interfaces.
- **Open/Closed Principle (OCP)**: Adding support for a new operating system (e.g., Android, iOS, or macOS) only requires implementing `SecondScreenPlatform` without modifying the domain use cases or repository contracts.
- **Liskov Substitution Principle (LSP)**: Any platform implementation (`WindowsSecondScreenPlatform`, `AndroidSecondScreenPlatform`, or test mocks) can be seamlessly substituted without breaking consumers.
- **Interface Segregation Principle (ISP)**: Clients can depend solely on `SecondScreenDisplayManager`, `SecondScreenWindowManager`, or `SecondScreenMessenger` instead of one monolithic interface.
- **Dependency Inversion Principle (DIP)**: High-level application modules depend on domain abstractions rather than concrete platform libraries.

---

## 📱 Upcoming Android & iOS Implementation

`flutter_second_screen` defines clean platform contracts and architectural blueprints for Android and iOS in:
- `AndroidSecondScreenPlatform` (`lib/src/data/datasources/android_second_screen_platform.dart`)
- `IosSecondScreenPlatform` (`lib/src/data/datasources/ios_second_screen_platform.dart`)

### Android Roadmap
- Integrates with Android's `DisplayManager.getDisplays(DisplayManager.DISPLAY_CATEGORY_PRESENTATION)`.
- Spawns a secondary `FlutterEngine` inside an `android.app.Presentation` dialog window.
- Communicates across engines via native MethodChannel and EventChannel.

### iOS Roadmap
- Detects external displays via `UIScreen.screens` and `UIScreenDidConnectNotification`.
- Attaches a secondary `UIWindow` with a `FlutterViewController` bound to the external `UIScreen`.
- Communicates across engines via native MethodChannel and EventChannel.

---

## 🧪 Testing

The package includes comprehensive unit and widget tests covering all entities, use cases, repository implementations, mixins, and platform interfaces:

```bash
flutter test
```

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🌟 Support

If you find this package helpful, please consider giving it a ⭐ on [GitHub](https://github.com/yusufhnf/flutter_second_screen) and a 👍 on [pub.dev](https://pub.dev/packages/flutter_second_screen)!
