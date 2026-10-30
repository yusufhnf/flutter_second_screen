import 'dart:ui';
import 'package:screen_retriever/screen_retriever.dart' as sr;

import '../../domain/entities/screen_display.dart';

/// Data transfer model for [ScreenDisplay], adapting from external display sources.
class ScreenDisplayModel extends ScreenDisplay {
  const ScreenDisplayModel({
    required super.id,
    required super.name,
    required super.size,
    super.visibleSize,
    super.position,
    super.visiblePosition,
    super.isPrimary,
  });

  /// Factory constructor to convert from `screen_retriever`'s [sr.Display].
  factory ScreenDisplayModel.fromScreenRetriever(sr.Display display, int id,
      {bool isPrimary = false}) {
    return ScreenDisplayModel(
      id: id,
      name: display.name ?? 'Display $id',
      size: display.size,
      visibleSize: display.visibleSize,
      position: display.visiblePosition,
      visiblePosition: display.visiblePosition,
      isPrimary: isPrimary,
    );
  }

  /// Converts this model to a domain [ScreenDisplay] entity.
  ScreenDisplay toEntity() {
    return ScreenDisplay(
      id: id,
      name: name,
      size: size,
      visibleSize: visibleSize,
      position: position,
      visiblePosition: visiblePosition,
      isPrimary: isPrimary,
    );
  }

  /// Deserializes a map representation to [ScreenDisplayModel].
  factory ScreenDisplayModel.fromMap(Map<String, dynamic> map) {
    return ScreenDisplayModel(
      id: map['id'] as int? ?? 0,
      name: map['name'] as String? ?? '',
      size: Size(
        (map['width'] as num?)?.toDouble() ?? 0.0,
        (map['height'] as num?)?.toDouble() ?? 0.0,
      ),
      visibleSize:
          map.containsKey('visibleWidth') && map.containsKey('visibleHeight')
              ? Size(
                  (map['visibleWidth'] as num?)?.toDouble() ?? 0.0,
                  (map['visibleHeight'] as num?)?.toDouble() ?? 0.0,
                )
              : null,
      position: map.containsKey('x') && map.containsKey('y')
          ? Offset(
              (map['x'] as num?)?.toDouble() ?? 0.0,
              (map['y'] as num?)?.toDouble() ?? 0.0,
            )
          : null,
      isPrimary: map['isPrimary'] as bool? ?? false,
    );
  }

  /// Serializes this model into a map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'width': size.width,
      'height': size.height,
      if (visibleSize != null) ...{
        'visibleWidth': visibleSize!.width,
        'visibleHeight': visibleSize!.height,
      },
      if (position != null) ...{
        'x': position!.dx,
        'y': position!.dy,
      },
      'isPrimary': isPrimary,
    };
  }
}
