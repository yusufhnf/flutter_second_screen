import 'package:flutter/widgets.dart';

import '../../domain/repositories/second_screen_messenger.dart';
import '../../flutter_second_screen.dart';

/// Mixin providing reactive event handling and cross-screen dispatching
/// capabilities to any [StatefulWidget].
mixin SecondScreenListenerMixin<T extends StatefulWidget> on State<T> {
  final Map<String, void Function(dynamic)> _registeredListeners = {};

  /// Override this getter if you wish to provide a custom or injected [SecondScreenMessenger].
  /// Defaults to the global [FlutterSecondScreen.instance] messenger.
  SecondScreenMessenger get secondScreenMessenger =>
      FlutterSecondScreen.instance;

  @override
  void initState() {
    super.initState();
    _registerEventListeners();
  }

  @override
  void dispose() {
    _unregisterEventListeners();
    super.dispose();
  }

  void _registerEventListeners() {
    final listeners = getSecondScreenEventListeners();
    listeners.forEach((eventName, callback) {
      _registeredListeners[eventName] = callback;
      secondScreenMessenger.addEventListener(eventName, callback);
    });
  }

  void _unregisterEventListeners() {
    _registeredListeners.forEach((eventName, callback) {
      secondScreenMessenger.removeEventListener(eventName, callback);
    });
    _registeredListeners.clear();
  }

  /// Override this method in your State to define which events to listen to.
  /// Returns a map of event names to callback functions.
  Map<String, void Function(dynamic)> getSecondScreenEventListeners() => {};

  /// Sends an event payload to the secondary screen.
  Future<void> sendEventToSecondaryScreen(String eventName, [dynamic data]) {
    return secondScreenMessenger.sendEventToSecondary(eventName, data);
  }

  /// Sends an event payload to the primary (main) screen.
  Future<void> sendEventToMainScreen(String eventName, [dynamic data]) {
    return secondScreenMessenger.sendEventToMain(eventName, data);
  }

  /// Dynamically subscribes to an additional event.
  void subscribeToScreenEvent(
      String eventName, void Function(dynamic) callback) {
    if (!_registeredListeners.containsKey(eventName)) {
      _registeredListeners[eventName] = callback;
      secondScreenMessenger.addEventListener(eventName, callback);
    }
  }

  /// Unsubscribes from an event.
  void unsubscribeFromScreenEvent(String eventName) {
    final callback = _registeredListeners.remove(eventName);
    if (callback != null) {
      secondScreenMessenger.removeEventListener(eventName, callback);
    }
  }
}
