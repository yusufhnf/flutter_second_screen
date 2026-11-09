#include "flutter_second_screen_plugin.h"

// This must be included before many other Windows headers.
#include <windows.h>

#include <flutter/method_result_functions.h>
#include <flutter/standard_method_codec.h>
#include <flutter_windows.h>
#include <shobjidl.h>

#include <algorithm>
#include <cmath>
#include <map>
#include <string>
#include <type_traits>
#include <vector>

namespace flutter_second_screen {

namespace {

using flutter::EncodableList;
using flutter::EncodableMap;
using flutter::EncodableValue;

constexpr char kChannelName[] =
    "com.meetucup.flutter_second_screen/desktop_methods";

constexpr double kBaseDpi = 96.0;

// Native bookkeeping for a single Flutter window managed by this plugin.
struct WindowEntry {
  // The top-level window handle.
  HWND hwnd = nullptr;

  // The plugin instance bound to the engine rendering this window.
  FlutterSecondScreenPlugin* plugin = nullptr;

  // The host window created by this plugin, `nullptr` for the main window.
  std::unique_ptr<SecondScreenWindow> owned_window;
};

// All windows known to the plugin, keyed by window ID (`0` is the main
// window). Intentionally leaked to avoid destruction order issues at exit.
std::map<int, WindowEntry>& Windows() {
  static auto* windows = new std::map<int, WindowEntry>();
  return *windows;
}

SecondScreenWindow::RegisterPluginsCallback g_register_plugins = nullptr;

// --- Argument helpers ---

const EncodableValue* FindValue(const EncodableMap& map, const char* key) {
  auto it = map.find(EncodableValue(key));
  if (it == map.end() || it->second.IsNull()) {
    return nullptr;
  }
  return &it->second;
}

std::optional<int> GetInt(const EncodableMap& map, const char* key) {
  const auto* value = FindValue(map, key);
  if (!value) {
    return std::nullopt;
  }
  if (const auto* int_value = std::get_if<int32_t>(value)) {
    return *int_value;
  }
  if (const auto* long_value = std::get_if<int64_t>(value)) {
    return static_cast<int>(*long_value);
  }
  return std::nullopt;
}

std::optional<double> GetDouble(const EncodableMap& map, const char* key) {
  const auto* value = FindValue(map, key);
  if (!value) {
    return std::nullopt;
  }
  if (const auto* double_value = std::get_if<double>(value)) {
    return *double_value;
  }
  if (const auto* int_value = std::get_if<int32_t>(value)) {
    return static_cast<double>(*int_value);
  }
  if (const auto* long_value = std::get_if<int64_t>(value)) {
    return static_cast<double>(*long_value);
  }
  return std::nullopt;
}

bool GetBool(const EncodableMap& map, const char* key, bool fallback) {
  const auto* value = FindValue(map, key);
  if (const auto* bool_value = value ? std::get_if<bool>(value) : nullptr) {
    return *bool_value;
  }
  return fallback;
}

std::optional<std::string> GetString(const EncodableMap& map,
                                     const char* key) {
  const auto* value = FindValue(map, key);
  if (const auto* string_value =
          value ? std::get_if<std::string>(value) : nullptr) {
    return *string_value;
  }
  return std::nullopt;
}

// --- String helpers ---

std::wstring Utf8ToWide(const std::string& input) {
  if (input.empty()) {
    return std::wstring();
  }
  int length = MultiByteToWideChar(CP_UTF8, 0, input.data(),
                                   static_cast<int>(input.size()), nullptr, 0);
  std::wstring output(length, L'\0');
  MultiByteToWideChar(CP_UTF8, 0, input.data(), static_cast<int>(input.size()),
                      output.data(), length);
  return output;
}

std::string WideToUtf8(const std::wstring& input) {
  if (input.empty()) {
    return std::string();
  }
  int length =
      WideCharToMultiByte(CP_UTF8, 0, input.data(),
                          static_cast<int>(input.size()), nullptr, 0, nullptr,
                          nullptr);
  std::string output(length, '\0');
  WideCharToMultiByte(CP_UTF8, 0, input.data(), static_cast<int>(input.size()),
                      output.data(), length, nullptr, nullptr);
  return output;
}

// --- Display helpers ---

// `FlutterDesktopGetDpiForMonitor` takes an `HMONITOR` in current Flutter
// versions and an `intptr_t` in older ones; support both.
template <typename GetDpiFunction>
UINT CallGetDpiForMonitor(GetDpiFunction get_dpi, HMONITOR monitor) {
  if constexpr (std::is_invocable_v<GetDpiFunction, HMONITOR>) {
    return get_dpi(monitor);
  } else {
    return get_dpi(reinterpret_cast<intptr_t>(monitor));
  }
}

double GetScaleFactor(HMONITOR monitor) {
  return CallGetDpiForMonitor(&FlutterDesktopGetDpiForMonitor, monitor) /
         kBaseDpi;
}

MONITORINFOEXW GetMonitorInfoEx(HMONITOR monitor) {
  MONITORINFOEXW info{};
  info.cbSize = sizeof(MONITORINFOEXW);
  GetMonitorInfoW(monitor, &info);
  return info;
}

// Returns all connected monitors, with the primary monitor first.
std::vector<HMONITOR> GetMonitors() {
  std::vector<HMONITOR> monitors;
  EnumDisplayMonitors(
      nullptr, nullptr,
      [](HMONITOR monitor, HDC, LPRECT, LPARAM data) -> BOOL {
        reinterpret_cast<std::vector<HMONITOR>*>(data)->push_back(monitor);
        return TRUE;
      },
      reinterpret_cast<LPARAM>(&monitors));
  std::stable_partition(monitors.begin(), monitors.end(), [](HMONITOR m) {
    return (GetMonitorInfoEx(m).dwFlags & MONITORINFOF_PRIMARY) != 0;
  });
  return monitors;
}

// Finds the monitor containing a point expressed in logical pixels, where
// each monitor's logical bounds are its physical bounds divided by its scale.
HMONITOR MonitorFromLogicalPoint(double x, double y) {
  for (HMONITOR monitor : GetMonitors()) {
    const double scale = GetScaleFactor(monitor);
    const RECT& rect = GetMonitorInfoEx(monitor).rcMonitor;
    if (x >= rect.left / scale && x < rect.right / scale &&
        y >= rect.top / scale && y < rect.bottom / scale) {
      return monitor;
    }
  }
  POINT point{static_cast<LONG>(x), static_cast<LONG>(y)};
  return MonitorFromPoint(point, MONITOR_DEFAULTTOPRIMARY);
}

std::string GetMonitorName(const MONITORINFOEXW& info, size_t index) {
  DISPLAY_DEVICEW device{};
  device.cb = sizeof(DISPLAY_DEVICEW);
  if (EnumDisplayDevicesW(info.szDevice, 0, &device, 0) &&
      device.DeviceString[0] != L'\0') {
    return WideToUtf8(device.DeviceString);
  }
  if (info.szDevice[0] != L'\0') {
    return WideToUtf8(info.szDevice);
  }
  return "Display " + std::to_string(index);
}

EncodableList GetDisplays() {
  EncodableList displays;
  const auto monitors = GetMonitors();
  for (size_t index = 0; index < monitors.size(); ++index) {
    HMONITOR monitor = monitors[index];
    const auto info = GetMonitorInfoEx(monitor);
    const double scale = GetScaleFactor(monitor);
    const RECT& bounds = info.rcMonitor;
    const RECT& work = info.rcWork;

    displays.push_back(EncodableValue(EncodableMap{
        {EncodableValue("id"), EncodableValue(static_cast<int>(index))},
        {EncodableValue("name"), EncodableValue(GetMonitorName(info, index))},
        {EncodableValue("width"),
         EncodableValue(std::round((bounds.right - bounds.left) / scale))},
        {EncodableValue("height"),
         EncodableValue(std::round((bounds.bottom - bounds.top) / scale))},
        {EncodableValue("visibleWidth"),
         EncodableValue(std::round((work.right - work.left) / scale))},
        {EncodableValue("visibleHeight"),
         EncodableValue(std::round((work.bottom - work.top) / scale))},
        {EncodableValue("x"), EncodableValue(std::round(bounds.left / scale))},
        {EncodableValue("y"), EncodableValue(std::round(bounds.top / scale))},
        {EncodableValue("visibleX"),
         EncodableValue(std::round(work.left / scale))},
        {EncodableValue("visibleY"),
         EncodableValue(std::round(work.top / scale))},
        {EncodableValue("isPrimary"),
         EncodableValue((info.dwFlags & MONITORINFOF_PRIMARY) != 0)},
    }));
  }
  return displays;
}

void SetSkipTaskbar(HWND hwnd) {
  ITaskbarList* taskbar = nullptr;
  if (SUCCEEDED(CoCreateInstance(CLSID_TaskbarList, nullptr,
                                 CLSCTX_INPROC_SERVER,
                                 IID_PPV_ARGS(&taskbar)))) {
    if (SUCCEEDED(taskbar->HrInit())) {
      taskbar->DeleteTab(hwnd);
    }
    taskbar->Release();
  }
}

}  // namespace

// static
void FlutterSecondScreenPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows* registrar) {
  auto plugin = std::make_unique<FlutterSecondScreenPlugin>(registrar);
  registrar->AddPlugin(std::move(plugin));
}

