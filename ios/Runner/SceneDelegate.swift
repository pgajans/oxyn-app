import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {
  private var channel: FlutterMethodChannel?

  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    super.scene(scene, willConnectTo: session, options: connectionOptions)

    guard let windowScene = scene as? UIWindowScene,
          let flutterVC = windowScene.windows.first?.rootViewController as? FlutterViewController
    else { return }

    channel = FlutterMethodChannel(
      name: "com.oxynapp.oxyn/platform",
      binaryMessenger: flutterVC.binaryMessenger
    )

    channel?.setMethodCallHandler { [weak self] call, result in
      guard let self = self else { return }
      switch call.method {
      case "getStorageInfo":
        result(self.getStorageInfo())
      case "getBatteryDetails":
        result(self.getBatteryDetails())
      case "getCpuTemperature":
        result(0.0)
      case "openBatterySettings":
        if let url = URL(string: UIApplication.openSettingsURLString) {
          UIApplication.shared.open(url)
        }
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
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
      "temperature": 0.0,
    ]
  }
}
