import 'dart:ui';
import 'package:flutter_second_screen/flutter_second_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ScreenDisplay Entity', () {
    test('instantiates and provides effectiveSize and effectivePosition', () {
      const display = ScreenDisplay(
        id: 1,
        name: 'Secondary Monitor',
        size: Size(1920, 1080),
        visibleSize: Size(1920, 1040),
        position: Offset(1920, 0),
        visiblePosition: Offset(1920, 0),
        isPrimary: false,
      );

      expect(display.id, 1);
      expect(display.name, 'Secondary Monitor');
      expect(display.effectiveSize, const Size(1920, 1040));
      expect(display.effectivePosition, const Offset(1920, 0));
      expect(display.isPrimary, isFalse);
    });

    test('falls back to size and Offset.zero when visible metrics are null', () {
      const display = ScreenDisplay(
        id: 0,
        name: 'Primary Monitor',
        size: Size(1440, 900),
        isPrimary: true,
      );

      expect(display.effectiveSize, const Size(1440, 900));
      expect(display.effectivePosition, Offset.zero);
      expect(display.isPrimary, isTrue);
    });

    test('supports equality and hashCode', () {
      const display1 = ScreenDisplay(
        id: 0,
        name: 'Display 0',
        size: Size(1920, 1080),
      );
      const display2 = ScreenDisplay(
        id: 0,
        name: 'Display 0',
        size: Size(1920, 1080),
      );

      expect(display1, equals(display2));
      expect(display1.hashCode, equals(display2.hashCode));
      expect(display1.toString(), contains('Display 0'));
    });
  });

  group('SecondScreenEvent Entity', () {
    test('instantiates with defaults and custom properties', () {
      final now = DateTime.now();
      final event = SecondScreenEvent<String>(
        name: 'test_event',
        data: 'payload_data',
        fromWindowId: 0,
        toWindowId: 1,
        timestamp: now,
      );

      expect(event.name, 'test_event');
      expect(event.data, 'payload_data');
      expect(event.fromWindowId, 0);
      expect(event.toWindowId, 1);
      expect(event.timestamp, now);
    });

    test('supports equality and hashCode', () {
      final event1 = SecondScreenEvent<int>(
        name: 'counter',
        data: 42,
        fromWindowId: 1,
        toWindowId: 0,
      );
      final event2 = SecondScreenEvent<int>(
        name: 'counter',
        data: 42,
        fromWindowId: 1,
        toWindowId: 0,
      );

      expect(event1, equals(event2));
      expect(event1.hashCode, equals(event2.hashCode));
      expect(event1.toString(), contains('counter'));
    });
  });

  group('SecondScreenConfig Entity', () {
    test('provides sensible defaults', () {
      const config = SecondScreenConfig();

      expect(config.title, 'Customer Display');
      expect(config.fullScreen, isTrue);
      expect(config.center, isTrue);
      expect(config.skipTaskbar, isFalse);
      expect(config.routeArguments, ['second-screen']);
    });

    test('supports custom overrides and equality', () {
      const config1 = SecondScreenConfig(
        title: 'POS Screen',
        fullScreen: false,
        size: Size(800, 600),
      );
      const config2 = SecondScreenConfig(
        title: 'POS Screen',
        fullScreen: false,
        size: Size(800, 600),
      );

      expect(config1, equals(config2));
      expect(config1.hashCode, equals(config2.hashCode));
    });

    test('supports copyWith', () {
      const config = SecondScreenConfig(title: 'Default');
      final updated = config.copyWith(title: 'Updated', fullScreen: false, alwaysOnTop: true);

      expect(updated.title, 'Updated');
      expect(updated.fullScreen, isFalse);
      expect(updated.alwaysOnTop, isTrue);
      expect(updated.center, isTrue);
    });
  });

  group('FlutterSecondScreen Static Helpers', () {
    test('isSecondaryScreen and isMainScreen correctly identify launch mode', () {
      expect(FlutterSecondScreen.isSecondaryScreen(['second-screen']), isTrue);
      expect(FlutterSecondScreen.isSecondaryScreen(['1', 'second-screen']), isTrue);
      expect(FlutterSecondScreen.isSecondaryScreen([]), isFalse);
      expect(FlutterSecondScreen.isMainScreen([]), isTrue);
      expect(FlutterSecondScreen.isMainScreen(['second-screen']), isFalse);
    });

    test('getWindowIdFromArgs parses window id or defaults to 0', () {
      expect(FlutterSecondScreen.getWindowIdFromArgs([]), 0);
      expect(FlutterSecondScreen.getWindowIdFromArgs(['1', 'second-screen']), 1);
      expect(FlutterSecondScreen.getWindowIdFromArgs(['invalid']), 0);
    });
  });
}

