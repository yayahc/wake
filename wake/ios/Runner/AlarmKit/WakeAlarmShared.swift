import Foundation
import AlarmKit

/// Files in this directory are shared between the Runner app and the
/// WakeAlarmWidget extension. Both targets need them: the extension renders
/// the alarm presentation, and the intents can be performed by either
/// process. Keep them free of Flutter imports.

enum WakeAlarmIdentity {
  /// Must match the App Group enabled on both the Runner and the widget
  /// extension targets.
  static let appGroup = "group.dev.yayahc.wake"

  /// Darwin notification used to reach the app process from whichever
  /// process ends up performing the intent.
  static let quizRequestedNotification = "dev.yayahc.wake.quizRequested"

  /// Alarm rows are identified by an int in Drift but AlarmKit wants a UUID.
  /// Deriving one from the row id keeps the mapping stateless in both
  /// directions, so no lookup table has to stay in sync.
  static func uuid(for alarmId: Int) -> UUID {
    let hex = String(format: "%012llx", UInt64(max(0, alarmId)))
    return UUID(uuidString: "00000000-0000-4000-8000-\(hex)")!
  }

  static func alarmId(for uuid: UUID) -> Int? {
    let suffix = uuid.uuidString.split(separator: "-").last.map(String.init) ?? ""
    guard let value = UInt64(suffix, radix: 16) else { return nil }
    return Int(value)
  }
}

/// State that has to outlive the app process and be readable from the widget
/// extension, so it lives in the shared App Group rather than in Drift.
struct WakeAlarmStore {
  static let shared = WakeAlarmStore()

  private let defaults: UserDefaults?

  private init() {
    defaults = UserDefaults(suiteName: WakeAlarmIdentity.appGroup)
    if defaults == nil {
      NSLog("[Wake] App Group \(WakeAlarmIdentity.appGroup) is not configured")
    }
  }

  private func quizKey(_ id: Int) -> String { "wake.quizPending.\(id)" }
  private func messageKey(_ id: Int) -> String { "wake.message.\(id)" }
  private let pendingQuizKey = "wake.pendingQuizAlarmId"

  /// True while the user still owes a correct quiz answer for this alarm.
  /// This is the flag the re-arm loop reads.
  func isQuizPending(_ id: Int) -> Bool {
    defaults?.bool(forKey: quizKey(id)) ?? false
  }

  func setQuizPending(_ pending: Bool, for id: Int) {
    defaults?.set(pending, forKey: quizKey(id))
  }

  func message(for id: Int) -> String? {
    defaults?.string(forKey: messageKey(id))
  }

  func setMessage(_ message: String, for id: Int) {
    defaults?.set(message, forKey: messageKey(id))
  }

  /// Handoff slot for a cold start: the app was launched by the alert, so
  /// Dart was not listening when the intent ran.
  ///
  /// Deliberately not consumed on read. It stays set until the quiz is
  /// solved, so abandoning the app halfway still owes an answer next launch.
  func setPendingQuiz(_ id: Int) {
    defaults?.set(id, forKey: pendingQuizKey)
  }

  func pendingQuizAlarmId() -> Int? {
    guard let defaults, defaults.object(forKey: pendingQuizKey) != nil else { return nil }
    return defaults.integer(forKey: pendingQuizKey)
  }

  func clearPendingQuiz(ifMatching id: Int) {
    guard pendingQuizAlarmId() == id else { return }
    defaults?.removeObject(forKey: pendingQuizKey)
  }

  func forget(_ id: Int) {
    defaults?.removeObject(forKey: quizKey(id))
    defaults?.removeObject(forKey: messageKey(id))
    clearPendingQuiz(ifMatching: id)
  }
}

enum WakeAlarmBridge {
  /// Posted cross-process because a LiveActivityIntent may be performed by
  /// the widget extension rather than the app.
  static func postQuizRequested() {
    CFNotificationCenterPostNotification(
      CFNotificationCenterGetDarwinNotifyCenter(),
      CFNotificationName(WakeAlarmIdentity.quizRequestedNotification as CFString),
      nil,
      nil,
      true
    )
  }
}

/// Payload carried alongside the alarm so the Live Activity can render the
/// user's own message.
@available(iOS 26.0, *)
struct WakeAlarmMetadata: AlarmMetadata {
  let alarmId: Int
  let message: String

  init(alarmId: Int, message: String) {
    self.alarmId = alarmId
    self.message = message
  }
}
