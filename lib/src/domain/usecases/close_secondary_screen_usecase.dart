import '../repositories/second_screen_window_manager.dart';

/// Use case to close the secondary screen window.
class CloseSecondaryScreenUseCase {
  final SecondScreenWindowManager _windowManager;

  const CloseSecondaryScreenUseCase(this._windowManager);

  Future<void> call() {
    return _windowManager.closeSecondaryScreen();
  }
}

