#ifndef FLUTTER_PLUGIN_SECOND_SCREEN_WINDOW_H_
#define FLUTTER_PLUGIN_SECOND_SCREEN_WINDOW_H_

#include <flutter_windows.h>
#include <windows.h>

#include <functional>
#include <string>
#include <vector>

namespace flutter_second_screen {

// A top-level Win32 window hosting a secondary Flutter engine and view.
//
// The window is created hidden; it is shown once Dart configures it through
// the `configureWindow` method. When the window is destroyed, the engine is
// shut down and [on_destroyed] is invoked so the owner can release it.
class SecondScreenWindow {
 public:
  using RegisterPluginsCallback = void (*)(FlutterDesktopEngineRef engine);

  SecondScreenWindow(int id, std::function<void(int)> on_destroyed);
  ~SecondScreenWindow();

  // Prevent copying.
  SecondScreenWindow(SecondScreenWindow const&) = delete;
  SecondScreenWindow& operator=(SecondScreenWindow const&) = delete;

  // Creates the native window and runs a new Flutter engine inside it with
  // [entrypoint_args] as the Dart entrypoint arguments.
  bool Create(const std::vector<std::string>& entrypoint_args,
              RegisterPluginsCallback register_plugins);

  // The top-level window handle.
  HWND GetHandle() const { return window_handle_; }

 private:
  static LRESULT CALLBACK WndProc(HWND window,
                                  UINT message,
                                  WPARAM wparam,
                                  LPARAM lparam) noexcept;

  LRESULT MessageHandler(HWND window,
                         UINT message,
                         WPARAM wparam,
                         LPARAM lparam) noexcept;

  // Resizes the Flutter child view to fill the client area.
  void ResizeChildContent();

  static const wchar_t* GetWindowClass();

  int id_;
  std::function<void(int)> on_destroyed_;
  HWND window_handle_ = nullptr;
  HWND child_content_ = nullptr;
  FlutterDesktopEngineRef engine_ = nullptr;
  FlutterDesktopViewControllerRef controller_ = nullptr;
};

}  // namespace flutter_second_screen

#endif  // FLUTTER_PLUGIN_SECOND_SCREEN_WINDOW_H_
