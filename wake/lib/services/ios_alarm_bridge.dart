import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

@immutable
class PendingQuiz {
  const PendingQuiz({
    required this.id,
    required this.alarmId,
    required this.message,
    required this.ringAt,
    required this.retryCount,
  });

  final String id;

  final int alarmId;
  final String message;
  final DateTime ringAt;

  final int retryCount;

  factory PendingQuiz.fromMap(Map<Object?, Object?> map) => PendingQuiz(
    id: map['id']! as String,
    alarmId: map['alarmId']! as int,
    message: map['message']! as String,
    ringAt: DateTime.fromMillisecondsSinceEpoch(map['ringAtMillis']! as int),
    retryCount: map['retryCount']! as int,
  );
}

class IosAlarmBridge {
  IosAlarmBridge._();

  static const _channel = MethodChannel('dev.yayahc.wake/alarm');

  static bool get isSupported => !kIsWeb && Platform.isIOS;

  static Future<bool> requestAuthorization() async {
    if (!isSupported) return false;
    return await _invoke<bool>('requestAuthorization') ?? false;
  }

  static Future<String?> schedule({
    required int alarmId,
    required String message,
    required DateTime ringAt,
  }) async {
    if (!isSupported) return null;
    if (!await requestAuthorization()) {
      debugPrint('[wake] AlarmKit authorization denied; alarm not armed.');
      return null;
    }
    return _invoke<String>('schedule', {
      'alarmId': alarmId,
      'message': message,
      'ringAtMillis': ringAt.millisecondsSinceEpoch,
    });
  }

  static Future<void> cancel(int alarmId) async {
    if (!isSupported) return;
    await _invoke<void>('cancel', {'alarmId': alarmId});
  }

  static Future<PendingQuiz?> pendingQuiz() async {
    if (!isSupported) return null;
    final result = await _invoke<Map<Object?, Object?>>('pendingQuiz');
    return result == null ? null : PendingQuiz.fromMap(result);
  }

  static Future<void> markQuizSolved(String id) async {
    if (!isSupported) return;
    await _invoke<void>('markQuizSolved', {'id': id});
  }

  static Future<void> reconcile() async {
    if (!isSupported) return;
    await _invoke<void>('reconcile');
  }

  static Future<T?> _invoke<T>(
    String method, [
    Map<String, Object?>? args,
  ]) async {
    try {
      return await _channel.invokeMethod<T>(method, args);
    } on MissingPluginException {
      debugPrint('[wake] WakeAlarmPlugin is not registered.');
      return null;
    } on PlatformException catch (e) {
      debugPrint('[wake] $method failed: ${e.code} ${e.message}');
      return null;
    }
  }
}
