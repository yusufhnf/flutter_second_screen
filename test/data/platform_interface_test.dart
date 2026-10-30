import 'package:flutter_second_screen/flutter_second_screen.dart';
import 'package:flutter_test/flutter_test.dart';

class MockPlatform extends SecondScreenPlatform {
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
  Future<bool> isSecondaryScreenOpen() async => false;

  @override
  Future<bool> isSecondaryDisplayAvailable() async => true;

  @override
  Future<List<ScreenDisplay>> getDisplays() async => [];

  @override
  Future<void> sendEvent(String eventName, dynamic data,
      {int? targetWindowId}) async {}

  @override
  Stream<SecondScreenEvent<dynamic>> get eventStream => const Stream.empty();

  @override
  Future<void> dispose() async {}
}

void main() {
  test('SecondScreenPlatform instance can be mocked and set', () {
    final mock = MockPlatform();
    SecondScreenPlatform.instance = mock;
    expect(SecondScreenPlatform.instance, mock);
  });
}
