#include "include/flutter_second_screen/flutter_second_screen_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "flutter_second_screen_plugin.h"

void FlutterSecondScreenPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  flutter_second_screen::FlutterSecondScreenPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}

void FlutterSecondScreenPluginSetRegisterPluginsCallback(
    FlutterSecondScreenPluginRegisterPluginsCallback callback) {
  flutter_second_screen::FlutterSecondScreenPlugin::SetRegisterPluginsCallback(
      callback);
}
