import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wake/core/domain/entities/alarm_entity.dart';
import 'package:wake/core/domain/usecases/alarm_usecases.dart';
import 'package:wake/features/alarm/cubit/alarm_state.dart';

class AlarmCubit extends Cubit<AlarmState> {
  AlarmCubit() : super(InitStateAlarmState());

  List<AlarmEntity> alarms = [];

  void getAlarms() async {
    emit(LoadingAlarmsState());
    final result = await AlarmUsecases.getAlarms();
    result.fold((error) => emit(FailedToLoadAlarmsState(error: error)), (
      loaded,
    ) {
      alarms = loaded;
      emit(AlarmsLoadedState());
    });
  }

  void setAlarm(AlarmEntity alarm) async {
    emit(SettingAlarmState());
    final result = await AlarmUsecases.setAlarm(alarm);
    result.fold((error) => emit(FailedToSetAlarmState(error: error)), (_) {
      emit(AlarmSuccesfulySetState());
      getAlarms();
    });
  }

  void deleteAlarm(int id) async {
    final result = await AlarmUsecases.deleteAlarm(id);
    result.fold((error) => emit(FailedToDeleteAlarmState(error: error)), (_) {
      emit(AlarmDeletedState());
      getAlarms();
    });
  }
}
