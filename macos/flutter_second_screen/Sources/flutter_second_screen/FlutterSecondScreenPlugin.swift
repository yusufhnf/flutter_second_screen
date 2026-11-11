import Cocoa
import FlutterMacOS

/// Native bookkeeping for a single Flutter window managed by this plugin.
final class SecondScreenWindowEntry {
  /// The native window hosting the Flutter view, retained until it closes.
  var window: NSWindow?

  /// The plugin instance bound to the engine rendering this window.
  weak var plugin: FlutterSecondScreenPlugin?

  /// The view controller created by this plugin, `nil` for the app's main window.
  var flutterViewController: FlutterViewController?

  /// Observer token for the window close notification.
  var closeObserver: NSObjectProtocol?

  init(window: NSWindow?, flutterViewController: FlutterViewController? = nil) {
    self.window = window
    self.flutterViewController = flutterViewController
  }
}

/// macOS implementation of the `flutter_second_screen` desktop plugin.
///
/// Creates secondary Flutter windows (each with its own engine), enumerates
/// connected displays, configures window geometry, and relays events between
/// window engines.
///
/// Register the app's generated plugins for secondary engines in
/// `macos/Runner/MainFlutterWindow.swift`:
/// ```swift
/// FlutterSecondScreenPlugin.registerGeneratedPlugins = { registry in
///   RegisterGeneratedPlugins(registry: registry)
/// }
/// ```
public class FlutterSecondScreenPlugin: NSObject, FlutterPlugin {
  /// Channel name shared with `DesktopSecondScreenPlatform` on the Dart side.
  static let channelName = "com.meetucup.flutter_second_screen/desktop_methods"

  /// Callback used to register the app's generated plugins on secondary engines.
  public static var registerGeneratedPlugins: ((FlutterPluginRegistry) -> Void)?

  /// All windows known to the plugin, keyed by window ID (`0` is the main window).
  private static var windows: [Int: SecondScreenWindowEntry] = [:]

