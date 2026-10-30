import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import '../../domain/entities/screen_display.dart';
import '../../domain/entities/second_screen_config.dart';
import '../../domain/entities/second_screen_event.dart';
import 'android_second_screen_platform.dart';
import 'desktop_second_screen_platform.dart';
import 'ios_second_screen_platform.dart';
import 'macos_second_screen_platform.dart';
import 'windows_second_screen_platform.dart';

/// The interface that platform implementations of `flutter_second_screen` must extend.
abstract class SecondScreenPlatform extends PlatformInterface {
  /// Constructs a SecondScreenPlatform.
  SecondScreenPlatform() : super(token: _token);

  static final Object _token = Object();

  static SecondScreenPlatform _instance = _createDefaultPlatform();

  /// The current default platform implementation.
  static SecondScreenPlatform get instance => _instance;

  /// Platform-specific plugins should set this with their own platform-specific
  /// class that extends [SecondScreenPlatform] when they register themselves.
  static set instance(SecondScreenPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  static SecondScreenPlatform _createDefaultPlatform() {
    if (!kIsWeb) {
      if (Platform.isWindows) {
        return WindowsSecondScreenPlatform();
      } else if (Platform.isMacOS) {
        return MacosSecondScreenPlatform();
      } else if (Platform.isAndroid) {
        return AndroidSecondScreenPlatform();
      } else if (Platform.isIOS) {
        return IosSecondScreenPlatform();
      }
    }
    // Default fallback to Desktop implementation.
    return DesktopSecondScreenPlatform();
  }

  /// Ensures native windowing and platform hooks are initialized before accessing windows.
  Future<void> ensureInitialized([List<String> args = const []]);

  /// Initializes the secondary screen display according to [config].
  Future<bool> initSecondaryDisplay([SecondScreenConfig? config]);

  /// Opens the secondary screen window or external display presentation.
  Future<void> openSecondaryScreen({List<String> arguments = const ['second-screen']});

  /// Closes the secondary screen window or presentation.
  Future<void> closeSecondaryScreen();

  /// Brings the secondary screen window to the foreground.
  Future<void> focusSecondaryScreen();

  /// Closes all screens.
  Future<void> closeAllScreens();

  /// Checks if the secondary screen is currently open.
  Future<bool> isSecondaryScreenOpen();

  /// Checks if a secondary display is ready and available to open.
  Future<bool> isSecondaryDisplayAvailable();

  /// Retrieves all connected physical displays.
  Future<List<ScreenDisplay>> getDisplays();

  /// Sends an event/message to a target window (e.g. 0 for main, 1 for secondary).
  Future<void> sendEvent(
    String eventName,
    dynamic data, {
    int? targetWindowId,
  });

  /// Stream of incoming cross-screen events.
  Stream<SecondScreenEvent<dynamic>> get eventStream;

  /// Disposes any resources held by the platform implementation.
  Future<void> dispose();
}
