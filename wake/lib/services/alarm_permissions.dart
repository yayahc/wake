import 'package:flutter/foundation.dart';

enum AlarmPermission {
  notifications,
  fullScreenIntent,
  drawOverlays,
  exactAlarms;

  String get key => switch (this) {
    AlarmPermission.notifications => 'notifications',
    AlarmPermission.fullScreenIntent => 'fullScreenIntent',
    AlarmPermission.drawOverlays => 'drawOverlays',
    AlarmPermission.exactAlarms => 'exactAlarms',
  };

  String get title => switch (this) {
    AlarmPermission.notifications => 'Notifications',
    AlarmPermission.fullScreenIntent => 'Show over the lock screen',
    AlarmPermission.drawOverlays => 'Display over other apps',
    AlarmPermission.exactAlarms => 'Exact alarms',
  };

  String get rationale => switch (this) {
    AlarmPermission.notifications =>
      'Without this the alarm rings but the quiz never appears.',
    AlarmPermission.fullScreenIntent =>
      'Without this the quiz will not open by itself when the alarm rings.',
    AlarmPermission.drawOverlays =>
      'Without this you can leave the quiz with the home button.',
    AlarmPermission.exactAlarms =>
      'Without this alarms can be delayed by the system.',
  };
}

@immutable
class AlarmPermissions {
  const AlarmPermissions(this._granted);

  final Map<AlarmPermission, bool> _granted;

  static const AlarmPermissions unknown = AlarmPermissions({});

  bool isGranted(AlarmPermission permission) => _granted[permission] ?? true;

  List<AlarmPermission> get missing =>
      AlarmPermission.values.where((p) => !isGranted(p)).toList();

  factory AlarmPermissions.fromMap(Map<Object?, Object?> map) {
    return AlarmPermissions({
      for (final permission in AlarmPermission.values)
        if (map[permission.key] case final bool granted) permission: granted,
    });
  }
}
