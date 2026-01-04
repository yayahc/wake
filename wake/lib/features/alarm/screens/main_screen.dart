import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wake/core/extensions/context_extension.dart';
import 'package:wake/features/alarm/state/cubit/alarm_state.dart';
import 'package:wake/features/alarm/widgets/set_alarm_sheet.dart';

import '../state/cubit/alarm_cubit.dart';

class AlarmMainScreen extends StatelessWidget {
  const AlarmMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: Text('Alarms')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            InkWell(
              onTap: () => _setNewAlarm(context),
              child: Text('set new alarm'),
            ),
            SizedBox(height: 20),

            BlocBuilder<AlarmCubit, AlarmState>(
              builder: (context, state) {
                _handleAlarmState(context, state);
                return Expanded(
                  child: AlarmCubit.instance.alarms.isEmpty
                      ? Center(child: Text('Empty'))
                      : ListView.builder(
                          itemCount: AlarmCubit.instance.alarms.length,
                          itemBuilder: (context, index) => Text(
                            AlarmCubit.instance.alarms[index].ringAt
                                .toIso8601String(),
                          ),
                        ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _setNewAlarm(BuildContext context) {
    context.showDefaultButtonSheet(SetAlarmSheet());
  }

  void _handleAlarmState(BuildContext context, AlarmState state) {
    switch (state) {
      case InitStateAlarmState():
      case LoadingAlarmsState():
      case FailedToLoadAlarmsState():
        context.showSnackBar(
          (state as FailedToLoadAlarmsState).error.userFriendlyErrorMessage,
        );
      case AlarmsLoadedState():
      case SettingAlarmState():
      case AlarmSuccesfulySetState():
      case FailedToSetAlarmState():
        context.showSnackBar(
          (state as FailedToSetAlarmState).error.userFriendlyErrorMessage,
        );
    }
  }
}
