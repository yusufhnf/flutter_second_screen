/// Operational status of the secondary screen.
enum SecondScreenStatus {
  /// Secondary display is not physically detected or unsupported.
  unavailable,

  /// Secondary screen display is available but the window is currently closed.
  closed,

  /// Secondary screen window is currently being initialized or prepared.
  initializing,

  /// Secondary screen window is open and active.
  open,

  /// An error occurred during secondary screen initialization or operation.
  error,
}
