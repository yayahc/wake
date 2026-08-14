import Flutter
import Foundation

/// MethodChannel side of the AlarmKit bridge. Runner target only: the widget
/// extension must not link Flutter.
final class WakeAlarmPlugin: NSObject {
  private static let channelName = "dev.yayahc.wake/alarmkit"

  /// The Darwin observer callback is a C function pointer and cannot capture
  /// context, so it reaches the instance through here.
  private static var current: WakeAlarmPlugin?

  private let channel: FlutterMethodChannel

  private init(channel: FlutterMethodChannel) {
    self.channel = channel
    super.init()
  }

  static func register(with messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: channelName, binaryMessenger: messenger)
    let plugin = WakeAlarmPlugin(channel: channel)
    current = plugin
    channel.setMethodCallHandler { call, result in
      plugin.handle(call, result: result)
    }
    plugin.observeQuizRequests()
  }

  private func observeQuizRequests() {
    CFNotificationCenterAddObserver(
      CFNotificationCenterGetDarwinNotifyCenter(),
      nil,
      { _, _, _, _, _ in
        WakeAlarmPlugin.current?.forwardQuizRequest()
      },
      WakeAlarmIdentity.quizRequestedNotification as CFString,
      nil,
      .deliverImmediately
    )
  }

  /// Peeks rather than consumes: the pending slot stays set until the quiz is
  /// actually solved, so abandoning the app mid-quiz still owes an answer on
  /// the next launch.
  private func forwardQuizRequest() {
    guard let alarmId = WakeAlarmStore.shared.pendingQuizAlarmId() else { return }
    DispatchQueue.main.async {
      self.channel.invokeMethod("onQuizRequested", arguments: alarmId)
    }
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard #available(iOS 26.0, *) else {
      // AlarmKit is the only sanctioned way to ring through silent mode and
      // Focus. Below iOS 26 there is no equivalent, so fail loudly rather
      // than silently arming something that will not wake anyone.
      result(
        FlutterError(
          code: "unsupported_os",
          message: "Wake alarms require iOS 26 or later.",
          details: nil
        )
      )
      return
    }

    let arguments = call.arguments as? [String: Any]

    switch call.method {
    case "requestAuthorization":
      Task {
        let granted = await WakeAlarmController.shared.requestAuthorization()
        result(granted)
      }

    case "schedule":
      guard
        let alarmId = arguments?["id"] as? Int,
        let ringAtEpochMs = arguments?["ringAtEpochMs"] as? Int,
        let message = arguments?["message"] as? String
      else {
        result(Self.badArguments(call.method))
        return
      }
      let date = Date(timeIntervalSince1970: TimeInterval(ringAtEpochMs) / 1000)
      Task {
        let scheduled = await WakeAlarmController.shared.schedule(
          alarmId: alarmId,
          message: message,
          at: date
        )
        result(scheduled)
      }

    case "cancel":
      guard let alarmId = arguments?["id"] as? Int else {
        result(Self.badArguments(call.method))
        return
      }
      result(WakeAlarmController.shared.cancel(alarmId: alarmId))

    case "markQuizSolved":
      guard let alarmId = arguments?["id"] as? Int else {
        result(Self.badArguments(call.method))
        return
      }
      WakeAlarmController.shared.markQuizSolved(alarmId: alarmId)
      result(nil)

    case "pendingQuizAlarmId":
      result(WakeAlarmStore.shared.pendingQuizAlarmId())

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private static func badArguments(_ method: String) -> FlutterError {
    FlutterError(
      code: "bad_arguments",
      message: "Missing or malformed arguments for \(method).",
      details: nil
    )
  }
}
