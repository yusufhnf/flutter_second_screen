import 'dart:ui';

/// Represents a physical display connected to the device.
class ScreenDisplay {
  /// Unique identifier of the display.
  final int id;

  /// Display name or label.
  final String name;

  /// Full size of the display in logical pixels.
  final Size size;

  /// Visible size of the display excluding OS taskbars or system bars.
  final Size? visibleSize;

  /// Top-left position of the display relative to the virtual screen.
  final Offset? position;

  /// Top-left position of the visible display area.
  final Offset? visiblePosition;

  /// Whether this is the primary system display.
  final bool isPrimary;

  const ScreenDisplay({
    required this.id,
    required this.name,
    required this.size,
    this.visibleSize,
    this.position,
    this.visiblePosition,
    this.isPrimary = false,
  });

  /// The effective visible size, falling back to [size] if [visibleSize] is null.
  Size get effectiveSize => visibleSize ?? size;

  /// The effective position, falling back to [Offset.zero] if [position] is null.
  Offset get effectivePosition => position ?? Offset.zero;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScreenDisplay &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          size == other.size &&
          visibleSize == other.visibleSize &&
          position == other.position &&
          visiblePosition == other.visiblePosition &&
          isPrimary == other.isPrimary;

  @override
  int get hashCode => Object.hash(
        id,
        name,
        size,
        visibleSize,
        position,
        visiblePosition,
        isPrimary,
      );

  @override
  String toString() =>
      'ScreenDisplay(id: $id, name: $name, size: $size, isPrimary: $isPrimary)';
}
