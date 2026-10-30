import '../entities/screen_display.dart';
import '../repositories/second_screen_display_manager.dart';

/// Use case to retrieve all currently connected physical displays.
class GetDisplaysUseCase {
  final SecondScreenDisplayManager _displayManager;

  const GetDisplaysUseCase(this._displayManager);

  Future<List<ScreenDisplay>> call() {
    return _displayManager.getDisplays();
  }
}