  private let registrar: FlutterPluginRegistrar
  private let channel: FlutterMethodChannel
  private var windowId: Int?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: channelName,
      binaryMessenger: registrar.messenger
    )
    let instance = FlutterSecondScreenPlugin(registrar: registrar, channel: channel)
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  init(registrar: FlutterPluginRegistrar, channel: FlutterMethodChannel) {
    self.registrar = registrar
    self.channel = channel
    super.init()
  }

  public func detachFromEngine(for registrar: FlutterPluginRegistrar) {
    channel.setMethodCallHandler(nil)
    if let windowId = windowId, let entry = Self.windows[windowId], entry.plugin === self {
      entry.plugin = nil
    }
  }

  /// The window hosting this plugin's engine.
  private var ownWindow: NSWindow? {
    if let windowId = windowId, let window = Self.windows[windowId]?.window {
      return window
    }
    return registrar.view?.window
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let args = call.arguments as? [String: Any] ?? [:]

    if call.method != "ensureInitialized" {
      bindToWindowIfNeeded()
    }

    switch call.method {
    case "ensureInitialized":
      ensureInitialized(args, result: result)
    case "createWindow":
      createWindow(args, result: result)
    case "getWindowId":
      result(windowId ?? 0)
    case "getWindowIds":
      result(Self.windows.keys.sorted())
    case "getDisplays":
      result(getDisplays())
    case "configureWindow":
      configureWindow(args, result: result)
    case "closeWindow":
      closeWindow(args, result: result)
    case "focusWindow":
      focusWindow(args, result: result)
    case "sendEvent":
      sendEvent(args, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  // MARK: - Window lifecycle

  private func ensureInitialized(_ args: [String: Any], result: @escaping FlutterResult) {
    var resolvedId = (args["windowId"] as? NSNumber)?.intValue ?? 0
    if let hostWindow = registrar.view?.window,
       let createdId = Self.windows.first(where: { _, entry in
         entry.flutterViewController != nil && entry.window === hostWindow
       })?.key {
      resolvedId = createdId
    }
    bind(toWindowId: resolvedId)
    result(true)
  }

  /// Binds this engine to its window when Dart did not call `ensureInitialized`
  /// (e.g. the app initializes windows through another package): a window
  /// created by this plugin keeps its ID, any other window is the main window.
  private func bindToWindowIfNeeded() {
    guard windowId == nil else { return }
    let hostWindow = registrar.view?.window
    let createdId = Self.windows.first { _, entry in
      entry.window != nil && entry.window === hostWindow
    }?.key
    bind(toWindowId: createdId ?? 0)
  }

  private func bind(toWindowId id: Int) {
    windowId = id

    let entry = Self.windows[id] ?? SecondScreenWindowEntry(window: registrar.view?.window)
    if entry.window == nil {
      entry.window = registrar.view?.window
    }
    entry.plugin = self
    Self.storeWindow(entry, for: id)
  }

  private func createWindow(_ args: [String: Any], result: @escaping FlutterResult) {
    guard let registerGeneratedPlugins = Self.registerGeneratedPlugins else {
      result(
        FlutterError(
          code: "UNAVAILABLE",
          message:
            "FlutterSecondScreenPlugin.registerGeneratedPlugins is not set. "
            + "Assign it in macos/Runner/MainFlutterWindow.swift.",
          details: nil))
      return
    }

    let id = Self.nextWindowId()
    let arguments = args["arguments"] as? [String] ?? []

    let project = FlutterDartProject()
    project.dartEntrypointArguments = [String(id)] + arguments

    let flutterViewController = FlutterViewController(project: project)
    let window = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
      styleMask: [.titled, .closable, .miniaturizable, .resizable],
      backing: .buffered,
      defer: false
    )
    window.isReleasedWhenClosed = false
    window.contentViewController = flutterViewController

    // The window stays hidden until `configureWindow` is called from Dart.
    Self.storeWindow(
      SecondScreenWindowEntry(window: window, flutterViewController: flutterViewController),
      for: id
    )
    registerGeneratedPlugins(flutterViewController)

    // The view controller only launches its engine when the view appears, so
    // run it now to let Dart configure and show the hidden window.
    flutterViewController.engine.run(withEntrypoint: nil)

    result(id)
  }

  private func closeWindow(_ args: [String: Any], result: @escaping FlutterResult) {
    let id = (args["windowId"] as? NSNumber)?.intValue ?? windowId ?? 0
    let window = Self.windows[id]?.window ?? (id == windowId ? ownWindow : nil)
    result(nil)
    // Defer so that an engine closing its own window finishes this call first.
    DispatchQueue.main.async {
      window?.close()
    }
  }

  private func focusWindow(_ args: [String: Any], result: @escaping FlutterResult) {
    let id = (args["windowId"] as? NSNumber)?.intValue ?? windowId ?? 0
    if let window = Self.windows[id]?.window {
      NSApp.activate(ignoringOtherApps: true)
      window.makeKeyAndOrderFront(nil)
    }
    result(nil)
  }

  private static func nextWindowId() -> Int {
    var id = 1
    while windows[id] != nil {
      id += 1
    }
    return id
  }

  private static func storeWindow(_ entry: SecondScreenWindowEntry, for id: Int) {
    windows[id] = entry
    guard entry.closeObserver == nil, let window = entry.window else { return }

    entry.closeObserver = NotificationCenter.default.addObserver(
      forName: NSWindow.willCloseNotification,
      object: window,
      queue: .main
    ) { _ in
      Self.removeWindow(id)
    }
  }

  private static func removeWindow(_ id: Int) {
    guard let entry = windows.removeValue(forKey: id) else { return }
    if let observer = entry.closeObserver {
      NotificationCenter.default.removeObserver(observer)
    }
    guard let flutterViewController = entry.flutterViewController else { return }
    entry.flutterViewController = nil
    // Shut the engine down once the window is gone.
    DispatchQueue.main.async {
      flutterViewController.engine.shutDownEngine()
      entry.window?.contentViewController = nil
    }
  }

  // MARK: - Window configuration

  private func configureWindow(_ args: [String: Any], result: @escaping FlutterResult) {
    guard let window = ownWindow else {
      result(false)
      return
    }

    let fullScreen = args["fullScreen"] as? Bool ?? false
    let resizable = args["resizable"] as? Bool ?? false
    let isInFullScreen = window.styleMask.contains(.fullScreen)

    if let title = args["title"] as? String {
      window.title = title
    }

    if let argb = (args["backgroundColor"] as? NSNumber)?.uint32Value {
      let color = Self.color(fromARGB: argb)
      window.backgroundColor = color
      window.isOpaque = color.alphaComponent >= 1.0
    }

    if args["skipTaskbar"] as? Bool ?? false {
      NSApp.setActivationPolicy(.accessory)
    }

    if !isInFullScreen {
      var frame = window.frame
      if let width = Self.double(args["width"]), let height = Self.double(args["height"]) {
        frame.size = NSSize(width: width, height: height)
      }
      if let x = Self.double(args["x"]), let y = Self.double(args["y"]) {
        frame.origin = Self.bottomLeftOrigin(x: x, y: y, height: frame.height)
        window.setFrame(frame, display: true)
      } else {
        window.setFrame(frame, display: true)
        if args["center"] as? Bool ?? false {
          window.center()
        }
      }
    }

    // A full screen window must stay resizable to enter macOS full screen mode.
    if resizable || fullScreen {
      window.styleMask.insert(.resizable)
    } else {
      window.styleMask.remove(.resizable)
    }

    window.level = (args["alwaysOnTop"] as? Bool ?? false) ? .floating : .normal
    if !window.isVisible {
      window.makeKeyAndOrderFront(nil)
    }

    if fullScreen {
      window.collectionBehavior.insert(.fullScreenPrimary)
      if !isInFullScreen {
        DispatchQueue.main.async {
          window.toggleFullScreen(nil)
        }
      }
    } else if !isInFullScreen, args["maximize"] as? Bool ?? false, let screen = window.screen {
      window.setFrame(screen.visibleFrame, display: true)
    }

    result(true)
  }

  // MARK: - Displays

  private func getDisplays() -> [[String: Any]] {
    // `NSScreen.screens[0]` is always the primary display (the one with the menu bar).
    return NSScreen.screens.enumerated().map { index, screen in
      let frame = screen.frame
      let visibleFrame = screen.visibleFrame
      let origin = Self.topLeftOrigin(of: frame)
      let visibleOrigin = Self.topLeftOrigin(of: visibleFrame)
      var name = "Display \(index)"
      if #available(macOS 10.15, *) {
        name = screen.localizedName
      }
      return [
        "id": index,
        "name": name,
        "width": frame.width,
        "height": frame.height,
        "visibleWidth": visibleFrame.width,
        "visibleHeight": visibleFrame.height,
        "x": origin.x,
        "y": origin.y,
        "visibleX": visibleOrigin.x,
        "visibleY": visibleOrigin.y,
        "isPrimary": index == 0,
      ]
    }
  }

  // MARK: - Messaging

  private func sendEvent(_ args: [String: Any], result: @escaping FlutterResult) {
    let targetId = (args["targetWindowId"] as? NSNumber)?.intValue ?? 1
    guard let target = Self.windows[targetId]?.plugin else {
      result(
        FlutterError(
          code: "WINDOW_NOT_FOUND",
          message: "No initialized window found with id \(targetId).",
          details: nil))
      return
    }

    let payload: [String: Any?] = [
      "eventName": args["eventName"] as? String ?? "",
      "fromWindowId": windowId ?? 0,
      "data": args["data"],
    ]
    target.channel.invokeMethod("onEvent", arguments: payload) { value in
      if let obj = value as? NSObject, obj === FlutterMethodNotImplemented {
        result(
          FlutterError(
            code: "TARGET_NOT_READY",
            message: "Target window \(targetId) is not ready to receive events yet.",
            details: nil))
      } else {
        result(value)
      }
    }
  }

  // MARK: - Helpers

  private static var primaryScreenHeight: CGFloat {
    return NSScreen.screens.first?.frame.height ?? 0
  }

  /// Converts a Cocoa (bottom-left origin) rect into a top-left origin point.
  private static func topLeftOrigin(of rect: NSRect) -> CGPoint {
    return CGPoint(x: rect.minX, y: primaryScreenHeight - rect.maxY)
  }

  /// Converts a top-left origin point into a Cocoa (bottom-left origin) point.
  private static func bottomLeftOrigin(x: Double, y: Double, height: CGFloat) -> CGPoint {
    return CGPoint(x: x, y: primaryScreenHeight - y - height)
  }

  private static func double(_ value: Any?) -> Double? {
    return (value as? NSNumber)?.doubleValue
  }

  private static func color(fromARGB argb: UInt32) -> NSColor {
    return NSColor(
      red: CGFloat((argb >> 16) & 0xFF) / 255.0,
      green: CGFloat((argb >> 8) & 0xFF) / 255.0,
      blue: CGFloat(argb & 0xFF) / 255.0,
      alpha: CGFloat((argb >> 24) & 0xFF) / 255.0
    )
  }
}
