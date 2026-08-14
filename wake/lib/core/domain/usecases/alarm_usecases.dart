import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart';
import 'package:wake/core/domain/entities/alarm_entity.dart';
import 'package:wake/core/errors/app_errors.dart';
import 'package:wake/core/extensions/db_extensions.dart';
import 'package:wake/db/database.dart';
import 'package:wake/services/alarm_scheduler.dart';

class AlarmUsecases {
  static Future<Either<AppError, int>> setAlarm(AlarmEntity alarm) async {
    try {
      final db = AppDatabase.instance;
      final id = await db.into(db.alarm).insert(alarm.toCompanion);
      final armed = await AlarmScheduler.schedule(
        id,
        alarm.ringAt,
        message: alarm.message,
      );
      if (!armed) {
        await (db.delete(db.alarm)..where((a) => a.id.equals(id))).go();
        return left(
          GenericAppError(
            errorMessage: 'platform refused to arm alarm $id',
            stackTrace: StackTrace.current.toString(),
            userFriendlyErrorMessage:
                'could not set the alarm, check alarm permissions',
          ),
        );
      }
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
      final alarms =
          await (db.select(db.alarm)
                ..orderBy([(a) => OrderingTerm.asc(a.ringAt)]))
              .get();
      return right(alarms.map((a) => a.toEntity).toList());
    } catch (e, s) {
      return left(
        GenericAppError(
          errorMessage: e.toString(),
          stackTrace: s.toString(),
          userFriendlyErrorMessage: 'error loading alarms try again',
        ),
      );
    }
  }

  static Future<Either<AppError, Unit>> resolveQuiz(int id) async {
    try {
      final db = AppDatabase.instance;
      await AlarmScheduler.markQuizSolved(id);
      await AlarmScheduler.cancel(id);
      await (db.delete(db.alarm)..where((a) => a.id.equals(id))).go();
      return right(unit);
    } catch (e, s) {
      return left(
        GenericAppError(
          errorMessage: e.toString(),
          stackTrace: s.toString(),
          userFriendlyErrorMessage: 'error stopping alarm try again',
        ),
      );
    }
  }

  static Future<Either<AppError, Unit>> deleteAlarm(int id) async {
    try {
      final db = AppDatabase.instance;
      await AlarmScheduler.markQuizSolved(id);
      await AlarmScheduler.cancel(id);
      await (db.delete(db.alarm)..where((a) => a.id.equals(id))).go();
      return right(unit);
    } catch (e, s) {
      return left(
        GenericAppError(
          errorMessage: e.toString(),
          stackTrace: s.toString(),
          userFriendlyErrorMessage: 'error deleting alarm try again',
        ),
      );
    }
  }
}