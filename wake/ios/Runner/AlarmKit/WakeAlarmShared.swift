import AlarmKit
import Foundation

/// Identifiers shared by the app and the widget extension.
///
/// `appGroup` must match the App Groups capability enabled on *both* the Runner
/// and WakeAlarmWidget targets. If it does not, `WakeAlarmStore` falls back to a
/// no-op and every alarm reads back as already solved, which silently disables
/// the re-arm loop.
enum WakeAlarmIdentity {
    static let appGroup = "group.dev.yayahc.wake"
    static let methodChannel = "dev.yayahc.wake/alarm"
}

/// Metadata carried on the AlarmKit alert itself.
///
/// AlarmKit encodes this into the Live Activity attributes, so it is readable
/// from the widget extension without touching the App Group.
struct WakeAlarmMetadata: AlarmMetadata {
    /// Drift row id of the alarm this alert belongs to.
    let alarmId: Int
    /// User-supplied wake message.
    let message: String

    init(alarmId: Int, message: String) {
        self.alarmId = alarmId
        self.message = message
    }
}

/// One armed alarm as the re-arm loop sees it.
///
/// `id` is the AlarmKit alarm id and stays stable across re-arms, so a chain of
/// retries is one record rather than a growing pile.
struct WakeAlarmRecord: Codable, Hashable {
    let id: UUID
    let alarmId: Int
    let message: String
    /// When the alarm was originally meant to fire. Retries do not move this.
    let originalRingAt: Date
    /// When the currently armed alert fires.
    var ringAt: Date
    /// Set only by `WakeAlarmController.markQuizSolved`. The one exit from the loop.
    var solved: Bool
    /// How many times the alert has been dismissed without solving the quiz.
    var retryCount: Int

    init(
        id: UUID = UUID(),
        alarmId: Int,
        message: String,
        ringAt: Date,
        solved: Bool = false,
        retryCount: Int = 0
    ) {
        self.id = id
        self.alarmId = alarmId
        self.message = message
        self.originalRingAt = ringAt
        self.ringAt = ringAt
        self.solved = solved
        self.retryCount = retryCount
    }
}

/// App Group backed store for the re-arm loop's state.
///
/// This deliberately does not live in Drift: the intent that runs on dismissal
/// may be performed by the widget extension process while the Flutter app is not
/// running, and that process cannot open the app's Drift database.
struct WakeAlarmStore {
    private static let recordsKey = "wake.alarm.records"

    private static var defaults: UserDefaults? {
        guard let suite = UserDefaults(suiteName: WakeAlarmIdentity.appGroup) else {
            NSLog("[WakeAlarm] App Group \(WakeAlarmIdentity.appGroup) is not configured. "
                + "Enable the App Groups capability on both Runner and WakeAlarmWidget.")
            return nil
        }
        return suite
    }

    // MARK: - Reading

    static func all() -> [WakeAlarmRecord] {
        guard let data = defaults?.data(forKey: recordsKey) else { return [] }
        do {
            return try JSONDecoder().decode([WakeAlarmRecord].self, from: data)
        } catch {
            NSLog("[WakeAlarm] Could not decode stored records: \(error)")
            return []
        }
    }

    static func record(id: UUID) -> WakeAlarmRecord? {
        all().first { $0.id == id }
    }

    static func record(alarmId: Int) -> WakeAlarmRecord? {
        all().first { $0.alarmId == alarmId }
    }

    /// Every alarm that has fired at least once and still has an unsolved quiz.
    static func unsolved() -> [WakeAlarmRecord] {
        all().filter { !$0.solved }
    }

    // MARK: - Writing

    static func upsert(_ record: WakeAlarmRecord) {
        var records = all()
        if let index = records.firstIndex(where: { $0.id == record.id }) {
            records[index] = record
        } else {
            records.append(record)
        }
        persist(records)
    }

    static func remove(id: UUID) {
        persist(all().filter { $0.id != id })
    }

    static func removeAll(alarmId: Int) {
        persist(all().filter { $0.alarmId != alarmId })
    }

    /// Applies `mutation` to the stored record and writes it back.
    /// Returns the mutated record, or nil if no such record exists.
    @discardableResult
    static func mutate(id: UUID, _ mutation: (inout WakeAlarmRecord) -> Void) -> WakeAlarmRecord? {
        var records = all()
        guard let index = records.firstIndex(where: { $0.id == id }) else {
            NSLog("[WakeAlarm] No stored record for \(id.uuidString); nothing to mutate.")
            return nil
        }
        mutation(&records[index])
        persist(records)
        return records[index]
    }

    private static func persist(_ records: [WakeAlarmRecord]) {
        guard let defaults else { return }
        do {
            defaults.set(try JSONEncoder().encode(records), forKey: recordsKey)
        } catch {
            NSLog("[WakeAlarm] Could not encode records: \(error)")
        }
    }
}
