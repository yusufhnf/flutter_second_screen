import 'dart:convert';

import '../../domain/entities/second_screen_event.dart';

/// Data model representing an event with serialization utilities.
class SecondScreenEventModel<T> extends SecondScreenEvent<T> {
  SecondScreenEventModel({
    required super.name,
    super.data,
    super.fromWindowId,
    super.toWindowId,
    super.timestamp,
  });

  /// Creates a model from raw data coming from a window method call or platform channel.
  factory SecondScreenEventModel.fromRaw(
    String name,
    dynamic rawData, {
    int fromWindowId = 0,
    int? toWindowId,
  }) {
    T? parsedData;
    if (rawData is T) {
      parsedData = rawData;
    } else if (rawData is String && T != String) {
      try {
        final decoded = jsonDecode(rawData);
        if (decoded is T) {
          parsedData = decoded;
        }
      } catch (_) {
        // Fall back if decoding is not JSON
      }
    }

    return SecondScreenEventModel<T>(
      name: name,
      data: parsedData ?? (rawData is T ? rawData : null),
      fromWindowId: fromWindowId,
      toWindowId: toWindowId,
    );
  }

  /// Converts this model to a domain [SecondScreenEvent] entity.
  SecondScreenEvent<T> toEntity() {
    return SecondScreenEvent<T>(
      name: name,
      data: data,
      fromWindowId: fromWindowId,
      toWindowId: toWindowId,
      timestamp: timestamp,
    );
  }
}

