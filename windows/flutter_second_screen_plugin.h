#ifndef FLUTTER_PLUGIN_FLUTTER_SECOND_SCREEN_PLUGIN_H_
#define FLUTTER_PLUGIN_FLUTTER_SECOND_SCREEN_PLUGIN_H_

#include <flutter/encodable_value.h>
#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <windows.h>

#include <memory>
#include <optional>

#include "second_screen_window.h"

namespace flutter_second_screen {

// Windows implementation of the `flutter_second_screen` desktop plugin.
//
// One instance exists per Flutter engine (main window and each secondary
// window). Instances share a static window registry so they can create,
// configure, close, and message each other's windows.
class FlutterSecondScreenPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar);

  // Sets the callback used to register plugins on secondary window engines.
  static void SetRegisterPluginsCallback(
      SecondScreenWindow::RegisterPluginsCallback callback);

  explicit FlutterSecondScreenPlugin(
      flutter::PluginRegistrarWindows* registrar);

  virtual ~FlutterSecondScreenPlugin();

  // Disallow copy and assign.
  FlutterSecondScreenPlugin(const FlutterSecondScreenPlugin&) = delete;
  FlutterSecondScreenPlugin& operator=(const FlutterSecondScreenPlugin&) =
      delete;

 private:
  using MethodResult = flutter::MethodResult<flutter::EncodableValue>;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue>& method_call,
      std::unique_ptr<MethodResult> result);

  void EnsureInitialized(const flutter::EncodableMap& args,
                         std::unique_ptr<MethodResult> result);
  void CreateSecondaryWindow(const flutter::EncodableMap& args,
                             std::unique_ptr<MethodResult> result);
  void ConfigureWindow(const flutter::EncodableMap& args,
                       std::unique_ptr<MethodResult> result);
  void CloseWindow(const flutter::EncodableMap& args,
                   std::unique_ptr<MethodResult> result);
  void FocusWindow(const flutter::EncodableMap& args,
                   std::unique_ptr<MethodResult> result);
  void SendEvent(const flutter::EncodableMap& args,
                 std::unique_ptr<MethodResult> result);

  // Binds this engine to its window when Dart did not call
  // `ensureInitialized` (e.g. the app initializes windows elsewhere).
  void BindToWindowIfNeeded();

  // Registers this plugin as the owner of window [id].
  void BindToWindow(int id);

  // The top-level window hosting this plugin's engine.
  HWND GetOwnWindow() const;

  // Resolves the native window for [window_id], falling back to this
  // plugin's own window.
  HWND GetWindowForId(std::optional<int> window_id) const;

  flutter::PluginRegistrarWindows* registrar_;
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel_;
  std::optional<int> window_id_;
};

}  // namespace flutter_second_screen

#endif  // FLUTTER_PLUGIN_FLUTTER_SECOND_SCREEN_PLUGIN_H_