// static
void FlutterSecondScreenPlugin::SetRegisterPluginsCallback(
    SecondScreenWindow::RegisterPluginsCallback callback) {
  g_register_plugins = callback;
}

FlutterSecondScreenPlugin::FlutterSecondScreenPlugin(
    flutter::PluginRegistrarWindows* registrar)
    : registrar_(registrar) {
  channel_ = std::make_unique<flutter::MethodChannel<EncodableValue>>(
      registrar->messenger(), kChannelName,
      &flutter::StandardMethodCodec::GetInstance());
  channel_->SetMethodCallHandler([this](const auto& call, auto result) {
    HandleMethodCall(call, std::move(result));
  });
}

FlutterSecondScreenPlugin::~FlutterSecondScreenPlugin() {
  if (!window_id_) {
    return;
  }
  auto& windows = Windows();
  auto it = windows.find(*window_id_);
  if (it == windows.end() || it->second.plugin != this) {
    return;
  }
  if (it->second.owned_window) {
    // The host window releases itself once it is destroyed.
    it->second.plugin = nullptr;
  } else {
    windows.erase(it);
  }
}

void FlutterSecondScreenPlugin::HandleMethodCall(
    const flutter::MethodCall<EncodableValue>& method_call,
    std::unique_ptr<MethodResult> result) {
  const auto* args_ptr = std::get_if<EncodableMap>(method_call.arguments());
  const EncodableMap args = args_ptr ? *args_ptr : EncodableMap();
  const std::string& method = method_call.method_name();

  if (method != "ensureInitialized") {
    BindToWindowIfNeeded();
  }

  if (method == "ensureInitialized") {
    EnsureInitialized(args, std::move(result));
  } else if (method == "createWindow") {
    CreateSecondaryWindow(args, std::move(result));
  } else if (method == "getWindowId") {
    result->Success(EncodableValue(window_id_.value_or(0)));
  } else if (method == "getWindowIds") {
    EncodableList ids;
    for (const auto& window : Windows()) {
      ids.push_back(EncodableValue(window.first));
    }
    result->Success(EncodableValue(ids));
  } else if (method == "getDisplays") {
    result->Success(EncodableValue(GetDisplays()));
  } else if (method == "configureWindow") {
    ConfigureWindow(args, std::move(result));
  } else if (method == "closeWindow") {
    CloseWindow(args, std::move(result));
  } else if (method == "focusWindow") {
    FocusWindow(args, std::move(result));
  } else if (method == "sendEvent") {
    SendEvent(args, std::move(result));
  } else {
    result->NotImplemented();
  }
}

