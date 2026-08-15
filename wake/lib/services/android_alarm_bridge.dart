import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:wake/services/alarm_permissions.dart';
import 'package:wake/services/pending_quiz.dart';

class AndroidAlarmBridge {
  AndroidAlarmBridge._();

  static const _channel = MethodChannel('dev.yayahc.wake/alarm');

  static bool get isSupported => !kIsWeb && Platform.isAndroid;

  static final StreamController<String> _ringing =
      StreamController<String>.broadcast();

  static bool _listening = false;

  static Stream<String> get ringing {
    _listen();
    return _ringing.stream;
  }

  static void _listen() {
    if (_listening || !isSupported) return;
    _listening = true;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onAlarmRinging') {
        final id = call.arguments as String?;
        if (id != null) _ringing.add(id);
      }
      return null;
    });
  }

  static Future<bool> requestAuthorization() async {
    if (!isSupported) return false;
    return await _invoke<bool>('requestAuthorization') ?? false;
  }

  static Future<AlarmPermissions> permissionStatus() async {
    if (!isSupported) return AlarmPermissions.unknown;
    final result = await _invoke<Map<Object?, Object?>>('permissionStatus');
    return result == null
        ? AlarmPermissions.unknown
        : AlarmPermissions.fromMap(result);
  }

  static Future<void> requestPermission(AlarmPermission permission) async {
    if (!isSupported) return;
    await _invoke<void>('requestPermission', {'permission': permission.key});
  }

  static Future<bool> needsOemSetup() async {
    if (!isSupported) return false;
    return await _invoke<bool>('needsOemSetup') ?? false;
  }

  static Future<void> openOemSettings() async {
    if (!isSupported) return;
    await _invoke<void>('openOemSettings');
  }

  static Future<String?> schedule({
    required int alarmId,
    required String message,
    required DateTime ringAt,
  }) async {
    if (!isSupported) return null;
    _listen();
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
