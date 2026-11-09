#ifndef FLUTTER_PLUGIN_FLUTTER_SECOND_SCREEN_PLUGIN_C_API_H_
#define FLUTTER_PLUGIN_FLUTTER_SECOND_SCREEN_PLUGIN_C_API_H_

#include <flutter_plugin_registrar.h>
#include <flutter_windows.h>

#ifdef FLUTTER_PLUGIN_IMPL
#define FLUTTER_PLUGIN_EXPORT __declspec(dllexport)
#else
#define FLUTTER_PLUGIN_EXPORT __declspec(dllimport)
#endif

#if defined(__cplusplus)
extern "C" {
#endif

FLUTTER_PLUGIN_EXPORT void FlutterSecondScreenPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar);

// Callback invoked for every secondary window engine created by the plugin,
// so the app can register its generated plugins on that engine.
typedef void (*FlutterSecondScreenPluginRegisterPluginsCallback)(
    FlutterDesktopEngineRef engine);

// Sets the callback used to register plugins on secondary window engines.
// Call this once from the runner before the main Flutter window is created.
FLUTTER_PLUGIN_EXPORT void FlutterSecondScreenPluginSetRegisterPluginsCallback(
    FlutterSecondScreenPluginRegisterPluginsCallback callback);

#if defined(__cplusplus)
}  // extern "C"
#endif

#if defined(__cplusplus)
#include <flutter/plugin_registry.h>

#include <string>

namespace flutter_second_screen {

// Adapts a raw engine handle to `flutter::PluginRegistry` so the runner's
// generated `RegisterPlugins` can be reused for secondary window engines:
//
//   FlutterSecondScreenPluginSetRegisterPluginsCallback(
//       [](FlutterDesktopEngineRef engine) {
//         flutter_second_screen::EnginePluginRegistry registry(engine);
//         RegisterPlugins(&registry);
//       });
class EnginePluginRegistry : public flutter::PluginRegistry {
 public:
  explicit EnginePluginRegistry(FlutterDesktopEngineRef engine)
      : engine_(engine) {}

  FlutterDesktopPluginRegistrarRef GetRegistrarForPlugin(
      const std::string& plugin_name) override {
    return FlutterDesktopEngineGetPluginRegistrar(engine_, plugin_name.c_str());
  }

 private:
  FlutterDesktopEngineRef engine_;
};

}  // namespace flutter_second_screen
#endif  // defined(__cplusplus)

#endif  // FLUTTER_PLUGIN_FLUTTER_SECOND_SCREEN_PLUGIN_C_API_H_
