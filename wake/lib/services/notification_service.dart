import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import '../init_locla_notification.dart';

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

Future<void> requestNotificationPermission() async {
  final status = await Permission.notification.isDenied;
  if (status) {
    Permission.notification.request();
  }
}
