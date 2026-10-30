# Flutter Second Screen

A production-grade, Clean Architecture Flutter package for managing secondary screens, dual displays, and cross-screen communication. Currently available for **Windows Desktop**, with architectural blueprints and upcoming native support for **Android** and **iOS**.

---

## 🌟 Key Features

- **Multi-Display Detection**: Query physical monitors, detect primary vs. secondary displays, resolutions, and position offsets.
- **Secondary Window Lifecycle**: Initialize, open, maximize, focus, and close secondary windows seamlessly.
- **Bi-Directional Messaging**: Typed or event-based cross-screen event bus to transfer cart data, signatures, advertisements, or status updates between windows.
- **Clean Architecture & SOLID**: Strict separation of concerns (Domain, Data, Presentation) with dependency inversion, interface segregation, and platform interface extensibility.
- **Developer-Friendly Mixin & Widgets**: Use `SecondScreenListenerMixin`, `SecondScreenEventListener`, or `SecondScreenEventBuilder` for reactive UI updates without boilerplate.
- **Multi-Platform Blueprint**: Built on Flutter's `PlatformInterface` standard with pluggable platform classes and documented TODO blueprints for Android Presentation API and iOS external UIScreen.

---

## 🖥 Platform Support

| Platform | Support Status | Underlying Mechanism |
| :--- | :---: | :--- |
| **Windows Desktop / macOS** | ✅ **Available** | `window_manager_plus` + `screen_retriever` multi-window |
| **Android** | ⏳ *In Development* | `android.app.Presentation` + `DisplayManager` |
| **iOS** | ⏳ *In Development* | `UIScreen` external displays + `UIWindow` |
| **Linux** | 📋 *Planned* | Desktop multi-window & display retriever |

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
        │   └── second_screen_event_model.dart
        └── repositories/
            ├── repositories.dart
            └── second_screen_repository_impl.dart
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

## 🚀 Getting Started

### 1. Add Dependency

In your `pubspec.yaml`:

```yaml
dependencies:
  flutter_second_screen: ^1.0.0
```

### 2. Main Entry Point Setup

In your `main.dart`, handle the secondary screen entry point when the process is launched:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_second_screen/flutter_second_screen.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterSecondScreen.ensureInitialized(args);

  if (FlutterSecondScreen.isSecondaryScreen(args)) {
    // Secondary screen process
    final initialized = await FlutterSecondScreen.instance.initSecondaryDisplay(
      const SecondScreenConfig(title: 'Customer Facing Display'),
    );
    if (initialized) {
      runApp(const CustomerDisplayApp());
    }
  } else {
    // Main cashier / POS application
    runApp(const CashierMainApp());
  }
}
```

---

## 💡 Usage Examples

### Opening the Secondary Screen

```dart
final secondScreen = FlutterSecondScreen.instance;

// Check if a second physical monitor is connected
if (await secondScreen.isSecondaryDisplayAvailable()) {
  await secondScreen.openSecondaryScreen(arguments: ['second-screen']);
}
```

### Sending Events Between Screens

```dart
// Send from Main Screen to Secondary Screen
await secondScreen.sendEventToSecondary('cartUpdate', {
  'items': [
    {'name': 'Sneakers', 'price': 89.99},
  ],
  'total': 89.99,
});

// Send from Secondary Screen back to Main Screen (e.g. Signature or Confirmation)
await secondScreen.sendEventToMain('signatureApproved', signatureData);
```

### Listening to Events with `SecondScreenListenerMixin`

```dart
class CustomerDisplayScreen extends StatefulWidget {
  const CustomerDisplayScreen({super.key});

  @override
  State<CustomerDisplayScreen> createState() => _CustomerDisplayScreenState();
}

class _CustomerDisplayScreenState extends State<CustomerDisplayScreen>
    with SecondScreenListenerMixin {
  Map<String, dynamic>? cartData;

  @override
  Map<String, void Function(dynamic)> getSecondScreenEventListeners() {
    return {
      'cartUpdate': (data) {
        setState(() {
          cartData = data as Map<String, dynamic>;
        });
      },
      'reset': (_) {
        setState(() {
          cartData = null;
        });
      },
    };
  }

  @override
  Widget build(BuildContext context) {
    if (cartData == null) {
      return const Center(child: Text('Welcome!'));
    }
    return Text('Total: \$${cartData!['total']}');
  }
}
```

### Listening to Events with `SecondScreenEventListener` Widget

```dart
SecondScreenEventListener(
  eventName: 'cartUpdate',
  onEvent: (data) {
    debugPrint('Received cart update: $data');
  },
  child: const MyCartWidget(),
);
```

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
