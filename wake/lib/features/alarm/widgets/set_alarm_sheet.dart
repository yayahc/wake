import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wake/core/domain/entities/alarm_entity.dart';
import 'package:wake/core/extensions/context_extension.dart';

import '../state/cubit/alarm_cubit.dart';
import '../state/cubit/alarm_state.dart';

class SetAlarmSheet extends StatefulWidget {
  const SetAlarmSheet({super.key});

  @override
  State<SetAlarmSheet> createState() => _SetAlarmSheetState();
}

class _SetAlarmSheetState extends State<SetAlarmSheet> {
  late final TextEditingController _messageController;
  late final ValueNotifier<DateTime?> _ringAtNotifier;
  late final ValueNotifier<bool> _isSettingAlarm;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
    _ringAtNotifier = ValueNotifier(null);
    _isSettingAlarm = ValueNotifier(false);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _ringAtNotifier.dispose();
    _isSettingAlarm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: BlocBuilder<AlarmCubit, AlarmState>(
        builder: (context, state) {
          _handleAlarmState(context, state);
          return Form(
            child: Column(
              children: [
                TextField(controller: _messageController),
                SizedBox(height: 8),
                ListenableBuilder(
                  listenable: _isSettingAlarm,
                  builder: (context, _) {
                    return _isSettingAlarm.value
                        ? CupertinoActivityIndicator()
                        : InkWell(
                            onTap: () => _submit(),
                            child: Text('submit'),
                          );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _submit() {
    final alarmEntity = AlarmEntity(
      message: _messageController.text,
      ringAt: DateTime.now(),
    );
    AlarmCubit.instance.setAlarm(alarmEntity);
  }

  void _handleAlarmState(BuildContext context, AlarmState state) {
    switch (state) {
      case InitStateAlarmState():
      case LoadingAlarmsState():
      case FailedToLoadAlarmsState():
      case AlarmsLoadedState():
      case SettingAlarmState():
        _isSettingAlarm.value = true;
      case AlarmSuccesfulySetState():
        _isSettingAlarm.value = false;
        context.showSnackBar('Set successfuly');
      case FailedToSetAlarmState():
        _isSettingAlarm.value = false;
        context.showSnackBar((state).error.userFriendlyErrorMessage);
    }
  }
}
