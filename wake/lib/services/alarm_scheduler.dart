import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:wake/services/alarm_service.dart';

class AlarmScheduler {
  static Future<bool> schedule(int id, DateTime ringAt) {
    return AndroidAlarmManager.oneShotAt(
      ringAt,
      id,
      ringAlarm,
      exact: true,
      wakeup: true,
      alarmClock: true,
      allowWhileIdle: true,
      rescheduleOnReboot: true,
    );
  }

  static Future<bool> cancel(int id) {
    return AndroidAlarmManager.cancel(id);
  }
}
