import 'package:flutter/foundation.dart';


@immutable
class PendingQuiz {
  const PendingQuiz({
    required this.id,
    required this.alarmId,
    required this.message,
    required this.ringAt,
    required this.retryCount,
  });

  final String id;

  final int alarmId;
  final String message;
  final DateTime ringAt;

  final int retryCount;

  factory PendingQuiz.fromMap(Map<Object?, Object?> map) => PendingQuiz(
    id: map['id']! as String,
    alarmId: map['alarmId']! as int,
    message: map['message']! as String,
    ringAt: DateTime.fromMillisecondsSinceEpoch(
      (map['ringAtMillis']! as num).toInt(),
    ),
    retryCount: (map['retryCount']! as num).toInt(),
  );
}
