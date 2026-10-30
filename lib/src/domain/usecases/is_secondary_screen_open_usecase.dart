import '../repositories/second_screen_window_manager.dart';

/// Use case to verify if the secondary screen window is currently open.
class IsSecondaryScreenOpenUseCase {
  final SecondScreenWindowManager _windowManager;

  const IsSecondaryScreenOpenUseCase(this._windowManager);

  Future<bool> call() {
    return _windowManager.isSecondaryScreenOpen();
  }
}
