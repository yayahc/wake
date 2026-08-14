import AlarmKit
import AppIntents
import Foundation
import SwiftUI

/// Drives the AlarmKit alert and the skip-prevention re-arm loop.
///
/// iOS has no equivalent of Android's full-screen intent. AlarmKit's alert always
/// carries a Stop affordance that cannot be removed, suppressed, or intercepted
/// before it fires — and as of iOS 26.1 the system supplies that button itself.
/// Skip prevention is therefore a re-arm loop, not a lock: any dismissal that
/// leaves the quiz unsolved schedules the same alarm again `retryInterval` later.
/// `markQuizSolved` is the only exit.
@available(iOS 26.0, *)
enum WakeAlarmController {
    /// How long after a dismissal the alarm comes back. Not user-configurable.
    static let retryInterval: TimeInterval = 45

    private static var manager: AlarmManager { AlarmManager.shared }

    // MARK: - Authorization

    @discardableResult
    static func requestAuthorization() async -> Bool {
        switch manager.authorizationState {
        case .authorized:
            return true
        case .denied:
            return false
        case .notDetermined:
            do {
                return try await manager.requestAuthorization() == .authorized
            } catch {
                NSLog("[WakeAlarm] Authorization request failed: \(error)")
                return false
            }
        @unknown default:
            return false
        }
    }

    // MARK: - Arming

    /// Arms a brand new alarm and stores the record that drives the loop.
    @discardableResult
    static func arm(alarmId: Int, message: String, ringAt: Date) async throws -> UUID {
        // A fresh arm supersedes anything still pending for the same row.
        try await cancelAll(alarmId: alarmId)

        let record = WakeAlarmRecord(alarmId: alarmId, message: message, ringAt: ringAt)
        WakeAlarmStore.upsert(record)
        try await schedule(record)
        return record.id
    }

    /// Re-arms an existing record `retryInterval` from now.
    ///
    /// Called when the alert is dismissed with the quiz still unsolved. Bumps
    /// `retryCount` so the alert can tell the user this is a repeat.
    static func rearm(id: UUID) async {
        guard let current = WakeAlarmStore.record(id: id) else {
            NSLog("[WakeAlarm] Nothing to re-arm for \(id.uuidString).")
            return
        }
        guard !current.solved else { return }

        guard let updated = WakeAlarmStore.mutate(id: id, { record in
            record.ringAt = Date().addingTimeInterval(retryInterval)
            record.retryCount += 1
        }) else { return }

        do {
            try await schedule(updated)
            NSLog("[WakeAlarm] Re-armed \(id.uuidString) (retry \(updated.retryCount)).")
        } catch {
            NSLog("[WakeAlarm] Re-arm failed for \(id.uuidString): \(error)")
        }
    }

    /// The one exit from the loop. Cancels the pending alert and clears the record.
    static func markQuizSolved(id: UUID) {
        WakeAlarmStore.mutate(id: id) { $0.solved = true }
        try? manager.cancel(id: id)
        WakeAlarmStore.remove(id: id)
        NSLog("[WakeAlarm] Quiz solved for \(id.uuidString); chain ended.")
    }

    // MARK: - Cancelling

    static func cancelAll(alarmId: Int) async throws {
        for record in WakeAlarmStore.all() where record.alarmId == alarmId {
            try? manager.cancel(id: record.id)
        }
        WakeAlarmStore.removeAll(alarmId: alarmId)
    }

    // MARK: - Reconciliation

    /// Re-arms anything that should still be ringing but is not.
    ///
    /// The stop intent is the primary re-arm trigger, but it is not guaranteed:
    /// AlarmKit retires an unattended alert on its own, the extension process can
    /// be killed mid-perform, and a force-quit during the alert loses the callback.
    /// Running this on every app launch (and after a solve) keeps the chain alive
    /// in those cases instead of silently letting the user sleep in.
    static func reconcile() async {
        let live: Set<UUID>
        do {
            live = Set(try manager.alarms.map(\.id))
        } catch {
            // Without the live list, re-arming everything risks double-firing an
            // alarm that is still scheduled. Leave the chain as it is.
            NSLog("[WakeAlarm] Could not read scheduled alarms; skipping reconcile: \(error)")
            return
        }

        for record in WakeAlarmStore.unsolved() where !live.contains(record.id) {
            // Already fired and dismissed, or lost with the process. Bring it back.
            await rearm(id: record.id)
        }
    }

    /// The unsolved alarm the app should show a quiz for, if any.
    /// Prefers the one that was originally supposed to ring first.
    static func pendingQuiz() -> WakeAlarmRecord? {
        WakeAlarmStore.unsolved().min { $0.originalRingAt < $1.originalRingAt }
    }

    // MARK: - AlarmKit plumbing

    private static func schedule(_ record: WakeAlarmRecord) async throws {
        // AlarmKit rejects a fixed schedule in the past; nudge it just ahead.
        let fireDate = max(record.ringAt, Date().addingTimeInterval(1))

        let solveButton = AlarmButton(
            text: "Solve quiz",
            textColor: .white,
            systemImageName: "brain.head.profile"
        )

        let title: LocalizedStringResource = record.retryCount == 0
            ? "Wake up"
            : "Still awake? Solve the quiz."

        let alert: AlarmPresentation.Alert
        if #available(iOS 26.1, *) {
            // The system owns the stop button from 26.1 on.
            alert = AlarmPresentation.Alert(
                title: title,
                secondaryButton: solveButton,
                secondaryButtonBehavior: .custom
            )
        } else {
            alert = AlarmPresentation.Alert(
                title: title,
                stopButton: AlarmButton(
                    text: "Stop",
                    textColor: .white,
                    systemImageName: "stop.circle"
                ),
                secondaryButton: solveButton,
                secondaryButtonBehavior: .custom
            )
        }

        let attributes = AlarmAttributes(
            presentation: AlarmPresentation(alert: alert),
            metadata: WakeAlarmMetadata(alarmId: record.alarmId, message: record.message),
            tintColor: Color.orange
        )

        let configuration = AlarmManager.AlarmConfiguration(
            schedule: .fixed(fireDate),
            attributes: attributes,
            stopIntent: WakeAlarmStopIntent(alarmID: record.id.uuidString),
            secondaryIntent: WakeAlarmSolveIntent(alarmID: record.id.uuidString),
            sound: .default
        )

        _ = try await manager.schedule(id: record.id, configuration: configuration)
    }
}