import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../domain/entities/screen_display.dart';
import '../../domain/entities/second_screen_config.dart';
import '../../domain/entities/second_screen_event.dart';
import '../../domain/entities/second_screen_exception.dart';
import '../models/screen_display_model.dart';
import '../models/second_screen_config_model.dart';
import '../models/second_screen_event_model.dart';
import 'second_screen_platform.dart';

/// Base desktop (Windows & macOS) implementation of [SecondScreenPlatform].
///
/// Manages multi-window lifecycle, multi-display detection, and cross-window
/// messaging through the package's own native desktop plugin
/// (`FlutterSecondScreenPlugin`). Each window runs its own Flutter engine and
/// talks to the native side over [methodChannel].
class DesktopSecondScreenPlatform extends SecondScreenPlatform {
  /// Method Channel shared by every window engine for native desktop operations.
  static const MethodChannel _methodChannel =
      MethodChannel('com.meetucup.flutter_second_screen/desktop_methods');

  /// Window ID of the primary/main window.
  static const int mainWindowId = 0;

  /// Window ID of the secondary screen window.
  static const int secondaryWindowId = 1;

  /// Accessor for the native desktop method channel.
  @visibleForTesting
  MethodChannel get methodChannel => _methodChannel;

  final StreamController<SecondScreenEvent<dynamic>> _eventController =
      StreamController<SecondScreenEvent<dynamic>>.broadcast();

  bool _isHandlerRegistered = false;

  int _windowId = mainWindowId;

  /// The ID of the window running this engine.
  int get windowId => _windowId;

  DesktopSecondScreenPlatform();

  void _ensureMethodCallHandlerRegistered() {
    if (!_isHandlerRegistered) {
      try {
        _methodChannel.setMethodCallHandler(handleMethodCall);
        _isHandlerRegistered = true;
      } catch (_) {
        // Can fail if the binding is not yet initialized or in unit test environment.
      }
    }
  }

  @override
  Future<void> ensureInitialized([List<String> args = const []]) async {
    _windowId = args.isEmpty ? mainWindowId : int.tryParse(args[0]) ?? 0;
    _ensureMethodCallHandlerRegistered();
    try {
      await _methodChannel.invokeMethod<void>(
        'ensureInitialized',
        {'windowId': _windowId},
      );
    } catch (_) {
      // Handles hot restart or unit test runner environments
    }
  }

  @override
  Stream<SecondScreenEvent<dynamic>> get eventStream {
    _ensureMethodCallHandlerRegistered();
    return _eventController.stream;
  }

  @override
  Future<bool> initSecondaryDisplay([SecondScreenConfig? config]) async {
    try {
      final effectiveConfig = SecondScreenConfigModel.fromEntity(
        config ?? const SecondScreenConfig(),
      );
      final displays = await getDisplays();
      if (displays.length <= 1) {
        // Nothing to show on: release the hidden secondary window so the
        // main window can open it again once a display is connected.
        await _closeOwnSecondaryWindow();
        return false;
      }

      final secondDisplay = displays[1];
      final windowOptions = effectiveConfig.toMap(
        fallbackSize: secondDisplay.visibleSize ?? secondDisplay.size,
        fallbackPosition: secondDisplay.visiblePosition ?? Offset.zero,
      );

      return await _methodChannel.invokeMethod<bool>(
            'configureWindow',
            windowOptions,
          ) ??
          false;
    } catch (e, stack) {
      debugPrint('initSecondaryDisplay failed: $e\n$stack');
      return false;
    }
  }

  @override
  Future<void> openSecondaryScreen({
    List<String> arguments = const ['second-screen'],
  }) async {
    final isOpen = await isSecondaryScreenOpen();
    if (isOpen) return;
    try {
      await _methodChannel.invokeMethod<int>(
        'createWindow',
        {'arguments': arguments},
      );
    } on PlatformException catch (e) {
      throw SecondScreenException(
        e.code == 'UNAVAILABLE'
            ? SecondScreenException.setupRequired
            : SecondScreenException.createFailed,
        e.message ?? 'Failed to create the secondary window.',
      );
    }
  }

