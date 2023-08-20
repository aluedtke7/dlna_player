import Cocoa
import FlutterMacOS
import hid_listener

class MainFlutterWindow: NSWindow {
  let listener = HidListener()
  
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController.init()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
