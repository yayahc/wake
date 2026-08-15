package dev.wake.app

import android.content.Context
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Method channel bridge between Flutter and the alarm machinery.
 *
 * Method names and payload keys deliberately match the iOS plugin so
 * `AlarmScheduler` can talk to both through one interface.
 */
class WakeAlarmPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {

    companion object {
        /**
         * Shared with iOS, so it tracks the developer namespace rather than
         * the Android applicationId. Changing it here alone would desync the
         * two platforms from the single Dart facade.
         */
        private const val CHANNEL = "dev.yayahc.wake/alarm"

        @Volatile
        private var channel: MethodChannel? = null

        /**
         * Tells Flutter an alarm just started ringing.
         *
         * Needed only for the case where the app is already in the foreground:
         * every other path reaches the quiz through a resume, which the Dart
         * side polls on its own.
         */
        fun notifyRinging(recordId: String) {
            val target = channel ?: return
            Handler(Looper.getMainLooper()).post {
                target.invokeMethod("onAlarmRinging", recordId)
            }
        }
    }

    private lateinit var context: Context

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, CHANNEL).also {
            it.setMethodCallHandler(this)
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel?.setMethodCallHandler(null)
        channel = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "requestAuthorization" -> result.success(WakeAlarmScheduler.canScheduleExact(context))

            "permissionStatus" -> result.success(WakeAlarmPermissions.status(context))

            "needsOemSetup" -> result.success(WakeAlarmPermissions.needsOemSetup())

            "openOemSettings" -> {
                WakeAlarmPermissions.openOemSettings(context)
                result.success(null)
            }

            "requestPermission" -> {
                when (call.argument<String>("permission")) {
                    "fullScreenIntent" -> WakeAlarmPermissions.requestFullScreenIntent(context)
                    "drawOverlays" -> WakeAlarmPermissions.requestDrawOverlays(context)
                    "exactAlarms" -> WakeAlarmPermissions.requestExactAlarms(context)
                    else -> {
                        result.error("bad_arguments", "Unknown permission.", null)
                        return
                    }
                }
                result.success(null)
            }

            "schedule" -> {
                val alarmId = call.argument<Int>("alarmId")
                val message = call.argument<String>("message")
                val ringAtMillis = call.argument<Number>("ringAtMillis")?.toLong()
                if (alarmId == null || message == null || ringAtMillis == null) {
                    result.error("bad_arguments", "Missing arguments for schedule.", null)
                    return
                }
                if (!WakeAlarmScheduler.canScheduleExact(context)) {
                    result.error(
                        "exact_alarms_denied",
                        "Exact alarms are not permitted for this app.",
                        null,
                    )
                    return
                }
                val record = WakeAlarmScheduler.arm(context, alarmId, message, ringAtMillis)
                result.success(record.id)
            }

            "cancel" -> {
                val alarmId = call.argument<Int>("alarmId")
                if (alarmId == null) {
                    result.error("bad_arguments", "Missing alarmId for cancel.", null)
                    return
                }
                // Cancelling an alarm that is ringing right now must also stop
                // the sound, otherwise deleting it from the list leaves the
                // service running with nothing behind it.
                WakeAlarmStore.all(context)
                    .filter { it.alarmId == alarmId && it.id == WakeAlarmService.ringingRecordId }
                    .forEach { WakeAlarmService.stopSolved(context, it.id) }
                WakeAlarmScheduler.cancelAll(context, alarmId)
                result.success(null)
            }

            "pendingQuiz" -> result.success(WakeAlarmStore.pendingQuiz(context)?.toChannelMap())

            "markQuizSolved" -> {
                val id = call.argument<String>("id")
                if (id == null) {
                    result.error("bad_arguments", "Missing id for markQuizSolved.", null)
                    return
                }
                if (WakeAlarmService.ringingRecordId == id) {
                    WakeAlarmService.stopSolved(context, id)
                }
                WakeAlarmScheduler.markQuizSolved(context, id)
                result.success(null)
            }

            "reconcile" -> {
                WakeAlarmScheduler.reconcile(context)
                result.success(null)
            }

            else -> result.notImplemented()
        }
    }
}
