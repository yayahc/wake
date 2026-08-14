import AppIntents
import Foundation

/// Performed when the user taps Stop on the alarm alert.
///
/// The alarm stops regardless of what this does: iOS owns that button. All we
/// can do is notice the quiz was never solved and arm the next one.
@available(iOS 26.0, *)
struct StopWakeAlarmIntent: LiveActivityIntent {
  static let title: LocalizedStringResource = "Stop Wake alarm"
  static let description = IntentDescription("Stops the current alarm.")

  @Parameter(title: "Alarm")
  var alarmId: Int

  init() {}

  init(alarmId: Int) {
    self.alarmId = alarmId
  }

  func perform() async throws -> some IntentResult {
    await WakeAlarmController.shared.handleDismissal(
      alarmId: alarmId,
      openingApp: false
    )
    return .result()
  }
}

/// Performed when the user taps the secondary button, and opens the app on
/// the quiz. This is the only path that can actually end the alarm chain.
@available(iOS 26.0, *)
struct OpenWakeQuizIntent: LiveActivityIntent {
  static let title: LocalizedStringResource = "Solve Wake quiz"
  static let description = IntentDescription("Opens Wake to answer the skip quiz.")
  static let openAppWhenRun = true

  @Parameter(title: "Alarm")
  var alarmId: Int

  init() {}

  init(alarmId: Int) {
    self.alarmId = alarmId
  }

  func perform() async throws -> some IntentResult {
    await WakeAlarmController.shared.handleDismissal(
      alarmId: alarmId,
      openingApp: true
    )
    return .result()
  }
}
