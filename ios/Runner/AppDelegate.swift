import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller = window?.rootViewController as? FlutterViewController
    if let controller = controller {
      let channel = FlutterMethodChannel(
        name: "com.oxynapp.oxyn/platform",
        binaryMessenger: controller.binaryMessenger
      )

      channel.setMethodCallHandler { (call, result) in
        switch call.method {
        case "getStorageInfo":
          result(self.getStorageInfo())
        case "getBatteryDetails":
          result(self.getBatteryDetails())
        case "openBatterySettings":
          if let url = URL(string: "App-Prefs:root=BATTERY_USAGE") {
            UIApplication.shared.open(url)
          }
          result(nil)
        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  private func getStorageInfo() -> [String: Any] {
    do {
      let attrs = try FileManager.default.attributesOfFileSystem(
        forPath: NSHomeDirectory()
      )
      let totalSpace = attrs[.systemSize] as? Int64 ?? 0
      let freeSpace = attrs[.systemFreeSize] as? Int64 ?? 0
      let usedSpace = totalSpace - freeSpace

      return [
        "totalBytes": totalSpace,
        "freeBytes": freeSpace,
        "usedBytes": usedSpace,
      ]
    } catch {
      return [:]
    }
  }

  private func getBatteryDetails() -> [String: Any] {
    UIDevice.current.isBatteryMonitoringEnabled = true
    let level = UIDevice.current.batteryLevel
    let state = UIDevice.current.batteryState

    var stateString = "unknown"
    switch state {
    case .charging: stateString = "charging"
    case .full: stateString = "full"
    case .unplugged: stateString = "discharging"
    default: stateString = "unknown"
    }

    return [
      "level": Int(level * 100),
      "state": stateString,
      "isCharging": state == .charging || state == .full,
    ]
  }
}
