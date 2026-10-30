import 'dart:async';

import '../entities/second_screen_event.dart';

/// Contract for dispatching and receiving messages/events between screens.
abstract interface class SecondScreenMessenger {
  /// Sends an event from the current screen to the secondary screen (window ID 1).
  Future<void> sendEventToSecondary(String eventName, [dynamic data]);

  /// Sends an event from the current screen to the primary screen (window ID 0).
  Future<void> sendEventToMain(String eventName, [dynamic data]);

  /// Sends an event to a specific target window by [windowId].
  Future<void> sendEventToWindow(
    int windowId,
    String eventName, [
    dynamic data,
  ]);

  /// A broadcast stream of all incoming events received by this screen.
  Stream<SecondScreenEvent<dynamic>> get eventStream;

  /// A typed stream filtered for events matching [eventName].
  Stream<T?> on<T>(String eventName);

  /// Subscribes a callback to incoming events matching [eventName].
  void addEventListener(String eventName, void Function(dynamic data) listener);

  /// Unsubscribes a callback from incoming events matching [eventName].
  void removeEventListener(
    String eventName,
    void Function(dynamic data) listener,
  );
}
