import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_second_screen/flutter_second_screen.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterSecondScreen.ensureInitialized(args);
  debugPrint('>>> main started with args=$args');
  if (FlutterSecondScreen.isSecondaryScreen(args)) {
    await const MethodChannel(
      'com.meetucup.flutter_second_screen/desktop_methods',
    ).invokeMethod('configureWindow', {
      'title': 'Secondary Test',
      'fullScreen': true,
      'maximize': false,
      'center': true,
      'width': 400.0,
      'height': 300.0,
    });
    // Send immediately without delay to stress-test Hot Restart ordering.
    await FlutterSecondScreen.instance.sendEventToMain('ready', 'v1');
    runApp(const SecondaryScreenApp());
  } else {
    runApp(const MainScreenApp());
    await Future<void>.delayed(const Duration(milliseconds: 500));
    await FlutterSecondScreen.instance.openSecondaryScreen();
    await FlutterSecondScreen.instance.sendEventToSecondary('sync', 'hello');
  }
}

/// Main Screen Application (cashier / POS).
class MainScreenApp extends StatelessWidget {
  const MainScreenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: MainScreenPage());
  }
}

class MainScreenPage extends StatefulWidget {
  const MainScreenPage({super.key});

  @override
  State<MainScreenPage> createState() => _MainScreenPageState();
}

class _MainScreenPageState extends State<MainScreenPage>
    with SecondScreenListenerMixin {
  final secondScreen = FlutterSecondScreen.instance;

  List<ScreenDisplay> _displays = const [];
  bool _isSecondaryOpen = false;
  String _customerSignatureStatus = 'Pending';

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  Map<String, void Function(dynamic)> getSecondScreenEventListeners() {
    return {
      'customerSigned': (data) {
        setState(() => _customerSignatureStatus = 'Signed ($data)');
      },
    };
  }

  Future<void> _refresh() async {
    final displays = await secondScreen.getDisplays();
    final isOpen = await secondScreen.isSecondaryScreenOpen();
    if (!mounted) return;
    setState(() {
      _displays = displays;
      _isSecondaryOpen = isOpen;
    });
  }

  Future<void> _open() async {
    try {
      await secondScreen.openSecondaryScreen();
    } on SecondScreenException catch (e) {
      _showMessage(e.message);
    }
    await _refresh();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasSecondDisplay = _displays.length > 1;

    return Scaffold(
      appBar: AppBar(
        title: const Text('POS Main Screen'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          Text('Detected displays (${_displays.length})',
              style: Theme.of(context).textTheme.titleMedium),
          for (final display in _displays)
            ListTile(
              dense: true,
              leading: Icon(
                display.isPrimary ? Icons.desktop_mac : Icons.tv,
              ),
              title: Text(display.name),
              subtitle: Text(
                '${display.size.width.toInt()} x ${display.size.height.toInt()}'
                ' at ${display.effectivePosition}',
              ),
              trailing: Text(display.isPrimary ? 'Primary' : 'Secondary'),
            ),
          if (!hasSecondDisplay)
            const Text('Connect a second display to open the customer screen.'),
          const Divider(height: 32),
          Text('Secondary Screen Open: $_isSecondaryOpen'),
          Text('Customer Signature: $_customerSignatureStatus'),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              ElevatedButton(
                onPressed: hasSecondDisplay && !_isSecondaryOpen ? _open : null,
                child: const Text('Open Secondary Screen'),
              ),
              ElevatedButton(
                onPressed: () => sendEventToSecondaryScreen('cartUpdate', {
                  'item': 'Running Shoes',
                  'price': 129.99,
                }),
                child: const Text('Send Cart Update'),
              ),
              ElevatedButton(
                onPressed:
                    _isSecondaryOpen ? secondScreen.focusSecondaryScreen : null,
                child: const Text('Focus Secondary Screen'),
              ),
              ElevatedButton(
                onPressed: _isSecondaryOpen
                    ? () async {
                        await secondScreen.closeSecondaryScreen();
                        await Future<void>.delayed(
                          const Duration(milliseconds: 300),
                        );
                        await _refresh();
                      }
                    : null,
                child: const Text('Close Secondary Screen'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Secondary Screen Application (customer-facing display).
class SecondaryScreenApp extends StatefulWidget {
  const SecondaryScreenApp({super.key});

  @override
  State<SecondaryScreenApp> createState() => _SecondaryScreenAppState();
}

class _SecondaryScreenAppState extends State<SecondaryScreenApp>
    with SecondScreenListenerMixin {
  String _cartDisplay = 'Welcome to our store!';

  @override
  Map<String, void Function(dynamic)> getSecondScreenEventListeners() {
    return {
      'cartUpdate': (data) {
        if (data is Map) {
          setState(() {
            _cartDisplay = 'Item: ${data['item']} - \$${data['price']}';
          });
        }
      },
    };
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.black87,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _cartDisplay,
                style: const TextStyle(color: Colors.white, fontSize: 28),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () =>
                    sendEventToMainScreen('customerSigned', 'SignatureOK'),
                child: const Text('Confirm & Sign on Customer Display'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
