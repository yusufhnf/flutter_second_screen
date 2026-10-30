import 'dart:async';
import 'dart:ui';
import 'package:flutter_second_screen/flutter_second_screen.dart';
import 'package:flutter_test/flutter_test.dart';

class TestPlatform extends SecondScreenPlatform {
  final StreamController<SecondScreenEvent<dynamic>> _eventController =
      StreamController<SecondScreenEvent<dynamic>>.broadcast();

  String? sentEventName;
  dynamic sentData;
  int? sentTargetWindowId;

  List<ScreenDisplay> mockDisplays = [];
  bool secondaryOpen = false;
  bool displayAvailable = true;

  @override
  Stream<SecondScreenEvent<dynamic>> get eventStream => _eventController.stream;

  void emitEvent(SecondScreenEvent<dynamic> event) {
    _eventController.add(event);
  }

  @override
  Future<void> ensureInitialized([List<String> args = const []]) async {}

  @override
  Future<bool> initSecondaryDisplay([SecondScreenConfig? config]) async => true;

  @override
  Future<void> openSecondaryScreen(
      {List<String> arguments = const ['second-screen']}) async {}

  @override
  Future<void> closeSecondaryScreen() async {}

  @override
  Future<void> focusSecondaryScreen() async {}

  @override
  Future<void> closeAllScreens() async {}

  @override
  Future<bool> isSecondaryScreenOpen() async => secondaryOpen;

  @override
  Future<bool> isSecondaryDisplayAvailable() async => displayAvailable;

  @override
  Future<List<ScreenDisplay>> getDisplays() async => mockDisplays;

  @override
  Future<void> sendEvent(String eventName, dynamic data,
      {int? targetWindowId}) async {
    sentEventName = eventName;
    sentData = data;
    sentTargetWindowId = targetWindowId;
  }

  @override
  Future<void> dispose() async {
    await _eventController.close();
  }
}

void main() {
  late TestPlatform platform;
  late SecondScreenRepositoryImpl repo;

  setUp(() {
    platform = TestPlatform();
    repo = SecondScreenRepositoryImpl(platform: platform);
  });

  tearDown(() {
    repo.dispose();
  });

  group('SecondScreenRepositoryImpl - Display queries', () {
    test('returns displays and handles primary/secondary lookups', () async {
      platform.mockDisplays = [
        const ScreenDisplay(
            id: 0, name: 'Main', size: Size(1920, 1080), isPrimary: true),
        const ScreenDisplay(id: 1, name: 'Secondary', size: Size(1920, 1080)),
      ];

      final displays = await repo.getDisplays();
      expect(displays.length, 2);

      final primary = await repo.getPrimaryDisplay();
      expect(primary?.name, 'Main');

      final secondary = await repo.getSecondaryDisplay();
      expect(secondary?.name, 'Secondary');

      final hasSecondary = await repo.hasSecondaryDisplay();
      expect(hasSecondary, isTrue);
    });

    test('returns null when secondary display is not available', () async {
      platform.mockDisplays = [
        const ScreenDisplay(
            id: 0, name: 'Main', size: Size(1920, 1080), isPrimary: true),
      ];

      final secondary = await repo.getSecondaryDisplay();
      expect(secondary, isNull);

      final hasSecondary = await repo.hasSecondaryDisplay();
      expect(hasSecondary, isFalse);
    });
  });

  group('SecondScreenRepositoryImpl - Messaging & Event listeners', () {
    test('sends events to secondary and main targets', () async {
      await repo.sendEventToSecondary('updatePrice', 99.9);
      expect(platform.sentEventName, 'updatePrice');
      expect(platform.sentData, 99.9);
      expect(platform.sentTargetWindowId, 1);

      await repo.sendEventToMain('confirm', true);
      expect(platform.sentEventName, 'confirm');
      expect(platform.sentData, true);
      expect(platform.sentTargetWindowId, 0);

      await repo.sendEventToWindow(2, 'custom', 'payload');
      expect(platform.sentTargetWindowId, 2);
    });

    test('invokes registered callback on incoming event', () async {
      dynamic receivedData;
      void onUpdate(dynamic data) {
        receivedData = data;
      }

      repo.addEventListener('item_update', onUpdate);

      platform.emitEvent(
        SecondScreenEvent(name: 'item_update', data: {'item': 'Apple'}),
      );

      await pumpEventQueue();

      expect(receivedData, {'item': 'Apple'});

      // Unsubscribe and verify no further callbacks
      repo.removeEventListener('item_update', onUpdate);
      platform.emitEvent(
        SecondScreenEvent(name: 'item_update', data: {'item': 'Orange'}),
      );

      await pumpEventQueue();
      expect(receivedData, {'item': 'Apple'});
    });

    test('typed stream filtering with on<T>()', () async {
      final receivedItems = <String>[];
      final subscription = repo.on<String>('chat').listen((msg) {
        if (msg != null) receivedItems.add(msg);
      });

      platform.emitEvent(SecondScreenEvent(name: 'chat', data: 'hello'));
      platform.emitEvent(SecondScreenEvent(name: 'chat', data: 'world'));
      platform.emitEvent(SecondScreenEvent(name: 'other', data: 'ignored'));

      await pumpEventQueue();

      expect(receivedItems, ['hello', 'world']);
      await subscription.cancel();
    });
  });
}
