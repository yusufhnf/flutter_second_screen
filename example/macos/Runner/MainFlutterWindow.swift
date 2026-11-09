import Cocoa
import FlutterMacOS
import flutter_second_screen

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)
    // Register plugins on every secondary window engine as well.
    FlutterSecondScreenPlugin.registerGeneratedPlugins = { registry in
      RegisterGeneratedPlugins(registry: registry)
    }

    super.awakeFromNib()
  }
}
