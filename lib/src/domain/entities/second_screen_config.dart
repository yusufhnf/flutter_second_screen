import 'dart:ui';

/// Configuration options for setting up the secondary screen window.
class SecondScreenConfig {
  /// Window title for the secondary screen.
  final String title;

  /// Whether the secondary window should start in full screen mode.
  final bool fullScreen;

  /// Whether to center the window initially.
  final bool center;

  /// Whether the window should skip the OS taskbar.
  final bool skipTaskbar;

  /// Background color of the window.
  final Color backgroundColor;

  /// Custom size if not matching the display visible size.
  final Size? size;

  /// Custom initial position.
  final Offset? position;

  /// CLI or process arguments passed when creating the secondary window.
  final List<String> routeArguments;

  /// Whether the secondary window should be resizable by the user.
  final bool resizable;

  /// Whether the secondary window should stay on top of other windows.
  final bool alwaysOnTop;

  /// Whether the window should be maximized upon display.
  final bool maximize;

  const SecondScreenConfig({
    this.title = 'Customer Display',
    this.fullScreen = true,
    this.center = true,
    this.skipTaskbar = false,
    this.backgroundColor = const Color(0x00000000),
    this.size,
    this.position,
    this.routeArguments = const ['second-screen'],
    this.resizable = false,
    this.alwaysOnTop = false,
    this.maximize = true,
  });

  /// Creates a copy of this config with modified properties.
  SecondScreenConfig copyWith({
    String? title,
    bool? fullScreen,
    bool? center,
    bool? skipTaskbar,
    Color? backgroundColor,
    Size? size,
    Offset? position,
    List<String>? routeArguments,
    bool? resizable,
    bool? alwaysOnTop,
    bool? maximize,
  }) {
    return SecondScreenConfig(
      title: title ?? this.title,
      fullScreen: fullScreen ?? this.fullScreen,
      center: center ?? this.center,
      skipTaskbar: skipTaskbar ?? this.skipTaskbar,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      size: size ?? this.size,
      position: position ?? this.position,
      routeArguments: routeArguments ?? this.routeArguments,
      resizable: resizable ?? this.resizable,
      alwaysOnTop: alwaysOnTop ?? this.alwaysOnTop,
      maximize: maximize ?? this.maximize,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SecondScreenConfig &&
          runtimeType == other.runtimeType &&
          title == other.title &&
          fullScreen == other.fullScreen &&
          center == other.center &&
          skipTaskbar == other.skipTaskbar &&
          backgroundColor == other.backgroundColor &&
          size == other.size &&
          position == other.position &&
          resizable == other.resizable &&
          alwaysOnTop == other.alwaysOnTop &&
          maximize == other.maximize;

  @override
  int get hashCode => Object.hash(
        title,
        fullScreen,
        center,
        skipTaskbar,
        backgroundColor,
        size,
        position,
        resizable,
        alwaysOnTop,
        maximize,
      );
}
