import 'desktop_second_screen_platform.dart';
import 'second_screen_platform.dart';

/// Windows Desktop implementation of [SecondScreenPlatform].
///
/// Inherits shared desktop multi-window and display logic from [DesktopSecondScreenPlatform].
class WindowsSecondScreenPlatform extends DesktopSecondScreenPlatform {
  /// Registers this class as the default instance of [SecondScreenPlatform].
  static void registerWith() {
    SecondScreenPlatform.instance = WindowsSecondScreenPlatform();
  }
}
