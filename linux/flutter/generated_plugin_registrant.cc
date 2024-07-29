//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <scroll_screenshot/scroll_screenshot_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) scroll_screenshot_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "ScrollScreenshotPlugin");
  scroll_screenshot_plugin_register_with_registrar(scroll_screenshot_registrar);
}
