import 'package:flutter_second_screen/flutter_second_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('IosSecondScreenPlatform', () {
    late IosSecondScreenPlatform platform;

    setUp(() {
      platform = IosSecondScreenPlatform();
    });

    tearDown(() async {
      await platform.dispose();
    });

    test('exposes channels and stub methods returning safe defaults', () async {
      expect(platform.methodChannel.name, 'com.meetucup.flutter_second_screen/ios_methods');
      expect(platform.eventChannel.name, 'com.meetucup.flutter_second_screen/ios_events');

      expect(await platform.initSecondaryDisplay(), isFalse);
      expect(await platform.isSecondaryScreenOpen(), isFalse);
      expect(await platform.isSecondaryDisplayAvailable(), isFalse);
      expect(await platform.getDisplays(), isEmpty);

      // Verify void methods execute without throwing
      await platform.openSecondaryScreen();
      await platform.closeSecondaryScreen();
      await platform.focusSecondaryScreen();
      await platform.closeAllScreens();
      await platform.sendEvent('test', null);
    });
  });
}