  @override
  Future<void> closeSecondaryScreen() async {
    final windowIds = await _getWindowIds();
    await _closeWindow(
      windowIds.contains(secondaryWindowId) ? secondaryWindowId : _windowId,
    );
  }

  @override
  Future<void> focusSecondaryScreen() async {
    final windowIds = await _getWindowIds();
    if (windowIds.contains(secondaryWindowId)) {
      await _methodChannel.invokeMethod<void>(
        'focusWindow',
        {'windowId': secondaryWindowId},
      );
    }
  }

  @override
  Future<void> closeAllScreens() async {
    final windowIds = await _getWindowIds();
    await Future.wait(windowIds.map(_closeWindow));
  }

  @override
  Future<bool> isSecondaryScreenOpen() async {
    final windowIds = await _getWindowIds();
    return windowIds.length > 1;
  }

  @override
  Future<bool> isSecondaryDisplayAvailable() async {
    final displays = await getDisplays();
    final windowIds = await _getWindowIds();
    return windowIds.length <= 1 && displays.length > 1;
  }

  @override
  Future<List<ScreenDisplay>> getDisplays() async {
    final displays = await _methodChannel
            .invokeListMethod<Map<dynamic, dynamic>>('getDisplays') ??
        const [];
    return displays.asMap().entries.map((entry) {
      return ScreenDisplayModel.fromMap({
        ...Map<String, dynamic>.from(entry.value),
        'id': entry.key,
        'isPrimary': entry.key == 0,
      }).toEntity();
    }).toList();
  }

  @override
  Future<void> sendEvent(
    String eventName,
    dynamic data, {
    int? targetWindowId,
  }) async {
    final targetId = targetWindowId ?? secondaryWindowId;
    try {
      await _methodChannel.invokeMethod<dynamic>('sendEvent', {
        'targetWindowId': targetId,
        'eventName': eventName,
        'data': data,
      });
    } on PlatformException catch (e) {
      // Sending to a window that is not open is a no-op, so callers do not
      // need to check `isSecondaryScreenOpen` before every update.
      if (e.code != 'WINDOW_NOT_FOUND') rethrow;
      debugPrint(
        'flutter_second_screen: dropped "$eventName", window $targetId is not open.',
      );
    }
  }

  /// Handles method calls coming from the native desktop plugin.
  @visibleForTesting
  Future<dynamic> handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onEvent':
        final arguments = Map<String, dynamic>.from(
          call.arguments as Map<dynamic, dynamic>? ?? const {},
        );
        return onEventFromWindow(
          arguments['eventName'] as String? ?? '',
          arguments['fromWindowId'] as int? ?? mainWindowId,
          arguments['data'],
        );
      default:
        throw MissingPluginException(
          'No implementation found for method ${call.method}',
        );
    }
  }

  /// Dispatches an incoming cross-window event to [eventStream] listeners.
  Future<dynamic> onEventFromWindow(
    String eventName,
    int fromWindowId,
    dynamic arguments,
  ) async {
    final event = SecondScreenEventModel<dynamic>.fromRaw(
      eventName,
      arguments,
      fromWindowId: fromWindowId,
    ).toEntity();
    _eventController.add(event);
    return null;
  }

  Future<List<int>> _getWindowIds() async {
    final windowIds =
        await _methodChannel.invokeListMethod<int>('getWindowIds');
    return windowIds ?? const [];
  }

  Future<void> _closeOwnSecondaryWindow() async {
    final windowId =
        await _methodChannel.invokeMethod<int>('getWindowId') ?? _windowId;
    if (windowId != mainWindowId) {
      await _closeWindow(windowId);
    }
  }

  Future<void> _closeWindow(int windowId) {
    return _methodChannel.invokeMethod<void>(
      'closeWindow',
      {'windowId': windowId},
    );
  }

  @override
  Future<void> dispose() async {
    if (_isHandlerRegistered) {
      try {
        _methodChannel.setMethodCallHandler(null);
      } catch (_) {}
      _isHandlerRegistered = false;
    }
    await _eventController.close();
  }
}
