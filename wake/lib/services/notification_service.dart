import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import '../init_locla_notification.dart';

const _alarmChannelId = 'wake_alarm_channel';

Future<void> sendNofitication(String title, String body) async {
  await requestNotificationPermission();
  final plugin = flutterLocalNotificationsPlugin;
  const AndroidNotificationDetails androidNotificationDetails =
      AndroidNotificationDetails(
        "0",
        'IPChannelName',
        channelDescription: 'IPChannelName',
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'ticker',
      );
  const NotificationDetails notificationDetails = NotificationDetails(
    android: androidNotificationDetails,
  );
  await plugin.show(
    id: 0,
    title: title,
    body: body,
    notificationDetails: notificationDetails,
  );
}

Future<void> sendAlarmNotification(int id, String message) async {
  final plugin = flutterLocalNotificationsPlugin;
  const AndroidNotificationDetails androidNotificationDetails =
      AndroidNotificationDetails(
        _alarmChannelId,
        'Alarms',
        channelDescription: 'Scheduled wake alarms',
        importance: Importance.max,
        priority: Priority.max,
        category: AndroidNotificationCategory.alarm,
        fullScreenIntent: true,
        playSound: true,
        enableVibration: true,
        ongoing: true,
        autoCancel: false,
      );
  const NotificationDetails notificationDetails = NotificationDetails(
    android: androidNotificationDetails,
  );
  await plugin.show(
    id: id,
    title: 'Wake up',
    body: message,
    notificationDetails: notificationDetails,
  );
}

Future<void> requestNotificationPermission() async {
  final status = await Permission.notification.isDenied;
  if (status) {
    Permission.notification.request();
  }
}
