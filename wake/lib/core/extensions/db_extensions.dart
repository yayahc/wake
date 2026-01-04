import 'package:wake/core/domain/entities/alarm_entity.dart';
import 'package:wake/db/database.dart';

extension AlarmEntityToAlarmCompanion on AlarmEntity {
  AlarmCompanion get toCompanion =>
      AlarmCompanion.insert(ringAt: ringAt, message: message);
}

extension AlarmDataToAlarmEntity on AlarmData {
  AlarmEntity get toEntity => AlarmEntity(
    id: id,
    message: message,
    createdAt: createdAt,
    ringAt: ringAt,
  );
}
