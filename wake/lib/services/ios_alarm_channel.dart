import 'dart:async';

import 'package:flutter/services.dart';


class IosAlarmChannel {
  const IosAlarmChannel._();

  static const MethodChannel _channel = MethodChannel(
    'dev.yayahc.wake/alarmkit',
  );

  static final StreamController<int> _quizRequests =
      StreamController<int>.broadcast();

  static bool _handlerAttached = false;


  static Stream<int> get quizRequests {
    _attachHandler();
    return _quizRequests.stream;
  }

  static void _attachHandler() {
    if (_handlerAttached) return;
    _handlerAttached = true;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onQuizRequested') {
        final id = call.arguments as int?;
        if (id != null) _quizRequests.add(id);
      }
      return null;
    });
  }


  static Future<bool> requestAuthorization() async {
    final granted = await _channel.invokeMethod<bool>('requestAuthorization');
    return granted ?? false;
  }

  static Future<bool> schedule(int id, DateTime ringAt, String message) async {
    _attachHandler();
    final scheduled = await _channel.invokeMethod<bool>('schedule', {
      'id': id,
      'ringAtEpochMs': ringAt.millisecondsSinceEpoch,
      'message': message,
    });
    return scheduled ?? false;
  }

  static Future<bool> cancel(int id) async {
    final cancelled = await _channel.invokeMethod<bool>('cancel', {'id': id});
    return cancelled ?? false;
  }

  static Future<void> markQuizSolved(int id) {
    return _channel.invokeMethod<void>('markQuizSolved', {'id': id});
  }

  static Future<int?> pendingQuizAlarmId() {
    _attachHandler();
    return _channel.invokeMethod<int>('pendingQuizAlarmId');
  }
}
