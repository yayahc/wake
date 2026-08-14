import 'package:flutter/material.dart';
import 'package:wake/root.dart';
import 'package:wake/services/alarm_scheduler.dart';
import 'init_locla_notification.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeLocalNotification();
  await AlarmScheduler.reconcile();
  await AlarmScheduler.ensureNotificationPermission();

  runApp(const Wake());
}