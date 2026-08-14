import 'dart:io';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:wake/services/alarm_service.dart';
import 'package:wake/services/ios_alarm_bridge.dart';

class AlarmScheduler {
  static bool get _isAndroid => !kIsWeb && Platform.isAndroid;

  static Future<bool> schedule(
    int id,
    DateTime ringAt, {
    required String message,
  }) async {
    if (IosAlarmBridge.isSupported) {
      final armed = await IosAlarmBridge.schedule(
        alarmId: id,
        message: message,
        ringAt: ringAt,
      );
      return armed != null;
    }
    if (!_isAndroid) return false;

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

  static Future<bool> cancel(int id) async {
    if (IosAlarmBridge.isSupported) {
      await IosAlarmBridge.cancel(id);
      return true;
    }
    if (!_isAndroid) return false;

    return AndroidAlarmManager.cancel(id);
  }
}