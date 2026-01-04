import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wake/core/domain/entities/alarm_entity.dart';
import 'package:wake/core/domain/usecases/alarm_usecases.dart';
import 'package:wake/features/alarm/state/cubit/alarm_state.dart';

class AlarmCubit extends Cubit<AlarmState> {
  static late final AlarmCubit _instance;
  static AlarmCubit get instance => _instance;
  AlarmCubit() : super(InitStateAlarmState()) {
    _instance = AlarmCubit();
  }

  List<AlarmEntity> alarms = [];

  void setAlarm(AlarmEntity alarm) async {
    emit(SettingAlarmState());
    final result = await AlarmUsecases.setAlarm(alarm);
    result.fold(
      (error) => emit(FailedToSetAlarmState(error: error)),
      (_) => emit(AlarmSuccesfulySetState()),
    );
  }

  void getAlarms() async {
    emit(LoadingAlarmsState());
    final result = await AlarmUsecases.getAlarms();
    result.fold((error) => emit(FailedToLoadAlarmsState(error: error)), (as) {
      emit(AlarmsLoadedState());
      alarms = as;
    });
  }
}
