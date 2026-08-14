import 'dart:io';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/material.dart';
import 'package:wake/root.dart';
import 'init_locla_notification.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isAndroid) {
    await AndroidAlarmManager.initialize();
  }
  await initializeLocalNotification();
  runApp(const Wake());
}
