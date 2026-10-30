import '../entities/second_screen_config.dart';
import '../repositories/second_screen_window_manager.dart';

/// Use case to initialize the secondary screen display.
class InitSecondaryDisplayUseCase {
  final SecondScreenWindowManager _windowManager;

  const InitSecondaryDisplayUseCase(this._windowManager);

  Future<bool> call([SecondScreenConfig? config]) {
    return _windowManager.initSecondaryDisplay(config);
  }
}

