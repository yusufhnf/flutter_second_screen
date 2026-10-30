import '../entities/second_screen_event.dart';
import '../repositories/second_screen_messenger.dart';

/// Use case to subscribe to incoming cross-screen events.
class ListenSecondaryScreenEventsUseCase {
  final SecondScreenMessenger _messenger;

  const ListenSecondaryScreenEventsUseCase(this._messenger);

  /// Streams all incoming events.
  Stream<SecondScreenEvent<dynamic>> call() {
    return _messenger.eventStream;
  }

  /// Streams incoming events matching [eventName].
  Stream<T?> on<T>(String eventName) {
    return _messenger.on<T>(eventName);
  }
}

