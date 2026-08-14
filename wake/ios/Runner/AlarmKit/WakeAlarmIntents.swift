import AlarmKit
import AppIntents
import Foundation

/// Runs when the alert's Stop button is tapped.
///
/// AlarmKit has already stopped the alert by the time this performs; the only
/// thing left to do is put it back. This may be performed by the widget
/// extension process while the Flutter app is not running, which is why the loop
/// state lives in the App Group rather than in Drift.
@available(iOS 26.0, *)
struct WakeAlarmStopIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Stop alarm"
    static var description = IntentDescription("Stops the current alert and re-arms it until the quiz is solved.")
    static var isDiscoverable: Bool = false

    @Parameter(title: "Alarm ID")
    var alarmID: String

    init() {}

    init(alarmID: String) {
        self.alarmID = alarmID
    }

    func perform() async throws -> some IntentResult {
        guard let id = UUID(uuidString: alarmID) else { return .result() }
        await WakeAlarmController.rearm(id: id)
        return .result()
    }
}

/// Runs when the alert's "Solve quiz" button is tapped.
///
/// Opens the app so the quiz gate can take over. It still re-arms: tapping
/// "Solve quiz" and then force-quitting must not end the chain — only actually
/// answering, via `WakeAlarmController.markQuizSolved`, does that.
@available(iOS 26.0, *)
struct WakeAlarmSolveIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Solve wake quiz"
    static var description = IntentDescription("Opens Wake so the quiz can be answered.")
    static var openAppWhenRun: Bool = true
    static var isDiscoverable: Bool = false

    @Parameter(title: "Alarm ID")
    var alarmID: String

    init() {}

    init(alarmID: String) {
        self.alarmID = alarmID
    }

    func perform() async throws -> some IntentResult {
        guard let id = UUID(uuidString: alarmID) else { return .result() }
        await WakeAlarmController.rearm(id: id)
        return .result()
    }
}
