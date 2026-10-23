import Flutter
import Foundation

final class FoldChannelBridge: NSObject {

  static let methodChannelName = "com.duo/fold"
  static let eventChannelName = "com.duo/fold_events"

  private let monitor = FoldStateMonitor.shared
  private let methodChannel: FlutterMethodChannel
  private let eventChannel: FlutterEventChannel
  private var eventSink: FlutterEventSink?

  init(messenger: FlutterBinaryMessenger) {
    methodChannel = FlutterMethodChannel(
      name: FoldChannelBridge.methodChannelName,
      binaryMessenger: messenger
    )
    eventChannel = FlutterEventChannel(
      name: FoldChannelBridge.eventChannelName,
      binaryMessenger: messenger
    )
    super.init()

    monitor.onUpdate = { [weak self] state in
      guard let self else { return }
      self.eventSink?(state.toDictionary())
      self.methodChannel.invokeMethod(
        "onFoldStateChanged", arguments: state.toDictionary())
    }

    methodChannel.setMethodCallHandler { [weak self] call, result in
      self?.handle(call, result: result)
    }
    eventChannel.setStreamHandler(self)
  }

  func start() {
    monitor.start()
  }

  func stop() {
    monitor.stop()
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getCurrentState":
      result(monitor.lastState?.toDictionary())
    case "startMonitoring":
      monitor.start()
      result(true)
    case "stopMonitoring":
      monitor.stop()
      result(true)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}

extension FoldChannelBridge: FlutterStreamHandler {
  func onListen(
    withArguments arguments: Any?,
    eventSink events: @escaping FlutterEventSink
  ) -> FlutterError? {
    eventSink = events
    if let lastState = monitor.lastState {
      events(lastState.toDictionary())
    }
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    return nil
  }
}
