import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_second_screen/flutter_second_screen.dart';
import 'package:flutter_test/flutter_test.dart';

class MockMessenger implements SecondScreenMessenger {
  final Map<String, List<void Function(dynamic)>> listeners = {};
  final StreamController<SecondScreenEvent<dynamic>> _streamController =
      StreamController<SecondScreenEvent<dynamic>>.broadcast();

  String? sentEventName;
  dynamic sentData;

  @override
  void addEventListener(
      String eventName, void Function(dynamic data) listener) {
    listeners.putIfAbsent(eventName, () => []).add(listener);
  }

  @override
  void removeEventListener(
      String eventName, void Function(dynamic data) listener) {
    listeners[eventName]?.remove(listener);
  }

  @override
  Future<void> sendEventToMain(String eventName, [dynamic data]) async {
    sentEventName = eventName;
    sentData = data;
  }

  @override
  Future<void> sendEventToSecondary(String eventName, [dynamic data]) async {
    sentEventName = eventName;
    sentData = data;
  }

  @override
  Future<void> sendEventToWindow(int windowId, String eventName,
      [dynamic data]) async {
    sentEventName = eventName;
    sentData = data;
  }

  @override
  Stream<SecondScreenEvent<dynamic>> get eventStream =>
      _streamController.stream;

  @override
  Stream<T?> on<T>(String eventName) {
    return _streamController.stream
        .where((event) => event.name == eventName)
        .map((event) => event.data is T ? event.data as T : null);
  }

  void triggerEvent(String eventName, dynamic data) {
    _streamController.add(SecondScreenEvent(name: eventName, data: data));
    final callbacks = listeners[eventName];
    if (callbacks != null) {
      for (final cb in List<void Function(dynamic)>.from(callbacks)) {
        cb(data);
      }
    }
  }

  void dispose() {
    _streamController.close();
  }
}

class TestMixinWidget extends StatefulWidget {
  final MockMessenger messenger;

  const TestMixinWidget({super.key, required this.messenger});

  @override
  State<TestMixinWidget> createState() => _TestMixinWidgetState();
}

class _TestMixinWidgetState extends State<TestMixinWidget>
    with SecondScreenListenerMixin {
  String receivedMessage = 'none';

  @override
  SecondScreenMessenger get secondScreenMessenger => widget.messenger;

  @override
  Map<String, void Function(dynamic)> getSecondScreenEventListeners() {
    return {
      'greet': (dynamic data) {
        setState(() {
          receivedMessage = data as String;
        });
      },
    };
  }

  @override
  Widget build(BuildContext context) {
    return Text(receivedMessage, textDirection: TextDirection.ltr);
  }
}

void main() {
  late MockMessenger messenger;

  setUp(() {
    messenger = MockMessenger();
  });

  tearDown(() {
    messenger.dispose();
  });

  testWidgets('SecondScreenListenerMixin registers and receives events',
      (tester) async {
    await tester.pumpWidget(TestMixinWidget(messenger: messenger));

    expect(find.text('none'), findsOneWidget);

    messenger.triggerEvent('greet', 'Hello from Secondary!');
    await tester.pump();

    expect(find.text('Hello from Secondary!'), findsOneWidget);
  });

  testWidgets('SecondScreenEventListener triggers callback on matching event',
      (tester) async {
    dynamic receivedValue;

    await tester.pumpWidget(
      SecondScreenEventListener(
        eventName: 'ping',
        messenger: messenger,
        onEvent: (data) {
          receivedValue = data;
        },
        child: const Text('Listener Child', textDirection: TextDirection.ltr),
      ),
    );

    expect(find.text('Listener Child'), findsOneWidget);

    messenger.triggerEvent('ping', 'pong');
    await tester.pump();

    expect(receivedValue, 'pong');
  });

  testWidgets('SecondScreenEventBuilder rebuilds on event arrival',
      (tester) async {
    await tester.pumpWidget(
      SecondScreenEventBuilder<int>(
        eventName: 'count',
        initialData: 0,
        messenger: messenger,
        builder: (context, data) {
          return Text('Count: $data', textDirection: TextDirection.ltr);
        },
      ),
    );

    expect(find.text('Count: 0'), findsOneWidget);

    messenger.triggerEvent('count', 5);
    await tester.pumpAndSettle();

    expect(find.text('Count: 5'), findsOneWidget);
  });
}
