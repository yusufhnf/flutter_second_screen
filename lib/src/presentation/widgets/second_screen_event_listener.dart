import 'dart:async';
import 'package:flutter/widgets.dart';

import '../../domain/repositories/second_screen_messenger.dart';
import '../../flutter_second_screen.dart';

/// A widget that listens for specific cross-screen events and invokes [onEvent].
class SecondScreenEventListener extends StatefulWidget {
  /// The event name to listen for.
  final String eventName;

  /// Callback executed when the matching event arrives.
  final void Function(dynamic data) onEvent;

  /// The child widget.
  final Widget child;

  /// Optional custom messenger. Defaults to [FlutterSecondScreen.instance].
  final SecondScreenMessenger? messenger;

  const SecondScreenEventListener({
    super.key,
    required this.eventName,
    required this.onEvent,
    required this.child,
    this.messenger,
  });

  @override
  State<SecondScreenEventListener> createState() =>
      _SecondScreenEventListenerState();
}

class _SecondScreenEventListenerState extends State<SecondScreenEventListener> {
  SecondScreenMessenger get _messenger =>
      widget.messenger ?? FlutterSecondScreen.instance;

  @override
  void initState() {
    super.initState();
    _messenger.addEventListener(widget.eventName, widget.onEvent);
  }

  @override
  void didUpdateWidget(covariant SecondScreenEventListener oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.eventName != widget.eventName ||
        oldWidget.messenger != widget.messenger) {
      (oldWidget.messenger ?? FlutterSecondScreen.instance)
          .removeEventListener(oldWidget.eventName, oldWidget.onEvent);
      _messenger.addEventListener(widget.eventName, widget.onEvent);
    }
  }

  @override
  void dispose() {
    _messenger.removeEventListener(widget.eventName, widget.onEvent);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// A widget that rebuilds its child whenever a specific typed event is received.
class SecondScreenEventBuilder<T> extends StatefulWidget {
  /// The event name to listen for.
  final String eventName;

  /// Initial data to supply to [builder] before any event arrives.
  final T? initialData;

  /// Builder function called on initial build and every time a new event arrives.
  final Widget Function(BuildContext context, T? data) builder;

  /// Optional custom messenger. Defaults to [FlutterSecondScreen.instance].
  final SecondScreenMessenger? messenger;

  const SecondScreenEventBuilder({
    super.key,
    required this.eventName,
    required this.builder,
    this.initialData,
    this.messenger,
  });

  @override
  State<SecondScreenEventBuilder<T>> createState() =>
      _SecondScreenEventBuilderState<T>();
}

class _SecondScreenEventBuilderState<T>
    extends State<SecondScreenEventBuilder<T>> {
  T? _data;
  StreamSubscription<T?>? _subscription;

  SecondScreenMessenger get _messenger =>
      widget.messenger ?? FlutterSecondScreen.instance;

  @override
  void initState() {
    super.initState();
    _data = widget.initialData;
    _subscribe();
  }

  void _subscribe() {
    _subscription = _messenger.on<T>(widget.eventName).listen((T? data) {
      if (mounted) {
        setState(() {
          _data = data;
        });
      }
    });
  }

  @override
  void didUpdateWidget(covariant SecondScreenEventBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.eventName != widget.eventName ||
        oldWidget.messenger != widget.messenger) {
      _subscription?.cancel();
      _subscribe();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _data);
  }
}

