import 'dart:async';

import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:wake/services/alarm_permissions.dart';
import 'package:wake/services/android_alarm_bridge.dart';
import 'package:wake/services/ios_alarm_bridge.dart';
import 'package:wake/services/pending_quiz.dart';

class AlarmScheduler {
  AlarmScheduler._();

  static bool get isSupported =>
      AndroidAlarmBridge.isSupported || IosAlarmBridge.isSupported;

  static Stream<String> get ringing => AndroidAlarmBridge.isSupported
      ? AndroidAlarmBridge.ringing
      : const Stream<String>.empty();

  static Future<AlarmPermissions> permissionStatus() {
    if (AndroidAlarmBridge.isSupported) {
      return AndroidAlarmBridge.permissionStatus();
    }
    return Future.value(AlarmPermissions.unknown);
  }

  static Future<void> requestPermission(AlarmPermission permission) async {
    if (!AndroidAlarmBridge.isSupported) return;

    if (permission == AlarmPermission.notifications) {
      final status = await ph.Permission.notification.request();
      if (status.isPermanentlyDenied) await ph.openAppSettings();
      return;
    }

    await AndroidAlarmBridge.requestPermission(permission);
  }

  static Future<bool> needsOemSetup() {
    if (AndroidAlarmBridge.isSupported) return AndroidAlarmBridge.needsOemSetup();
    return Future.value(false);
  }

  static Future<void> openOemSettings() {
    if (AndroidAlarmBridge.isSupported) {
      return AndroidAlarmBridge.openOemSettings();
    }
    return Future.value();
  }

  static Future<void> ensureNotificationPermission() async {
    if (!AndroidAlarmBridge.isSupported) return;
    final permissions = await permissionStatus();
    if (permissions.isGranted(AlarmPermission.notifications)) return;
    await ph.Permission.notification.request();
  }

  static Future<bool> requestAuthorization() {
    if (AndroidAlarmBridge.isSupported) {
      return AndroidAlarmBridge.requestAuthorization();
    }
    if (IosAlarmBridge.isSupported) return IosAlarmBridge.requestAuthorization();
    return Future.value(false);
  }

  static Future<bool> schedule(
    int id,
    DateTime ringAt, {
    required String message,
  }) async {
    if (AndroidAlarmBridge.isSupported) {
      final armed = await AndroidAlarmBridge.schedule(
        alarmId: id,
        message: message,
        ringAt: ringAt,
      );
      return armed != null;
    }
    if (IosAlarmBridge.isSupported) {
      final armed = await IosAlarmBridge.schedule(
        alarmId: id,
        message: message,
        ringAt: ringAt,
      );
      return armed != null;
    }
    return false;
  }

  static Future<bool> cancel(int id) async {
    if (AndroidAlarmBridge.isSupported) {
      await AndroidAlarmBridge.cancel(id);
      return true;
    }
    if (IosAlarmBridge.isSupported) {
      await IosAlarmBridge.cancel(id);
      return true;
    }
    return false;
  }

  static Future<PendingQuiz?> pendingQuiz() {
    if (AndroidAlarmBridge.isSupported) return AndroidAlarmBridge.pendingQuiz();
    if (IosAlarmBridge.isSupported) return IosAlarmBridge.pendingQuiz();
    return Future.value(null);
  }

  static Future<void> markQuizSolved(String id) {
    if (AndroidAlarmBridge.isSupported) {
      return AndroidAlarmBridge.markQuizSolved(id);
    }
    if (IosAlarmBridge.isSupported) return IosAlarmBridge.markQuizSolved(id);
    return Future.value();
  }

  static Future<void> reconcile() {
    if (AndroidAlarmBridge.isSupported) return AndroidAlarmBridge.reconcile();
    if (IosAlarmBridge.isSupported) return IosAlarmBridge.reconcile();
    return Future.value();
  }
}