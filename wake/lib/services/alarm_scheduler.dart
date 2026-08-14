import 'dart:io';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:wake/services/alarm_service.dart';
import 'package:wake/services/ios_alarm_channel.dart';


class AlarmScheduler {
  static Future<bool> schedule(int id, DateTime ringAt, String message) {
    if (Platform.isIOS) {
      return IosAlarmChannel.schedule(id, ringAt, message);
    }
    if (Platform.isAndroid) {
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
    return Future.value(false);
  }

  static Future<bool> cancel(int id) {
    if (Platform.isIOS) {
      return IosAlarmChannel.cancel(id);
    }
    if (Platform.isAndroid) {
      return AndroidAlarmManager.cancel(id);
    }
    return Future.value(false);
  }


  static Future<bool> requestPermission() {
    if (Platform.isIOS) {
      return IosAlarmChannel.requestAuthorization();
    }
    return Future.value(true);
  }


  static Future<void> markQuizSolved(int id) {
    if (Platform.isIOS) {
      return IosAlarmChannel.markQuizSolved(id);
    }
    return Future.value();
  }
}