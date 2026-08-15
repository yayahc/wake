package dev.wake.app

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject
import java.util.UUID

/**
 * One armed alarm and the state of its skip gate.
 *
 * Mirrors `WakeAlarmRecord` on iOS so both platforms hand Flutter the same
 * shape. [id] is the identity the quiz answers against; [alarmId] is the Drift
 * row it came from.
 */
data class WakeAlarmRecord(
    val id: String = UUID.randomUUID().toString(),
    val alarmId: Int,
    val message: String,
    val ringAt: Long,
    val originalRingAt: Long = ringAt,
    val retryCount: Int = 0,
    /**
     * Set the moment the alarm actually rings.
     *
     * A quiz is only owed once this is true. Without it, merely arming an
     * alarm would count as owing an answer, and opening the app would trap
     * the user in a quiz whose solution cancels the alarm they just set.
     */
    val fired: Boolean = false,
    val solved: Boolean = false,
) {
    fun toJson(): JSONObject = JSONObject().apply {
        put("id", id)
        put("alarmId", alarmId)
        put("message", message)
        put("ringAt", ringAt)
        put("originalRingAt", originalRingAt)
        put("retryCount", retryCount)
        put("fired", fired)
        put("solved", solved)
    }

    /** Payload handed to Flutter. Keys match the iOS bridge exactly. */
    fun toChannelMap(): Map<String, Any> = mapOf(
        "id" to id,
        "alarmId" to alarmId,
        "message" to message,
        "ringAtMillis" to ringAt,
        "retryCount" to retryCount,
    )

    companion object {
        fun fromJson(json: JSONObject) = WakeAlarmRecord(
            id = json.getString("id"),
            alarmId = json.getInt("alarmId"),
            message = json.getString("message"),
            ringAt = json.getLong("ringAt"),
            originalRingAt = json.optLong("originalRingAt", json.getLong("ringAt")),
            retryCount = json.optInt("retryCount", 0),
            fired = json.optBoolean("fired", false),
            solved = json.optBoolean("solved", false),
        )
    }
}

/**
 * Persistent home for the gate state.
 *
 * Deliberately not Drift: the receiver and the ring service run without a
 * Flutter engine, so they cannot reach the Dart database. SharedPreferences is
 * readable from every process that matters here.
 */
object WakeAlarmStore {
    private const val PREFS = "wake_alarm_store"
    private const val KEY_RECORDS = "records"

    private fun prefs(context: Context) =
        context.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    @Synchronized
    fun all(context: Context): List<WakeAlarmRecord> {
        val raw = prefs(context).getString(KEY_RECORDS, null) ?: return emptyList()
        return runCatching {
            val array = JSONArray(raw)
            (0 until array.length()).map { WakeAlarmRecord.fromJson(array.getJSONObject(it)) }
        }.getOrDefault(emptyList())
    }

    @Synchronized
    private fun write(context: Context, records: List<WakeAlarmRecord>) {
        val array = JSONArray().apply { records.forEach { put(it.toJson()) } }
        prefs(context).edit().putString(KEY_RECORDS, array.toString()).apply()
    }

    fun unsolved(context: Context): List<WakeAlarmRecord> = all(context).filter { !it.solved }

    fun record(context: Context, id: String): WakeAlarmRecord? = all(context).firstOrNull { it.id == id }

    @Synchronized
    fun upsert(context: Context, record: WakeAlarmRecord) {
        write(context, all(context).filterNot { it.id == record.id } + record)
    }

    @Synchronized
    fun remove(context: Context, id: String) {
        write(context, all(context).filterNot { it.id == id })
    }

    @Synchronized
    fun removeAll(context: Context, alarmId: Int) {
        write(context, all(context).filterNot { it.alarmId == alarmId })
    }

    @Synchronized
    fun mutate(
        context: Context,
        id: String,
        transform: (WakeAlarmRecord) -> WakeAlarmRecord,
    ): WakeAlarmRecord? {
        val current = record(context, id) ?: return null
        val updated = transform(current)
        upsert(context, updated)
        return updated
    }

    /**
     * The alarm the app should show a quiz for: one that has actually rung and
     * has not been answered. Prefers the one originally due first, so a
     * backlog is cleared oldest-first.
     *
     * Alarms still waiting to ring are excluded on purpose. They are unsolved,
     * but nothing is owed until they wake someone.
     */
    fun pendingQuiz(context: Context): WakeAlarmRecord? =
        unsolved(context).filter { it.fired }.minByOrNull { it.originalRingAt }
}
