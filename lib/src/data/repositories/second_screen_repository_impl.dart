import 'dart:async';

import '../../domain/entities/screen_display.dart';
import '../../domain/entities/second_screen_config.dart';
import '../../domain/entities/second_screen_event.dart';
import '../../domain/repositories/second_screen_repository.dart';
import '../datasources/second_screen_platform.dart';

/// Implementation of [SecondScreenRepository] coordinating platform datasources
/// with domain models and event subscriptions.
class SecondScreenRepositoryImpl implements SecondScreenRepository {
  final SecondScreenPlatform _platform;
  final Map<String, List<void Function(dynamic)>> _listeners = {};
  StreamSubscription<SecondScreenEvent<dynamic>>? _platformEventSubscription;

  SecondScreenRepositoryImpl({SecondScreenPlatform? platform})
      : _platform = platform ?? SecondScreenPlatform.instance;

  void _ensureEventListener() {
    _platformEventSubscription ??= _platform.eventStream.listen((event) {
      final callbacks = _listeners[event.name];
      if (callbacks != null) {
        // Create copy of list to prevent concurrent modification if a listener unsubscribes
        for (final callback in List<void Function(dynamic)>.from(callbacks)) {
          try {
            callback(event.data);
          } catch (_) {}
        }
      }
    });
  }

  // --- Display Manager Implementation ---

  @override
  Future<List<ScreenDisplay>> getDisplays() {
    return _platform.getDisplays();
  }

  @override
  Future<ScreenDisplay?> getPrimaryDisplay() async {
    final displays = await getDisplays();
    if (displays.isEmpty) return null;
    try {
      return displays.firstWhere((d) => d.isPrimary);
    } catch (_) {
      return displays.first;
    }
  }

  @override
  Future<ScreenDisplay?> getSecondaryDisplay() async {
    final displays = await getDisplays();
    if (displays.length <= 1) return null;
    return displays[1];
  }

  @override
  Future<bool> hasSecondaryDisplay() async {
    final displays = await getDisplays();
    return displays.length > 1;
  }

  // --- Window Manager Implementation ---

  @override
  Future<bool> initSecondaryDisplay([SecondScreenConfig? config]) {
    return _platform.initSecondaryDisplay(config);
  }

  @override
  Future<void> openSecondaryScreen({
    List<String> arguments = const ['second-screen'],
  }) {
    return _platform.openSecondaryScreen(arguments: arguments);
  }

  @override
  Future<void> closeSecondaryScreen() {
    return _platform.closeSecondaryScreen();
  }

  @override
  Future<void> focusSecondaryScreen() {
    return _platform.focusSecondaryScreen();
  }

  @override
  Future<void> closeAllScreens() {
    return _platform.closeAllScreens();
  }

  @override
  Future<bool> isSecondaryScreenOpen() {
    return _platform.isSecondaryScreenOpen();
  }

  @override
  Future<bool> isSecondaryDisplayAvailable() {
    return _platform.isSecondaryDisplayAvailable();
  }

  // --- Messenger Implementation ---

  @override
  Future<void> sendEventToSecondary(String eventName, [dynamic data]) {
    return _platform.sendEvent(eventName, data, targetWindowId: 1);
  }

  @override
  Future<void> sendEventToMain(String eventName, [dynamic data]) {
    return _platform.sendEvent(eventName, data, targetWindowId: 0);
  }

  @override
  Future<void> sendEventToWindow(
    int windowId,
    String eventName, [
    dynamic data,
  ]) {
    return _platform.sendEvent(eventName, data, targetWindowId: windowId);
  }

  @override
  Stream<SecondScreenEvent<dynamic>> get eventStream => _platform.eventStream;

  @override
  Stream<T?> on<T>(String eventName) {
    return _platform.eventStream
        .where((event) => event.name == eventName)
        .map((event) => event.data is T ? event.data as T : null);
  }

  @override
  void addEventListener(
    String eventName,
    void Function(dynamic data) listener,
  ) {
    _ensureEventListener();
    _listeners.putIfAbsent(eventName, () => []).add(listener);
  }

  @override
  void removeEventListener(
    String eventName,
    void Function(dynamic data) listener,
  ) {
    final list = _listeners[eventName];
    if (list != null) {
      list.remove(listener);
      if (list.isEmpty) {
        _listeners.remove(eventName);
      }
    }
  }

  /// Disposes the repository and cleans up listeners.
  void dispose() {
    _platformEventSubscription?.cancel();
    _platformEventSubscription = null;
    _listeners.clear();
  }
}

