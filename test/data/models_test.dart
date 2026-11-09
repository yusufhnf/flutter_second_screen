import 'dart:ui';

import 'package:flutter_second_screen/flutter_second_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ScreenDisplayModel', () {
    test('fromMap and toMap round trip including visible position', () {
      final map = {
        'id': 1,
        'name': 'External Display',
        'width': 1920.0,
        'height': 1080.0,
        'visibleWidth': 1920.0,
        'visibleHeight': 1040.0,
        'x': 1440.0,
        'y': 0.0,
        'visibleX': 1440.0,
        'visibleY': 40.0,
        'isPrimary': false,
      };

      final model = ScreenDisplayModel.fromMap(map);

      expect(model.position, const Offset(1440, 0));
      expect(model.visiblePosition, const Offset(1440, 40));
      expect(model.visibleSize, const Size(1920, 1040));
      expect(model.toMap(), map);
      expect(model.toEntity(), isA<ScreenDisplay>());
    });

    test('fromMap leaves optional values null when absent', () {
      final model = ScreenDisplayModel.fromMap({'width': 800, 'height': 600});

      expect(model.size, const Size(800, 600));
      expect(model.visibleSize, isNull);
      expect(model.position, isNull);
      expect(model.visiblePosition, isNull);
    });
  });

  group('SecondScreenConfigModel', () {
    test('toMap uses fallbacks when size and position are not set', () {
      final model = SecondScreenConfigModel.fromEntity(
        const SecondScreenConfig(backgroundColor: Color(0xFF112233)),
      );

      final map = model.toMap(
        fallbackSize: const Size(1920, 1040),
        fallbackPosition: const Offset(1440, 0),
      );

      expect(map['title'], 'Customer Display');
      expect(map['backgroundColor'], 0xFF112233);
      expect(map['width'], 1920.0);
      expect(map['height'], 1040.0);
      expect(map['x'], 1440.0);
      expect(map['y'], 0.0);
    });

    test('toMap prefers explicit size and position over fallbacks', () {
      final model = SecondScreenConfigModel.fromEntity(
        const SecondScreenConfig(
          size: Size(800, 600),
          position: Offset(10, 20),
        ),
      );

      final map = model.toMap(
        fallbackSize: const Size(1920, 1040),
        fallbackPosition: const Offset(1440, 0),
      );

      expect(map['width'], 800.0);
      expect(map['height'], 600.0);
      expect(map['x'], 10.0);
      expect(map['y'], 20.0);
    });

    test('toMap omits geometry when nothing is resolved', () {
      final map = const SecondScreenConfigModel().toMap();

      expect(map.containsKey('width'), isFalse);
      expect(map.containsKey('x'), isFalse);
    });

    test('toEntity preserves values', () {
      const config = SecondScreenConfig(title: 'Ads', alwaysOnTop: true);

      expect(SecondScreenConfigModel.fromEntity(config).toEntity(), config);
    });
  });
}
