import '../entities/second_screen_config.dart';

/// Contract for managing the lifecycle of the secondary screen window.
abstract interface class SecondScreenWindowManager {
  /// Initializes the secondary screen display according to [config].
  ///
  /// Typically called from the secondary screen process when launched.
  /// Returns `true` if initialization succeeded, or `false` otherwise.
  Future<bool> initSecondaryDisplay([SecondScreenConfig? config]);

  /// Opens the secondary screen window if a second physical display is available
  /// and the secondary screen window is not already open.
  ///
  /// [arguments] contains CLI/process parameters passed to the secondary window.
  Future<void> openSecondaryScreen({List<String> arguments = const ['second-screen']});

  /// Closes the secondary screen window.
  Future<void> closeSecondaryScreen();

  /// Brings the secondary screen window to the foreground.
  Future<void> focusSecondaryScreen();

  /// Closes all managed application windows.
  Future<void> closeAllScreens();

  /// Checks if the secondary screen window is currently open.
  Future<bool> isSecondaryScreenOpen();

  /// Checks if the environment is ready to open a secondary screen
  /// (i.e. secondary display is connected and window is not yet opened).
  Future<bool> isSecondaryDisplayAvailable();
}

