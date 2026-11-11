import 'package:flutter/services.dart';
import 'package:flutter_second_screen/flutter_second_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

  group('DesktopSecondScreenPlatform', () {
    late DesktopSecondScreenPlatform platform;
    late List<MethodCall> calls;
    late List<int> windowIds;
    late List<Map<String, dynamic>> displays;
    late int currentWindowId;
    late Map<String, PlatformException> failures;

    const primaryDisplay = {
      'id': 0,
      'name': 'Built-in Display',
      'width': 1440.0,
      'height': 900.0,
      'visibleWidth': 1440.0,
      'visibleHeight': 875.0,
      'x': 0.0,
      'y': 0.0,
      'visibleX': 0.0,
      'visibleY': 25.0,
      'isPrimary': true,
    };
    const externalDisplay = {
      'id': 1,
      'name': 'External Display',
      'width': 1920.0,
      'height': 1080.0,
      'visibleWidth': 1920.0,
      'visibleHeight': 1040.0,
      'x': 1440.0,
      'y': 0.0,
      'visibleX': 1440.0,
      'visibleY': 0.0,
      'isPrimary': false,
    };

    setUp(() {
      platform = DesktopSecondScreenPlatform();
      calls = [];
      windowIds = [0];
      displays = [primaryDisplay, externalDisplay];
      currentWindowId = 0;
      failures = {};

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(platform.methodChannel, (call) async {
        calls.add(call);
        final failure = failures[call.method];
        if (failure != null) throw failure;
        switch (call.method) {
          case 'getWindowId':
            return currentWindowId;
          case 'getWindowIds':
            return windowIds;
          case 'getDisplays':
            return displays;
          case 'createWindow':
            return 1;
          case 'configureWindow':
            return true;
          default:
            return null;
        }
      });
    });

    tearDown(() async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(platform.methodChannel, null);
      await platform.dispose();
    });

    List<String> methods() => calls.map((call) => call.method).toList();

    test('exposes the desktop method channel', () {
      expect(platform.methodChannel.name,
          'com.meetucup.flutter_second_screen/desktop_methods');
    });

    test('ensureInitialized parses window ID from args', () async {
      await platform.ensureInitialized(['1', 'second-screen']);

      expect(platform.windowId, 1);
      expect(calls.single.method, 'ensureInitialized');
      expect(calls.single.arguments, {'windowId': 1});
    });

    test('getDisplays maps native displays to entities', () async {
      final result = await platform.getDisplays();

      expect(result, hasLength(2));
      expect(result[0].isPrimary, isTrue);
      expect(result[1].id, 1);
      expect(result[1].name, 'External Display');
      expect(result[1].size, const Size(1920, 1080));
      expect(result[1].visibleSize, const Size(1920, 1040));
      expect(result[1].position, const Offset(1440, 0));
      expect(result[1].visiblePosition, const Offset(1440, 0));
    });

    test('isSecondaryScreenOpen reflects native window count', () async {
      expect(await platform.isSecondaryScreenOpen(), isFalse);
      windowIds = [0, 1];
      expect(await platform.isSecondaryScreenOpen(), isTrue);
    });

    test('isSecondaryDisplayAvailable requires a free external display',
        () async {
      expect(await platform.isSecondaryDisplayAvailable(), isTrue);

      windowIds = [0, 1];
      expect(await platform.isSecondaryDisplayAvailable(), isFalse);

      windowIds = [0];
      displays = [primaryDisplay];
      expect(await platform.isSecondaryDisplayAvailable(), isFalse);
    });

    test('openSecondaryScreen creates a window only when none is open',
        () async {
      await platform.openSecondaryScreen(arguments: ['second-screen', 'x']);
      expect(calls.last.method, 'createWindow');
      expect(calls.last.arguments, {
        'arguments': ['second-screen', 'x'],
      });

      calls.clear();
      windowIds = [0, 1];
      await platform.openSecondaryScreen();
      expect(methods(), isNot(contains('createWindow')));
    });

    test('closeSecondaryScreen closes the secondary window', () async {
      windowIds = [0, 1];
      await platform.closeSecondaryScreen();

      expect(calls.last.method, 'closeWindow');
      expect(calls.last.arguments, {'windowId': 1});
    });

    test('closeSecondaryScreen closes the current window when no secondary',
        () async {
      await platform.closeSecondaryScreen();

      expect(calls.last.method, 'closeWindow');
      expect(calls.last.arguments, {'windowId': 0});
    });

    test('closeAllScreens closes every window', () async {
      windowIds = [0, 1];
      await platform.closeAllScreens();

      final closed = calls
          .where((call) => call.method == 'closeWindow')
          .map((call) => (call.arguments as Map)['windowId'])
          .toList();
      expect(closed, [0, 1]);
    });

    test('focusSecondaryScreen focuses the secondary window when open',
        () async {
      await platform.focusSecondaryScreen();
      expect(methods(), isNot(contains('focusWindow')));

      windowIds = [0, 1];
      await platform.focusSecondaryScreen();
      expect(calls.last.method, 'focusWindow');
      expect(calls.last.arguments, {'windowId': 1});
    });

    test('initSecondaryDisplay configures window on the external display',
        () async {
      final result = await platform.initSecondaryDisplay(
        const SecondScreenConfig(title: 'Customer Display Window'),
      );

      expect(result, isTrue);
      expect(calls.last.method, 'configureWindow');
      final options = Map<String, dynamic>.from(calls.last.arguments as Map);
      expect(options['title'], 'Customer Display Window');
      expect(options['width'], 1920.0);
      expect(options['height'], 1040.0);
      expect(options['x'], 1440.0);
      expect(options['y'], 0.0);
      expect(options['fullScreen'], isTrue);
      expect(options['maximize'], isTrue);
    });

    test('initSecondaryDisplay returns false with a single display', () async {
      displays = [primaryDisplay];

      expect(await platform.initSecondaryDisplay(), isFalse);
      expect(methods(), isNot(contains('configureWindow')));
    });

    test('initSecondaryDisplay closes the secondary window without a display',
        () async {
      displays = [primaryDisplay];
      currentWindowId = 1;

      expect(await platform.initSecondaryDisplay(), isFalse);
      expect(calls.last.method, 'closeWindow');
      expect(calls.last.arguments, {'windowId': 1});
    });

    test('initSecondaryDisplay never closes the main window', () async {
      displays = [primaryDisplay];

      expect(await platform.initSecondaryDisplay(), isFalse);
      expect(methods(), isNot(contains('closeWindow')));
    });

    test('openSecondaryScreen reports missing runner setup', () async {
      failures['createWindow'] = PlatformException(
        code: 'UNAVAILABLE',
        message: 'registerGeneratedPlugins is not set',
      );

      await expectLater(
        platform.openSecondaryScreen(),
        throwsA(isA<SecondScreenException>().having(
          (e) => e.code,
          'code',
          SecondScreenException.setupRequired,
        )),
      );
    });

    test('sendEvent is a no-op when the target window is not open', () async {
      failures['sendEvent'] = PlatformException(code: 'WINDOW_NOT_FOUND');

      await platform.sendEvent('cartUpdate', null);
    });

    test('sendEvent is a no-op when the target window is not ready yet',
        () async {
      failures['sendEvent'] = PlatformException(code: 'TARGET_NOT_READY');

      await platform.sendEvent('cartUpdate', null);
    });

    test('registers method call handler on construction for hot restart safety',
        () async {
      const codec = StandardMethodCodec();
      ByteData? reply;
      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage(
        platform.methodChannel.name,
        codec.encodeMethodCall(const MethodCall('onEvent', {
          'eventName': 'ping',
          'fromWindowId': 1,
          'data': 'ok',
        })),
        (data) {
          reply = data;
        },
      );

      // A registered handler responds with a non-null encoded envelope (null result),
      // whereas an unregistered handler leaves `reply` null (MissingPluginException).
      expect(reply, isNotNull);
      expect(codec.decodeEnvelope(reply!), isNull);
    });

    test('sendEvent rethrows other platform errors', () async {
      failures['sendEvent'] = PlatformException(code: 'OTHER');

      await expectLater(
        platform.sendEvent('cartUpdate', null),
        throwsA(isA<PlatformException>()),
      );
    });

    test('sendEvent targets the secondary window by default', () async {
      await platform.sendEvent('cartUpdate', {'total': 10});

      expect(calls.last.method, 'sendEvent');
      expect(calls.last.arguments, {
        'targetWindowId': 1,
        'eventName': 'cartUpdate',
        'data': {'total': 10},
      });
    });

    test('handleMethodCall emits onEvent payloads to eventStream', () async {
      final eventFuture = platform.eventStream.first;

      await platform.handleMethodCall(const MethodCall('onEvent', {
        'eventName': 'customerSigned',
        'fromWindowId': 1,
        'data': 'SignatureOK',
      }));

      final event = await eventFuture;
      expect(event.name, 'customerSigned');
      expect(event.fromWindowId, 1);
      expect(event.data, 'SignatureOK');
    });

    test('handleMethodCall rejects unknown methods', () {
      expect(
        () => platform.handleMethodCall(const MethodCall('unknown')),
        throwsA(isA<MissingPluginException>()),
      );
    });
  });
}
