import 'package:flutter/widgets.dart';
import 'package:wake/db/database.dart';
import 'package:wake/init_locla_notification.dart';
import 'package:wake/services/notification_service.dart';

@pragma('vm:entry-point')
Future<void> ringAlarm(int id) async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeLocalNotification();

  final db = AppDatabase.instance;
  final alarm = await (db.select(
    db.alarm,
  )..where((a) => a.id.equals(id))).getSingleOrNull();

  await sendAlarmNotification(id, alarm?.message ?? 'Wake up');
  await (db.delete(db.alarm)..where((a) => a.id.equals(id))).go();
}