// --- Window lifecycle ---

void FlutterSecondScreenPlugin::EnsureInitialized(
    const EncodableMap& args,
    std::unique_ptr<MethodResult> result) {
  BindToWindow(GetInt(args, "windowId").value_or(0));
  result->Success(EncodableValue(true));
}

void FlutterSecondScreenPlugin::BindToWindowIfNeeded() {
  if (window_id_) {
    return;
  }
  // A window created by this plugin keeps its ID; any other is the main one.
  HWND own_window = GetOwnWindow();
  for (const auto& [id, entry] : Windows()) {
    if (own_window && entry.owned_window && entry.hwnd == own_window) {
      BindToWindow(id);
      return;
    }
  }
  BindToWindow(0);
}

void FlutterSecondScreenPlugin::BindToWindow(int id) {
  window_id_ = id;

  auto& entry = Windows()[id];
  if (!entry.hwnd) {
    entry.hwnd = GetOwnWindow();
  }
  entry.plugin = this;
}

void FlutterSecondScreenPlugin::CreateSecondaryWindow(
    const EncodableMap& args,
    std::unique_ptr<MethodResult> result) {
  if (!g_register_plugins) {
    result->Error("UNAVAILABLE",
                  "FlutterSecondScreenPluginSetRegisterPluginsCallback has not "
                  "been called. Set it in windows/runner/flutter_window.cpp.");
    return;
  }

  int id = 1;
  while (Windows().count(id) > 0) {
    ++id;
  }

  std::vector<std::string> entrypoint_args{std::to_string(id)};
  if (const auto* value = FindValue(args, "arguments")) {
    if (const auto* list = std::get_if<EncodableList>(value)) {
      for (const auto& item : *list) {
        if (const auto* argument = std::get_if<std::string>(&item)) {
          entrypoint_args.push_back(*argument);
        }
      }
    }
  }

  auto window = std::make_unique<SecondScreenWindow>(
      id, [](int destroyed_id) { Windows().erase(destroyed_id); });
  if (!window->Create(entrypoint_args, g_register_plugins)) {
    result->Error("CREATE_FAILED", "Failed to create the secondary window.");
    return;
  }

  WindowEntry entry;
  entry.hwnd = window->GetHandle();
  entry.owned_window = std::move(window);
  Windows()[id] = std::move(entry);

  result->Success(EncodableValue(id));
}

