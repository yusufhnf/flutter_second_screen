import '../entities/screen_display.dart';

/// Contract for detecting and querying connected displays.
abstract interface class SecondScreenDisplayManager {
  /// Retrieves all connected physical displays.
  Future<List<ScreenDisplay>> getDisplays();

  /// Retrieves the primary display, or null if none detected.
  Future<ScreenDisplay?> getPrimaryDisplay();

  /// Retrieves the secondary display (e.g. index 1), or null if not available.
  Future<ScreenDisplay?> getSecondaryDisplay();

  /// Returns true if at least two physical displays are connected.
  Future<bool> hasSecondaryDisplay();
}

