import '../repositories/second_screen_messenger.dart';

/// Use case to dispatch an event or message to the primary (main) screen.
class SendEventToMainUseCase {
  final SecondScreenMessenger _messenger;

  const SendEventToMainUseCase(this._messenger);

  Future<void> call(String eventName, [dynamic data]) {
    return _messenger.sendEventToMain(eventName, data);
  }
}
