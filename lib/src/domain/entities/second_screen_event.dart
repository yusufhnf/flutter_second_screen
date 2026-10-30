/// Represents a cross-screen message or event sent between the main
/// window and the secondary screen window.
class SecondScreenEvent<T> {
  /// Name or topic of the event.
  final String name;

  /// Optional payload data associated with this event.
  final T? data;

  /// ID of the window that originated the event (e.g. 0 for main, 1 for secondary).
  final int fromWindowId;

  /// Target window ID (if targeted) or null if broadcasted.
  final int? toWindowId;

  /// Timestamp when the event was dispatched.
  final DateTime timestamp;

  SecondScreenEvent({
    required this.name,
    this.data,
    this.fromWindowId = 0,
    this.toWindowId,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SecondScreenEvent &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          data == other.data &&
          fromWindowId == other.fromWindowId &&
          toWindowId == other.toWindowId;

  @override
  int get hashCode => Object.hash(name, data, fromWindowId, toWindowId);

  @override
  String toString() =>
      'SecondScreenEvent(name: $name, data: $data, from: $fromWindowId, to: $toWindowId)';
}
