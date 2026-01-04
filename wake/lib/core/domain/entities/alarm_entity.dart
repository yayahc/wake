class AlarmEntity {
  final int? id;
  final String message;
  final DateTime? createdAt;
  final DateTime ringAt;

  AlarmEntity({
    this.id,
    required this.message,
    this.createdAt,
    required this.ringAt,
  });
}
