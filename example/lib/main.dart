import 'package:flutter/material.dart';
import 'package:flutter_second_screen/flutter_second_screen.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterSecondScreen.ensureInitialized(args);

  if (FlutterSecondScreen.isSecondaryScreen(args)) {
    // Secondary Screen Process
    final initialized = await FlutterSecondScreen.instance.initSecondaryDisplay(
      const SecondScreenConfig(title: 'Customer Display Window'),
    );
    if (initialized) {
      runApp(const SecondaryScreenApp());
    }
  } else {
    // Primary / Main Window Process
    runApp(const MainScreenApp());
  }
}

/// Main Screen Application
class MainScreenApp extends StatefulWidget {
  const MainScreenApp({super.key});

  @override
  State<MainScreenApp> createState() => _MainScreenAppState();
}

class _MainScreenAppState extends State<MainScreenApp>
    with SecondScreenListenerMixin {
  final secondScreen = FlutterSecondScreen.instance;
  String _customerSignatureStatus = 'Pending';
  bool _isSecondaryOpen = false;

  @override
  Map<String, void Function(dynamic)> getSecondScreenEventListeners() {
    return {
      'customerSigned': (data) {
        setState(() {
          _customerSignatureStatus = 'Signed ($data)';
        });
      },
    };
  }

  Future<void> _checkSecondaryStatus() async {
    final isOpen = await secondScreen.isSecondaryScreenOpen();
    setState(() {
      _isSecondaryOpen = isOpen;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('POS Main Screen')),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Secondary Screen Open: $_isSecondaryOpen'),
              Text('Customer Signature: $_customerSignatureStatus'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  await secondScreen.openSecondaryScreen();
                  await _checkSecondaryStatus();
                },
                child: const Text('Open Secondary Screen'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () async {
                  await sendEventToSecondaryScreen('cartUpdate', {
                    'item': 'Running Shoes',
                    'price': 129.99,
                  });
                },
                child: const Text('Send Cart Update to Secondary Screen'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () async {
                  await secondScreen.closeSecondaryScreen();
                  await _checkSecondaryStatus();
                },
                child: const Text('Close Secondary Screen'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Secondary Screen Application
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
        setState(() {
          if (data is Map) {
            _cartDisplay = 'Item: ${data['item']} - \$${data['price']}';
          }
        });
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
                onPressed: () async {
                  await sendEventToMainScreen('customerSigned', 'SignatureOK');
                },
                child: const Text('Confirm & Sign on Customer Display'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
