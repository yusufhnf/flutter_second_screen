import 'dart:ui';
import 'package:flutter_second_screen/flutter_second_screen.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeSecondScreenRepository implements SecondScreenRepository {
  bool initSecondaryDisplayCalled = false;
  SecondScreenConfig? lastConfig;
  bool openSecondaryScreenCalled = false;
  List<String>? lastOpenArguments;
  bool closeSecondaryScreenCalled = false;
  bool focusSecondaryScreenCalled = false;
  bool closeAllScreensCalled = false;
  bool isSecondaryScreenOpenValue = false;
  bool isSecondaryDisplayAvailableValue = false;

  String? lastEventName;
  dynamic lastEventData;
  int? lastTargetWindowId;

  final List<ScreenDisplay> displays = [
    const ScreenDisplay(id: 0, name: 'Main', size: Size(1920, 1080), isPrimary: true),
    const ScreenDisplay(id: 1, name: 'Secondary', size: Size(1920, 1080)),
  ];

  @override
  Future<bool> initSecondaryDisplay([SecondScreenConfig? config]) async {
    initSecondaryDisplayCalled = true;
    lastConfig = config;
    return true;
  }

  @override
  Future<void> openSecondaryScreen({List<String> arguments = const ['second-screen']}) async {
    openSecondaryScreenCalled = true;
    lastOpenArguments = arguments;
  }

  @override
  Future<void> closeSecondaryScreen() async {
    closeSecondaryScreenCalled = true;
  }

  @override
  Future<void> focusSecondaryScreen() async {
    focusSecondaryScreenCalled = true;
  }

  @override
  Future<void> closeAllScreens() async {
    closeAllScreensCalled = true;
  }

  @override
  Future<bool> isSecondaryScreenOpen() async => isSecondaryScreenOpenValue;

  @override
  Future<bool> isSecondaryDisplayAvailable() async => isSecondaryDisplayAvailableValue;

  @override
  Future<List<ScreenDisplay>> getDisplays() async => displays;

  @override
  Future<ScreenDisplay?> getPrimaryDisplay() async => displays[0];

  @override
  Future<ScreenDisplay?> getSecondaryDisplay() async => displays[1];

  @override
  Future<bool> hasSecondaryDisplay() async => displays.length > 1;

  @override
  Future<void> sendEventToSecondary(String eventName, [dynamic data]) async {
    lastEventName = eventName;
    lastEventData = data;
    lastTargetWindowId = 1;
  }

  @override
  Future<void> sendEventToMain(String eventName, [dynamic data]) async {
    lastEventName = eventName;
    lastEventData = data;
    lastTargetWindowId = 0;
  }

  @override
  Future<void> sendEventToWindow(int windowId, String eventName, [dynamic data]) async {
    lastEventName = eventName;
    lastEventData = data;
    lastTargetWindowId = windowId;
  }

  @override
  Stream<SecondScreenEvent<dynamic>> get eventStream => const Stream.empty();

  @override
  Stream<T?> on<T>(String eventName) => const Stream.empty();

  @override
  void addEventListener(String eventName, void Function(dynamic data) listener) {}

  @override
  void removeEventListener(String eventName, void Function(dynamic data) listener) {}
}

void main() {
  late FakeSecondScreenRepository fakeRepo;

  setUp(() {
    fakeRepo = FakeSecondScreenRepository();
  });

  test('InitSecondaryDisplayUseCase delegates to repository', () async {
    final useCase = InitSecondaryDisplayUseCase(fakeRepo);
    const config = SecondScreenConfig(title: 'Custom Title');
    final result = await useCase(config);

    expect(result, isTrue);
    expect(fakeRepo.initSecondaryDisplayCalled, isTrue);
    expect(fakeRepo.lastConfig?.title, 'Custom Title');
  });

  test('OpenSecondaryScreenUseCase delegates to repository', () async {
    final useCase = OpenSecondaryScreenUseCase(fakeRepo);
    await useCase(arguments: ['custom-arg']);

    expect(fakeRepo.openSecondaryScreenCalled, isTrue);
    expect(fakeRepo.lastOpenArguments, ['custom-arg']);
  });

  test('CloseSecondaryScreenUseCase delegates to repository', () async {
    final useCase = CloseSecondaryScreenUseCase(fakeRepo);
    await useCase();

    expect(fakeRepo.closeSecondaryScreenCalled, isTrue);
  });

  test('SendEventToSecondaryUseCase delegates to repository', () async {
    final useCase = SendEventToSecondaryUseCase(fakeRepo);
    await useCase('itemAdded', {'id': 123});

    expect(fakeRepo.lastEventName, 'itemAdded');
    expect(fakeRepo.lastEventData, {'id': 123});
    expect(fakeRepo.lastTargetWindowId, 1);
  });

  test('SendEventToMainUseCase delegates to repository', () async {
    final useCase = SendEventToMainUseCase(fakeRepo);
    await useCase('signatureCaptured', 'base64...');

    expect(fakeRepo.lastEventName, 'signatureCaptured');
    expect(fakeRepo.lastEventData, 'base64...');
    expect(fakeRepo.lastTargetWindowId, 0);
  });

  test('IsSecondaryScreenOpenUseCase delegates to repository', () async {
    fakeRepo.isSecondaryScreenOpenValue = true;
    final useCase = IsSecondaryScreenOpenUseCase(fakeRepo);
    final result = await useCase();

    expect(result, isTrue);
  });

  test('IsSecondaryDisplayAvailableUseCase delegates to repository', () async {
    fakeRepo.isSecondaryDisplayAvailableValue = true;
    final useCase = IsSecondaryDisplayAvailableUseCase(fakeRepo);
    final result = await useCase();

    expect(result, isTrue);
  });

  test('GetDisplaysUseCase delegates to repository', () async {
    final useCase = GetDisplaysUseCase(fakeRepo);
    final result = await useCase();

    expect(result.length, 2);
    expect(result.first.name, 'Main');
  });
}