void FlutterSecondScreenPlugin::CloseWindow(
    const EncodableMap& args,
    std::unique_ptr<MethodResult> result) {
  // Posted so that an engine closing its own window finishes this call first.
  if (HWND hwnd = GetWindowForId(GetInt(args, "windowId"))) {
    PostMessage(hwnd, WM_CLOSE, 0, 0);
  }
  result->Success();
}

void FlutterSecondScreenPlugin::FocusWindow(
    const EncodableMap& args,
    std::unique_ptr<MethodResult> result) {
  if (HWND hwnd = GetWindowForId(GetInt(args, "windowId"))) {
    if (IsIconic(hwnd)) {
      ShowWindow(hwnd, SW_RESTORE);
    }
    SetForegroundWindow(hwnd);
  }
  result->Success();
}

// --- Window configuration ---

void FlutterSecondScreenPlugin::ConfigureWindow(
    const EncodableMap& args,
    std::unique_ptr<MethodResult> result) {
  HWND hwnd = GetOwnWindow();
  if (!hwnd) {
    result->Success(EncodableValue(false));
    return;
  }

  const bool full_screen = GetBool(args, "fullScreen", false);
  const bool center = GetBool(args, "center", false);
  const bool resizable = GetBool(args, "resizable", false);
  const bool always_on_top = GetBool(args, "alwaysOnTop", false);
  const bool maximize = GetBool(args, "maximize", false);
  const auto width = GetDouble(args, "width");
  const auto height = GetDouble(args, "height");
  const auto x = GetDouble(args, "x");
  const auto y = GetDouble(args, "y");

  if (const auto title = GetString(args, "title")) {
    SetWindowText(hwnd, Utf8ToWide(*title).c_str());
  }

  // Resolve the target monitor from the requested logical position.
  HMONITOR monitor = (x && y) ? MonitorFromLogicalPoint(*x, *y)
                              : MonitorFromWindow(hwnd, MONITOR_DEFAULTTONEAREST);
  const auto monitor_info = GetMonitorInfoEx(monitor);
  const double scale = GetScaleFactor(monitor);

  constexpr DWORD kOverlappedStyle = static_cast<DWORD>(WS_OVERLAPPEDWINDOW);
  constexpr DWORD kPopupStyle = static_cast<DWORD>(WS_POPUP);
  constexpr DWORD kResizeStyle =
      static_cast<DWORD>(WS_THICKFRAME | WS_MAXIMIZEBOX);
  DWORD style = static_cast<DWORD>(GetWindowLong(hwnd, GWL_STYLE));
  if (full_screen) {
    style = (style & ~kOverlappedStyle) | kPopupStyle;
  } else {
    style = (style & ~kPopupStyle) | kOverlappedStyle;
    if (!resizable) {
      style &= ~kResizeStyle;
    }
  }
  SetWindowLong(hwnd, GWL_STYLE, static_cast<LONG>(style));

  RECT frame;
  if (full_screen) {
    frame = monitor_info.rcMonitor;
  } else {
    RECT current;
    GetWindowRect(hwnd, &current);
    const RECT& work = monitor_info.rcWork;
    const LONG frame_width = width ? static_cast<LONG>(std::lround(*width * scale))
                                   : current.right - current.left;
    const LONG frame_height = height
                                  ? static_cast<LONG>(std::lround(*height * scale))
                                  : current.bottom - current.top;
    LONG left = current.left;
    LONG top = current.top;
    if (x && y) {
      left = static_cast<LONG>(std::lround(*x * scale));
      top = static_cast<LONG>(std::lround(*y * scale));
    } else if (center) {
      left = work.left + ((work.right - work.left) - frame_width) / 2;
      top = work.top + ((work.bottom - work.top) - frame_height) / 2;
    }
    frame = RECT{left, top, left + frame_width, top + frame_height};
  }

  // Move first so a DPI change between monitors does not rescale the
  // requested size, then apply the exact size.
  SetWindowPos(hwnd, nullptr, frame.left, frame.top, 0, 0,
               SWP_NOSIZE | SWP_NOZORDER | SWP_NOACTIVATE | SWP_FRAMECHANGED);
  SetWindowPos(hwnd, nullptr, frame.left, frame.top, frame.right - frame.left,
               frame.bottom - frame.top, SWP_NOZORDER | SWP_NOACTIVATE);

  SetWindowPos(hwnd, always_on_top ? HWND_TOPMOST : HWND_NOTOPMOST, 0, 0, 0, 0,
               SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE);

  ShowWindow(hwnd, (!full_screen && maximize) ? SW_MAXIMIZE : SW_SHOW);

  if (GetBool(args, "skipTaskbar", false)) {
    SetSkipTaskbar(hwnd);
  }

  result->Success(EncodableValue(true));
}

