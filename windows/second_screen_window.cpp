#include "second_screen_window.h"

#include <cwchar>
#include <iterator>

namespace flutter_second_screen {

namespace {

constexpr const wchar_t kWindowClassName[] = L"FLUTTER_SECOND_SCREEN_WINDOW";

// Resource ID of the app icon in the default Flutter Windows runner.
constexpr int kAppIconResourceId = 101;

constexpr int kDefaultWidth = 800;
constexpr int kDefaultHeight = 600;

}  // namespace

SecondScreenWindow::SecondScreenWindow(int id,
                                       std::function<void(int)> on_destroyed)
    : id_(id), on_destroyed_(std::move(on_destroyed)) {}

SecondScreenWindow::~SecondScreenWindow() {
  if (window_handle_) {
    // Detach first so WM_NCDESTROY does not call back into a dying object.
    SetWindowLongPtr(window_handle_, GWLP_USERDATA, 0);
    on_destroyed_ = nullptr;
    HWND handle = window_handle_;
    window_handle_ = nullptr;
    if (controller_) {
      FlutterDesktopViewControllerDestroy(controller_);
      controller_ = nullptr;
    }
    DestroyWindow(handle);
  }
}

// static
bool SecondScreenWindow::IsOwnWindow(HWND window) {
  wchar_t class_name[64] = {};
  if (!GetClassNameW(window, class_name,
                     static_cast<int>(std::size(class_name)))) {
    return false;
  }
  return wcscmp(class_name, kWindowClassName) == 0;
}

const wchar_t* SecondScreenWindow::GetWindowClass() {
  static bool registered = false;
  if (!registered) {
    WNDCLASS window_class{};
    window_class.hCursor = LoadCursor(nullptr, IDC_ARROW);
    window_class.lpszClassName = kWindowClassName;
    window_class.style = CS_HREDRAW | CS_VREDRAW;
    window_class.cbClsExtra = 0;
    window_class.cbWndExtra = 0;
    window_class.hInstance = GetModuleHandle(nullptr);
    window_class.hIcon = LoadIcon(GetModuleHandle(nullptr),
                                  MAKEINTRESOURCE(kAppIconResourceId));
    window_class.hbrBackground = 0;
    window_class.lpszMenuName = nullptr;
    window_class.lpfnWndProc = SecondScreenWindow::WndProc;
    RegisterClass(&window_class);
    registered = true;
  }
  return kWindowClassName;
}

bool SecondScreenWindow::Create(
    const std::vector<std::string>& entrypoint_args,
    RegisterPluginsCallback register_plugins) {
  window_handle_ = CreateWindowEx(
      0, GetWindowClass(), L"", WS_OVERLAPPEDWINDOW, CW_USEDEFAULT,
      CW_USEDEFAULT, kDefaultWidth, kDefaultHeight, nullptr, nullptr,
      GetModuleHandle(nullptr), this);
  if (!window_handle_) {
    return false;
  }

  std::vector<const char*> argv;
  argv.reserve(entrypoint_args.size());
  for (const auto& arg : entrypoint_args) {
    argv.push_back(arg.c_str());
  }

  // Relative paths are resolved against the executable directory.
  FlutterDesktopEngineProperties properties = {};
  properties.assets_path = L"data\\flutter_assets";
  properties.icu_data_path = L"data\\icudtl.dat";
  properties.aot_library_path = L"data\\app.so";
  properties.dart_entrypoint_argc = static_cast<int>(argv.size());
  properties.dart_entrypoint_argv = argv.empty() ? nullptr : argv.data();

  engine_ = FlutterDesktopEngineCreate(&properties);
  if (!engine_) {
    DestroyWindow(window_handle_);
    return false;
  }

  RECT frame;
  GetClientRect(window_handle_, &frame);
  // The view controller takes ownership of the engine.
  controller_ = FlutterDesktopViewControllerCreate(
      frame.right - frame.left, frame.bottom - frame.top, engine_);
  if (!controller_) {
    engine_ = nullptr;
    DestroyWindow(window_handle_);
    return false;
  }

  // Register plugins before parenting the view, like the default runner does.
  // Plugins that subclass `GetAncestor(view, GA_ROOT)` (e.g. media_kit_video,
  // which keeps a single process-wide instance) then subclass the Flutter view
  // in every engine, whose original window procs are interchangeable. If they
  // subclassed this host window instead, messages for the main window's view
  // would be routed to `SecondScreenWindow::WndProc` and crash.
  if (register_plugins) {
    register_plugins(engine_);
  }

  child_content_ =
      FlutterDesktopViewGetHWND(FlutterDesktopViewControllerGetView(controller_));
  SetParent(child_content_, window_handle_);
  ResizeChildContent();
  return true;
}

void SecondScreenWindow::ResizeChildContent() {
  if (!child_content_) {
    return;
  }
  RECT frame;
  GetClientRect(window_handle_, &frame);
  MoveWindow(child_content_, frame.left, frame.top, frame.right - frame.left,
             frame.bottom - frame.top, TRUE);
}

// static
LRESULT CALLBACK SecondScreenWindow::WndProc(HWND window,
                                             UINT message,
                                             WPARAM wparam,
                                             LPARAM lparam) noexcept {
  // A plugin that subclasses windows through a shared delegate can forward
  // another window's messages here. Never interpret a foreign window's
  // GWLP_USERDATA as `SecondScreenWindow*`; hand it to its own class proc.
  if (!IsOwnWindow(window)) {
    auto class_proc =
        reinterpret_cast<WNDPROC>(GetClassLongPtr(window, GCLP_WNDPROC));
    if (class_proc && class_proc != &SecondScreenWindow::WndProc) {
      return CallWindowProc(class_proc, window, message, wparam, lparam);
    }
    return DefWindowProc(window, message, wparam, lparam);
  }

  if (message == WM_NCCREATE) {
    auto create_struct = reinterpret_cast<CREATESTRUCT*>(lparam);
    SetWindowLongPtr(window, GWLP_USERDATA,
                     reinterpret_cast<LONG_PTR>(create_struct->lpCreateParams));
  } else if (auto* that = reinterpret_cast<SecondScreenWindow*>(
                 GetWindowLongPtr(window, GWLP_USERDATA))) {
    return that->MessageHandler(window, message, wparam, lparam);
  }
  return DefWindowProc(window, message, wparam, lparam);
}

LRESULT SecondScreenWindow::MessageHandler(HWND hwnd,
                                           UINT message,
                                           WPARAM wparam,
                                           LPARAM lparam) noexcept {
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (controller_) {
    LRESULT result = 0;
    if (FlutterDesktopViewControllerHandleTopLevelWindowProc(
            controller_, hwnd, message, wparam, lparam, &result)) {
      return result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      if (engine_) {
        FlutterDesktopEngineReloadSystemFonts(engine_);
      }
      break;

    case WM_SIZE:
      ResizeChildContent();
      return 0;

    case WM_ACTIVATE:
      if (child_content_) {
        SetFocus(child_content_);
      }
      return 0;

    case WM_DPICHANGED: {
      // While hidden, geometry is applied explicitly by `configureWindow`
      // in the target monitor's scale; skip the suggested rect.
      if (!IsWindowVisible(hwnd)) {
        return 0;
      }
      auto new_rect = reinterpret_cast<RECT*>(lparam);
      SetWindowPos(hwnd, nullptr, new_rect->left, new_rect->top,
                   new_rect->right - new_rect->left,
                   new_rect->bottom - new_rect->top,
                   SWP_NOZORDER | SWP_NOACTIVATE);
      return 0;
    }

    case WM_DESTROY:
      if (controller_) {
        // Destroys the engine and every plugin registered on it.
        FlutterDesktopViewControllerDestroy(controller_);
        controller_ = nullptr;
        engine_ = nullptr;
        child_content_ = nullptr;
      }
      return 0;

    case WM_NCDESTROY: {
      SetWindowLongPtr(hwnd, GWLP_USERDATA, 0);
      window_handle_ = nullptr;
      // May delete `this`; nothing must touch members afterwards.
      auto on_destroyed = std::move(on_destroyed_);
      if (on_destroyed) {
        on_destroyed(id_);
      }
      return DefWindowProc(hwnd, message, wparam, lparam);
    }
  }

  return DefWindowProc(hwnd, message, wparam, lparam);
}

}  // namespace flutter_second_screen
