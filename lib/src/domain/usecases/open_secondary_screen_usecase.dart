import '../repositories/second_screen_window_manager.dart';

/// Use case to open the secondary screen window.
class OpenSecondaryScreenUseCase {
  final SecondScreenWindowManager _windowManager;

  const OpenSecondaryScreenUseCase(this._windowManager);

  Future<void> call({List<String> arguments = const ['second-screen']}) {
    return _windowManager.openSecondaryScreen(arguments: arguments);
  }
}
