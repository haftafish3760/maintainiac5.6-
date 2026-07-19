import Flutter
import Network
import UIKit

final class DeviceCapabilityEvents: NSObject, FlutterStreamHandler {
  private var sink: FlutterEventSink?
  private var observers: [NSObjectProtocol] = []
  private var pathMonitor: NWPathMonitor?

  func register(with messenger: FlutterBinaryMessenger) {
    FlutterEventChannel(
      name: Self.channelName,
      binaryMessenger: messenger
    ).setStreamHandler(self)
  }

  func onListen(
    withArguments arguments: Any?,
    eventSink events: @escaping FlutterEventSink
  ) -> FlutterError? {
    sink = events
    UIDevice.current.isBatteryMonitoringEnabled = true
    let center = NotificationCenter.default
    let names: [(Notification.Name, String)] = [
      (UIDevice.batteryLevelDidChangeNotification, "battery"),
      (UIDevice.batteryStateDidChangeNotification, "battery"),
      (Notification.Name.NSProcessInfoPowerStateDidChange, "power"),
      (ProcessInfo.thermalStateDidChangeNotification, "thermal")
    ]
    observers = names.map { name, reason in
      center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
        self?.emit(reason)
      }
    }
    let monitor = NWPathMonitor()
    monitor.pathUpdateHandler = { [weak self] _ in self?.emit("network") }
    monitor.start(queue: DispatchQueue(label: "com.maintainiac.capability-events-network"))
    pathMonitor = monitor
    emit("subscribed")
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    observers.forEach(NotificationCenter.default.removeObserver)
    observers.removeAll()
    pathMonitor?.cancel()
    pathMonitor = nil
    sink = nil
    return nil
  }

  private func emit(_ reason: String) {
    let payload: [String: Any] = [
      "reason": reason,
      "atMs": Int(Date().timeIntervalSince1970 * 1_000)
    ]
    DispatchQueue.main.async { [weak self] in self?.sink?(payload) }
  }

  private static let channelName = "maintainiac/device_capability_events"
}
