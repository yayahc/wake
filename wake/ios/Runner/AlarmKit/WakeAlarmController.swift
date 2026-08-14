import Foundation
import AlarmKit
import SwiftUI

/// Owns every AlarmKit call. Reachable from both the app and the intents so
/// the re-arm loop keeps working even when the app is not running.
///
/// The loop exists because AlarmKit's Stop button cannot be removed or
/// suppressed. Rather than blocking the dismissal, which iOS does not allow,
/// every dismissal that leaves the quiz unsolved schedules the same alarm
/// again a short delay later. Only `markQuizSolved` ends it.
@available(iOS 26.0, *)
final class WakeAlarmController {
  static let shared = WakeAlarmController()
  private init() {}

  /// How soon a dismissed but unsolved alarm comes back. Short enough to be
  /// a real deterrent, long enough for the user to open the app and answer.
  private static let retryInterval: TimeInterval = 45

  func requestAuthorization() async -> Bool {
    switch AlarmManager.shared.authorizationState {
    case .authorized:
      return true
    case .denied:
      return false
    case .notDetermined:
      let state = try? await AlarmManager.shared.requestAuthorization()
      return state == .authorized
    @unknown default:
      return false
    }
  }

  @discardableResult
  func schedule(alarmId: Int, message: String, at date: Date) async -> Bool {
    guard await requestAuthorization() else {
      NSLog("[Wake] AlarmKit not authorized, alarm \(alarmId) not scheduled")
      return false
    }
    WakeAlarmStore.shared.setMessage(message, for: alarmId)
    WakeAlarmStore.shared.setQuizPending(true, for: alarmId)
    return await arm(alarmId: alarmId, message: message, at: date)
  }

  @discardableResult
  func cancel(alarmId: Int) -> Bool {
    do {
      try AlarmManager.shared.cancel(id: WakeAlarmIdentity.uuid(for: alarmId))
    } catch {
      // Cancelling an alarm that already fired is expected, not a failure.
      NSLog("[Wake] cancel alarm \(alarmId): \(error)")
    }
    WakeAlarmStore.shared.forget(alarmId)
    return true
  }

  /// The single exit from the re-arm loop.
  func markQuizSolved(alarmId: Int) {
    WakeAlarmStore.shared.setQuizPending(false, for: alarmId)
    _ = cancel(alarmId: alarmId)
  }

  /// Runs when the user taps either button on the alert. Both paths re-arm:
  /// tapping "Solve quiz" still stops the current alarm, and the user may
  /// abandon the app before answering.
  func handleDismissal(alarmId: Int, openingApp: Bool) async {
    if openingApp {
      WakeAlarmStore.shared.setPendingQuiz(alarmId)
      WakeAlarmBridge.postQuizRequested()
    }

    guard WakeAlarmStore.shared.isQuizPending(alarmId) else {
      WakeAlarmStore.shared.forget(alarmId)
      return
    }

    let message = WakeAlarmStore.shared.message(for: alarmId) ?? "Wake up"
    await arm(
      alarmId: alarmId,
      message: message,
      at: Date().addingTimeInterval(Self.retryInterval)
    )
  }

  private func arm(alarmId: Int, message: String, at date: Date) async -> Bool {
    let alert = AlarmPresentation.Alert(
      title: LocalizedStringResource(stringLiteral: message),
      stopButton: AlarmButton(
        text: "Stop",
        textColor: .white,
        systemImageName: "stop.circle"
      ),
      secondaryButton: AlarmButton(
        text: "Solve quiz",
        textColor: .white,
        systemImageName: "brain.head.profile"
      ),
      // .custom runs our intent instead of AlarmKit's built-in snooze.
      secondaryButtonBehavior: .custom
    )

    let attributes = AlarmAttributes<WakeAlarmMetadata>(
      presentation: AlarmPresentation(alert: alert),
      metadata: WakeAlarmMetadata(alarmId: alarmId, message: message),
      tintColor: Color.orange
    )

    let configuration = AlarmManager.AlarmConfiguration(
      schedule: .fixed(date),
      attributes: attributes,
      stopIntent: StopWakeAlarmIntent(alarmId: alarmId),
      secondaryIntent: OpenWakeQuizIntent(alarmId: alarmId),
      // Replace with .named("wake_ring") once a sound file is bundled.
      sound: .default
    )

    do {
      // Scheduling with an id that already exists replaces it, which is what
      // the re-arm loop relies on.
      _ = try await AlarmManager.shared.schedule(
        id: WakeAlarmIdentity.uuid(for: alarmId),
        configuration: configuration
      )
      return true
    } catch {
      NSLog("[Wake] failed to schedule alarm \(alarmId): \(error)")
      return false
    }
  }
}
