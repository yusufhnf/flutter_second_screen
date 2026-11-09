import 'dart:ui';

import '../../domain/entities/second_screen_config.dart';

/// Data model for [SecondScreenConfig] with serialization utilities for the
/// native desktop window channel.
class SecondScreenConfigModel extends SecondScreenConfig {
  const SecondScreenConfigModel({
    super.title,
    super.fullScreen,
    super.center,
    super.skipTaskbar,
    super.backgroundColor,
    super.size,
    super.position,
    super.routeArguments,
    super.resizable,
    super.alwaysOnTop,
    super.maximize,
  });

  /// Creates a model from a domain [SecondScreenConfig] entity.
  factory SecondScreenConfigModel.fromEntity(SecondScreenConfig config) {
    return SecondScreenConfigModel(
      title: config.title,
      fullScreen: config.fullScreen,
      center: config.center,
      skipTaskbar: config.skipTaskbar,
      backgroundColor: config.backgroundColor,
      size: config.size,
      position: config.position,
      routeArguments: config.routeArguments,
      resizable: config.resizable,
      alwaysOnTop: config.alwaysOnTop,
      maximize: config.maximize,
    );
  }

  /// Serializes this config into the native window options map.
  ///
  /// [fallbackSize] and [fallbackPosition] are used when [size] or [position]
  /// are not set, typically resolved from the target display.
  Map<String, dynamic> toMap({Size? fallbackSize, Offset? fallbackPosition}) {
    final effectiveSize = size ?? fallbackSize;
    final effectivePosition = position ?? fallbackPosition;
    return {
      'title': title,
      'fullScreen': fullScreen,
      'center': center,
      'skipTaskbar': skipTaskbar,
      // `Color.value` keeps compatibility with Flutter < 3.27 (no `toARGB32`).
      // ignore: deprecated_member_use
      'backgroundColor': backgroundColor.value,
      if (effectiveSize != null) ...{
        'width': effectiveSize.width,
        'height': effectiveSize.height,
      },
      if (effectivePosition != null) ...{
        'x': effectivePosition.dx,
        'y': effectivePosition.dy,
      },
      'resizable': resizable,
      'alwaysOnTop': alwaysOnTop,
      'maximize': maximize,
    };
  }

  /// Converts this model to a domain [SecondScreenConfig] entity.
  SecondScreenConfig toEntity() {
    return SecondScreenConfig(
      title: title,
      fullScreen: fullScreen,
      center: center,
      skipTaskbar: skipTaskbar,
      backgroundColor: backgroundColor,
      size: size,
      position: position,
      routeArguments: routeArguments,
      resizable: resizable,
      alwaysOnTop: alwaysOnTop,
      maximize: maximize,
    );
  }
}
