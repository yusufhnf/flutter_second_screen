import '../repositories/second_screen_messenger.dart';

/// Use case to dispatch an event or message to the secondary screen.
class SendEventToSecondaryUseCase {
  final SecondScreenMessenger _messenger;

  const SendEventToSecondaryUseCase(this._messenger);

  Future<void> call(String eventName, [dynamic data]) {
    return _messenger.sendEventToSecondary(eventName, data);
  }
}

