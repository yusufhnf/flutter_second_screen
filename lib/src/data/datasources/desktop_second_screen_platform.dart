import 'dart:async';
import 'package:flutter/material.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager_plus/window_manager_plus.dart';

import '../../domain/entities/screen_display.dart';
import '../../domain/entities/second_screen_config.dart';
import '../../domain/entities/second_screen_event.dart';
import '../models/screen_display_model.dart';
import '../models/second_screen_event_model.dart';
import 'second_screen_platform.dart';

/// Base desktop (Windows & macOS) implementation of [SecondScreenPlatform].
///
/// Manages multi-window lifecycle and multi-display detection using
/// `window_manager_plus` and `screen_retriever`.
class DesktopSecondScreenPlatform extends SecondScreenPlatform with WindowListener {
  final StreamController<SecondScreenEvent<dynamic>> _eventController =
      StreamController<SecondScreenEvent<dynamic>>.broadcast();

  bool _isListenerRegistered = false;

  DesktopSecondScreenPlatform();

  void _ensureWindowListenerRegistered() {
    if (!_isListenerRegistered) {
      try {
        WindowManagerPlus.current.addListener(this);
        _isListenerRegistered = true;
      } catch (_) {
        // Can fail if WindowManagerPlus is not yet initialized or in unit test environment.
      }
    }
  }

  @override
  Future<void> ensureInitialized([List<String> args = const []]) async {
    final windowId = args.isEmpty ? 0 : int.tryParse(args[0]) ?? 0;
    try {
      await WindowManagerPlus.ensureInitialized(windowId);
      _ensureWindowListenerRegistered();
    } catch (_) {
      // Handles hot restart or unit test runner environments
    }
  }

  @override
  Stream<SecondScreenEvent<dynamic>> get eventStream {
    _ensureWindowListenerRegistered();
    return _eventController.stream;
  }

  @override
  Future<bool> initSecondaryDisplay([SecondScreenConfig? config]) async {
    try {
      final effectiveConfig = config ?? const SecondScreenConfig();
      final displays = await screenRetriever.getAllDisplays();
      if (displays.length <= 1) return false;

      final secondDisplay = displays[1];
      final windowOptions = WindowOptions(
        center: effectiveConfig.center,
        backgroundColor: effectiveConfig.backgroundColor,
        skipTaskbar: effectiveConfig.skipTaskbar,
        fullScreen: effectiveConfig.fullScreen,
        size: effectiveConfig.size ?? secondDisplay.visibleSize ?? secondDisplay.size,
        title: effectiveConfig.title,
        titleBarStyle: TitleBarStyle.normal,
      );

      await WindowManagerPlus.current.waitUntilReadyToShow(windowOptions);
      await WindowManagerPlus.current.setPosition(
        effectiveConfig.position ?? secondDisplay.visiblePosition ?? Offset.zero,
      );
      if (effectiveConfig.maximize) {
        await WindowManagerPlus.current.maximize();
      }
      await WindowManagerPlus.current.show();
      await WindowManagerPlus.current.setResizable(effectiveConfig.resizable);
      if (effectiveConfig.alwaysOnTop) {
        await WindowManagerPlus.current.setAlwaysOnTop(true);
      }
      return true;
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
    if (!isOpen) {
      unawaited(WindowManagerPlus.createWindow(arguments));
    }
  }

  @override
  Future<void> closeSecondaryScreen() async {
    final windowIds = await WindowManagerPlus.getAllWindowManagerIds();
    if (windowIds.contains(1)) {
      await WindowManagerPlus.fromWindowId(1).close();
    } else {
      await WindowManagerPlus.current.close();
    }
  }

  @override
  Future<void> focusSecondaryScreen() async {
    final windowIds = await WindowManagerPlus.getAllWindowManagerIds();
    if (windowIds.contains(1)) {
      await WindowManagerPlus.fromWindowId(1).focus();
    }
  }

  @override
  Future<void> closeAllScreens() async {
    final windowIds = await WindowManagerPlus.getAllWindowManagerIds();
    await Future.wait(
      windowIds.map((id) => WindowManagerPlus.fromWindowId(id).close()),
    );
  }

  @override
  Future<bool> isSecondaryScreenOpen() async {
    final windowIds = await WindowManagerPlus.getAllWindowManagerIds();
    return windowIds.length > 1;
  }

  @override
  Future<bool> isSecondaryDisplayAvailable() async {
    final displays = await screenRetriever.getAllDisplays();
    final windowIds = await WindowManagerPlus.getAllWindowManagerIds();
    return windowIds.length <= 1 && displays.length > 1;
  }

  @override
  Future<List<ScreenDisplay>> getDisplays() async {
    final displays = await screenRetriever.getAllDisplays();
    return displays.asMap().entries.map((entry) {
      return ScreenDisplayModel.fromScreenRetriever(
        entry.value,
        entry.key,
        isPrimary: entry.key == 0,
      ).toEntity();
    }).toList();
  }

  @override
  Future<void> sendEvent(
    String eventName,
    dynamic data, {
    int? targetWindowId,
  }) async {
    final targetId = targetWindowId ?? 1;
    await WindowManagerPlus.current.invokeMethodToWindow(
      targetId,
      eventName,
      data,
    );
  }

  @override
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

  @override
  Future<void> dispose() async {
    if (_isListenerRegistered) {
      try {
        WindowManagerPlus.current.removeListener(this);
      } catch (_) {}
      _isListenerRegistered = false;
    }
    await _eventController.close();
  }
}

