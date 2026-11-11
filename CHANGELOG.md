## 2.0.0-dev.3

- Fixed Windows force-close crash when plugins subclass `GetAncestor(view, GA_ROOT)` by registering secondary engine plugins before parenting the Flutter view and guarding `SecondScreenWindow::WndProc` with `IsOwnWindow` against foreign window handles.
- Added clean shutdown of remaining secondary windows on Windows when the main window closes.
- Improved Hot Restart and Hot Reload reliability across Windows and macOS:
  - Register the desktop method channel handler eagerly on construction.
  - Prevent secondary windows from binding as window `0` during `ensureInitialized`.
  - Handle `TARGET_NOT_READY` gracefully when a target window is still booting or restarting, avoiding `MissingPluginException`.
  - Preserve fullscreen state and avoid stealing foreground focus when reconfiguring an already-visible secondary window on Hot Restart.
  - Update `SecondScreenEventListener` callbacks cleanly when `onEvent` changes on widget rebuild or Hot Reload.

## 2.0.0-dev.2

- Fixed Windows build error with current Flutter versions: `FlutterDesktopGetDpiForMonitor` now accepts both the `HMONITOR` and legacy `intptr_t` signatures.
- Fixed potential Windows `/W4 /WX` build failures in window style handling.

## 2.0.0-dev.1

- Removed the `window_manager_plus` and `screen_retriever` dependencies in favor of a built-in native desktop plugin (`FlutterSecondScreenPlugin`) for macOS (Swift) and Windows (C++).
- Added native secondary window creation (one Flutter engine per window), display enumeration, window configuration, and cross-window messaging over the `com.meetucup.flutter_second_screen/desktop_methods` channel.
- Added `SecondScreenConfigModel` for serializing window configuration to the native plugin.
- `ScreenDisplayModel` now reads and writes `visibleX` / `visibleY`; removed `ScreenDisplayModel.fromScreenRetriever`.
- Secondary window IDs are reused after closing, so a reopened secondary screen is always window `1`.
- Added `FlutterSecondScreen.run` to boot the main and secondary entry points in one call, with an optional `beforeRunApp` hook.
- Added `SecondScreenException`; `openSecondaryScreen` throws it with code `setup-required` when the runner setup is missing.
- `initSecondaryDisplay` now closes the hidden secondary window when no second display is connected, so it can be reopened later.
- Sending an event to a window that is not open is now a no-op instead of throwing.
- `FlutterSecondScreen.ensureInitialized` is now optional; the native plugin resolves the window on first use.
- The example app now ships runnable macOS and Windows runners with the setup applied.
- README reorganized around a quick start, API reference, configuration table, troubleshooting, and a 1.0.x migration guide.
- **Breaking:** app runners must register plugins for secondary engines (`FlutterSecondScreenPlugin.registerGeneratedPlugins` on macOS, `FlutterSecondScreenPluginSetRegisterPluginsCallback` on Windows). See README.

## 1.0.1

- Clarified and enhanced Architecture Overview in `README.md` with hierarchical component and file structure trees.
- Improved flowchart diagram syntax and structure for reliable rendering across all markdown viewers.
- Refined documentation links and repository metadata.

## 1.0.0

- Initial release of `flutter_second_screen`.
- Clean Architecture and SOLID design for secondary screen management.
- Windows desktop multi-display detection, secondary window lifecycle, and inter-window messaging via `window_manager_plus` & `screen_retriever`.
- Architecture blueprints and TODO contracts for upcoming Android (`Presentation` / `DisplayManager`) and iOS (`UIScreen` / `UIWindow`) support.
- Stream-based and mixin-based event communication between main and secondary screens.

