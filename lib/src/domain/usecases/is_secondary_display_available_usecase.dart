import '../repositories/second_screen_window_manager.dart';

/// Use case to verify if a secondary physical display is available for opening.
class IsSecondaryDisplayAvailableUseCase {
  final SecondScreenWindowManager _windowManager;

  const IsSecondaryDisplayAvailableUseCase(this._windowManager);

  Future<bool> call() {
    return _windowManager.isSecondaryDisplayAvailable();
  }
}
