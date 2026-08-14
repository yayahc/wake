import 'dart:io';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:wake/root.dart';
import 'package:wake/services/ios_alarm_bridge.dart';
import 'init_locla_notification.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb && Platform.isAndroid) {
    await AndroidAlarmManager.initialize();
  }
  await initializeLocalNotification();
  await IosAlarmBridge.reconcile();

  runApp(const Wake());
}
