import 'dart:async';

import 'data/datasources/second_screen_platform.dart';
import 'data/repositories/second_screen_repository_impl.dart';
import 'domain/entities/screen_display.dart';
import 'domain/entities/second_screen_config.dart';
import 'domain/entities/second_screen_event.dart';
import 'domain/repositories/second_screen_display_manager.dart';
import 'domain/repositories/second_screen_messenger.dart';
import 'domain/repositories/second_screen_repository.dart';
import 'domain/repositories/second_screen_window_manager.dart';
import 'domain/usecases/usecases.dart';

/// The central entry point and facade for the `flutter_second_screen` package.
///
/// Implements [SecondScreenRepository] and provides convenient access to
/// domain use cases, display queries, window management, and cross-screen messaging.
class FlutterSecondScreen implements SecondScreenRepository {
  static FlutterSecondScreen? _instance;

  /// Global singleton instance.
  static FlutterSecondScreen get instance => _instance ??= FlutterSecondScreen();

  /// Sets or overrides the singleton instance (e.g. for testing).
  static set instance(FlutterSecondScreen customInstance) {
    _instance = customInstance;
  }

  /// Ensures native windowing and platform hooks are initialized before accessing windows.
  ///
  /// Call this at the start of [main]:
  /// ```dart
  /// void main(List<String> args) async {
  ///   WidgetsFlutterBinding.ensureInitialized();
  ///   await FlutterSecondScreen.ensureInitialized(args);
  ///   ...
  /// }
  /// ```
  static Future<void> ensureInitialized([List<String> args = const []]) =>
      SecondScreenPlatform.instance.ensureInitialized(args);

  /// Helper to check if the current launch process is running as the secondary screen.
  ///
  /// Checks whether [args] contains [flag] (defaults to `'second-screen'`).
  static bool isSecondaryScreen(List<String> args, {String flag = 'second-screen'}) =>
      args.contains(flag);

  /// Helper to check if the current launch process is running as the primary/main screen.
  static bool isMainScreen(List<String> args, {String flag = 'second-screen'}) =>
      !args.contains(flag);

  /// Extracts the integer window ID from launch [args], defaulting to `0` for the primary window.
  static int getWindowIdFromArgs(List<String> args) =>
      args.isEmpty ? 0 : int.tryParse(args[0]) ?? 0;

  final SecondScreenRepository _repository;

  // Use cases
  late final InitSecondaryDisplayUseCase initSecondaryDisplayUseCase;
  late final OpenSecondaryScreenUseCase openSecondaryScreenUseCase;
  late final CloseSecondaryScreenUseCase closeSecondaryScreenUseCase;
  late final SendEventToSecondaryUseCase sendEventToSecondaryUseCase;
  late final SendEventToMainUseCase sendEventToMainUseCase;
  late final IsSecondaryScreenOpenUseCase isSecondaryScreenOpenUseCase;
  late final IsSecondaryDisplayAvailableUseCase isSecondaryDisplayAvailableUseCase;
  late final GetDisplaysUseCase getDisplaysUseCase;
  late final ListenSecondaryScreenEventsUseCase listenSecondaryScreenEventsUseCase;

  /// Creates a [FlutterSecondScreen] instance.
  ///
  /// Optionally injects a custom [repository] or [platform].
  FlutterSecondScreen({
    SecondScreenRepository? repository,
    SecondScreenPlatform? platform,
  }) : _repository = repository ?? SecondScreenRepositoryImpl(platform: platform) {
    initSecondaryDisplayUseCase = InitSecondaryDisplayUseCase(_repository);
    openSecondaryScreenUseCase = OpenSecondaryScreenUseCase(_repository);
    closeSecondaryScreenUseCase = CloseSecondaryScreenUseCase(_repository);
    sendEventToSecondaryUseCase = SendEventToSecondaryUseCase(_repository);
    sendEventToMainUseCase = SendEventToMainUseCase(_repository);
    isSecondaryScreenOpenUseCase = IsSecondaryScreenOpenUseCase(_repository);
    isSecondaryDisplayAvailableUseCase = IsSecondaryDisplayAvailableUseCase(_repository);
    getDisplaysUseCase = GetDisplaysUseCase(_repository);
    listenSecondaryScreenEventsUseCase = ListenSecondaryScreenEventsUseCase(_repository);
  }

  /// Direct reference to the display manager interface.
  SecondScreenDisplayManager get displayManager => _repository;

  /// Direct reference to the window manager interface.
  SecondScreenWindowManager get windowManager => _repository;

  /// Direct reference to the messenger interface.
  SecondScreenMessenger get messenger => _repository;

  // --- Display Manager Implementation ---

  @override
  Future<List<ScreenDisplay>> getDisplays() => getDisplaysUseCase();

  @override
  Future<ScreenDisplay?> getPrimaryDisplay() => _repository.getPrimaryDisplay();

  @override
  Future<ScreenDisplay?> getSecondaryDisplay() => _repository.getSecondaryDisplay();

  @override
  Future<bool> hasSecondaryDisplay() => _repository.hasSecondaryDisplay();

  // --- Window Manager Implementation ---

  @override
  Future<bool> initSecondaryDisplay([SecondScreenConfig? config]) =>
      initSecondaryDisplayUseCase(config);

  @override
  Future<void> openSecondaryScreen({
    List<String> arguments = const ['second-screen'],
  }) =>
      openSecondaryScreenUseCase(arguments: arguments);

  @override
  Future<void> closeSecondaryScreen() => closeSecondaryScreenUseCase();

  @override
  Future<void> focusSecondaryScreen() => _repository.focusSecondaryScreen();

  @override
  Future<void> closeAllScreens() => _repository.closeAllScreens();

  @override
  Future<bool> isSecondaryScreenOpen() => isSecondaryScreenOpenUseCase();

  @override
  Future<bool> isSecondaryDisplayAvailable() =>
      isSecondaryDisplayAvailableUseCase();

  // --- Messenger Implementation ---

  @override
  Future<void> sendEventToSecondary(String eventName, [dynamic data]) =>
      sendEventToSecondaryUseCase(eventName, data);

  @override
  Future<void> sendEventToMain(String eventName, [dynamic data]) =>
      sendEventToMainUseCase(eventName, data);

  @override
  Future<void> sendEventToWindow(
    int windowId,
    String eventName, [
    dynamic data,
  ]) =>
      _repository.sendEventToWindow(windowId, eventName, data);

  @override
  Stream<SecondScreenEvent<dynamic>> get eventStream =>
      listenSecondaryScreenEventsUseCase();

  @override
  Stream<T?> on<T>(String eventName) =>
      listenSecondaryScreenEventsUseCase.on<T>(eventName);

  @override
  void addEventListener(
    String eventName,
    void Function(dynamic data) listener,
  ) =>
      _repository.addEventListener(eventName, listener);

  @override
  void removeEventListener(
    String eventName,
    void Function(dynamic data) listener,
  ) =>
      _repository.removeEventListener(eventName, listener);
}

