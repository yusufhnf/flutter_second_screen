import 'package:flutter_second_screen/flutter_second_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Desktop Platforms (Windows & macOS)', () {
    test(
        'WindowsSecondScreenPlatform registers and inherits from DesktopSecondScreenPlatform',
        () {
      WindowsSecondScreenPlatform.registerWith();
      expect(SecondScreenPlatform.instance, isA<WindowsSecondScreenPlatform>());
      expect(SecondScreenPlatform.instance, isA<DesktopSecondScreenPlatform>());
    });

    test(
        'MacosSecondScreenPlatform registers and inherits from DesktopSecondScreenPlatform',
        () {
      MacosSecondScreenPlatform.registerWith();
      expect(SecondScreenPlatform.instance, isA<MacosSecondScreenPlatform>());
      expect(SecondScreenPlatform.instance, isA<DesktopSecondScreenPlatform>());
    });
  });
}
