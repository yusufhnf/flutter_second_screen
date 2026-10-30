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

```mermaid
graph TD
    subgraph UI ["Presentation Layer"]
        ScreenA["Main Screen View"]
        ScreenB["Secondary Screen View"]
        Mixin["SecondScreenListenerMixin"]
        Widget["SecondScreenEventListener"]
    end

    subgraph Facade ["Unified Facade"]
        FSS["FlutterSecondScreen"]
    end

    subgraph Domain ["Domain Layer (Pure Dart)"]
        DM["SecondScreenDisplayManager"]
        WM["SecondScreenWindowManager"]
        MS["SecondScreenMessenger"]
        Repo["SecondScreenRepository"]
        UseCases["Use Cases (Open, Close, Init, SendEvent, etc.)"]
        Entities["Entities (ScreenDisplay, SecondScreenEvent, SecondScreenConfig)"]
    end

    subgraph Data ["Data Layer"]
        RepoImpl["SecondScreenRepositoryImpl"]
        PI["SecondScreenPlatform (Interface)"]
        DeskPlat["DesktopSecondScreenPlatform"]
        WinPlat["WindowsSecondScreenPlatform"]
        MacPlat["MacosSecondScreenPlatform"]
        AndPlat["AndroidSecondScreenPlatform (TODO / Blueprint)"]
        IosPlat["IosSecondScreenPlatform (TODO / Blueprint)"]
    end

    UI --> Facade
    Facade --> UseCases
    UseCases --> Repo
    RepoImpl -.-> Repo
    RepoImpl --> PI
    PI <|-- DeskPlat
    DeskPlat <|-- WinPlat
    DeskPlat <|-- MacPlat
    PI <|-- AndPlat
    PI <|-- IosPlat
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
cd packages/flutter_second_screen
flutter test
```

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🌟 Support

If you find this package helpful, please consider giving it a ⭐ on [GitHub](https://github.com/yusufhnf/dart_json_schema_prompt) and a 👍 on [pub.dev](https://pub.dev/packages/dart_json_schema_prompt)!