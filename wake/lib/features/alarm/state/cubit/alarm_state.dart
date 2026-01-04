import 'package:equatable/equatable.dart';
import 'package:wake/core/errors/app_errors.dart';

sealed class AlarmState extends Equatable {}

class InitStateAlarmState extends AlarmState {
  @override
  List<Object?> get props => [];
}

class LoadingAlarmsState extends AlarmState {
  @override
  List<Object?> get props => [];
}

class FailedToLoadAlarmsState extends AlarmState {
  final AppError error;

  FailedToLoadAlarmsState({required this.error});
  @override
  List<Object?> get props => [error];
}

class AlarmsLoadedState extends AlarmState {
  @override
  List<Object?> get props => [];
}

class SettingAlarmState extends AlarmState {
  @override
  List<Object?> get props => [];
}

class AlarmSuccesfulySetState extends AlarmState {
  @override
  List<Object?> get props => [];
}

class FailedToSetAlarmState extends AlarmState {
  final AppError error;

  FailedToSetAlarmState({required this.error});

  @override
  List<Object?> get props => [error];
}
