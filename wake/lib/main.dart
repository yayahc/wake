import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/material.dart';
import 'package:wake/root.dart';
import 'init_locla_notification.dart';
import 'services/alarm_service.dart';

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  await AndroidAlarmManager.initialize();
  initializeLocalNotification();
  runApp(const Wake());
  final int helloAlarmID = 0;
  await AndroidAlarmManager.periodic(
    const Duration(minutes: 1),
    helloAlarmID,
    printHello,
  );
}
