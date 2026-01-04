import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart';
import 'package:wake/core/domain/entities/alarm_entity.dart';
import 'package:wake/core/errors/app_errors.dart';
import 'package:wake/core/extensions/db_extensions.dart';
import 'package:wake/db/database.dart';

class AlarmUsecases {
  static Future<Either<AppError, int>> setAlarm(AlarmEntity alarm) async {
    try {
      final db = AppDatabase.instance;
      final id = await db.into(db.alarm).insert(alarm.toCompanion);
      return right(id);
    } catch (e, s) {
      return left(
        GenericAppError(
          errorMessage: e.toString(),
          stackTrace: s.toString(),
          userFriendlyErrorMessage: 'error setting alarm try again',
        ),
      );
    }
  }

  static Future<Either<AppError, List<AlarmEntity>>> getAlarms() async {
    try {
      final db = AppDatabase.instance;
      final alarms = await db.alarm.select().get();
      return right(alarms.map((a) => a.toEntity).toList());
    } catch (e, s) {
      return left(
        GenericAppError(
          errorMessage: e.toString(),
          stackTrace: s.toString(),
          userFriendlyErrorMessage: 'error setting alarm try again',
        ),
      );
    }
  }
}
