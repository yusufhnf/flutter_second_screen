cmake_minimum_required(VERSION 3.14)

set(PROJECT_NAME "flutter_second_screen")
project(${PROJECT_NAME} LANGUAGES CXX)

cmake_policy(VERSION 3.14...3.25)

# This value is used when generating builds using this plugin, so it must
# not be changed
set(PLUGIN_NAME "flutter_second_screen_plugin")

list(APPEND PLUGIN_SOURCES
  "flutter_second_screen_plugin.cpp"
  "flutter_second_screen_plugin.h"
  "second_screen_window.cpp"
  "second_screen_window.h"
)

add_library(${PLUGIN_NAME} SHARED
  "include/flutter_second_screen/flutter_second_screen_plugin_c_api.h"
  "flutter_second_screen_plugin_c_api.cpp"
  ${PLUGIN_SOURCES}
)

apply_standard_settings(${PLUGIN_NAME})

set_target_properties(${PLUGIN_NAME} PROPERTIES
  CXX_VISIBILITY_PRESET hidden)
target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)

target_include_directories(${PLUGIN_NAME} INTERFACE
  "${CMAKE_CURRENT_SOURCE_DIR}/include")
target_link_libraries(${PLUGIN_NAME} PRIVATE flutter flutter_wrapper_plugin)

# List of absolute paths to libraries that should be bundled with the plugin.
set(flutter_second_screen_bundled_libraries
  ""
  PARENT_SCOPE
)