// --- Messaging ---

void FlutterSecondScreenPlugin::SendEvent(
    const EncodableMap& args,
    std::unique_ptr<MethodResult> result) {
  const int target_id = GetInt(args, "targetWindowId").value_or(1);
  auto it = Windows().find(target_id);
  if (it == Windows().end() || !it->second.plugin) {
    result->Error("WINDOW_NOT_FOUND", "No initialized window found with id " +
                                          std::to_string(target_id) + ".");
    return;
  }

  const auto* data = FindValue(args, "data");
  EncodableMap payload{
      {EncodableValue("eventName"),
       EncodableValue(GetString(args, "eventName").value_or(""))},
      {EncodableValue("fromWindowId"), EncodableValue(window_id_.value_or(0))},
      {EncodableValue("data"), data ? *data : EncodableValue()},
  };

  std::shared_ptr<MethodResult> shared_result = std::move(result);
  it->second.plugin->channel_->InvokeMethod(
      "onEvent", std::make_unique<EncodableValue>(payload),
      std::make_unique<flutter::MethodResultFunctions<EncodableValue>>(
          [shared_result](const EncodableValue* value) {
            shared_result->Success(value ? *value : EncodableValue());
          },
          [shared_result](const std::string& code, const std::string& message,
                          const EncodableValue* details) {
            shared_result->Error(code, message,
                                 details ? *details : EncodableValue());
          },
          [shared_result]() { shared_result->NotImplemented(); }));
}

// --- Helpers ---

HWND FlutterSecondScreenPlugin::GetOwnWindow() const {
  auto* view = registrar_->GetView();
  if (!view) {
    return nullptr;
  }
  return GetAncestor(view->GetNativeWindow(), GA_ROOT);
}

HWND FlutterSecondScreenPlugin::GetWindowForId(
    std::optional<int> window_id) const {
  if (window_id) {
    auto it = Windows().find(*window_id);
    if (it != Windows().end() && it->second.hwnd) {
      return it->second.hwnd;
    }
    if (*window_id != window_id_) {
      return nullptr;
    }
  }
  return GetOwnWindow();
}

}  // namespace flutter_second_screen
