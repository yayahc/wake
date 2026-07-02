import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wake/core/domain/entities/alarm_entity.dart';
import 'package:wake/core/extensions/context_extension.dart';

import '../cubit/alarm_cubit.dart';
import '../cubit/alarm_state.dart';

class SetAlarmSheet extends StatefulWidget {
  const SetAlarmSheet({super.key});

  @override
  State<SetAlarmSheet> createState() => _SetAlarmSheetState();
}

class _SetAlarmSheetState extends State<SetAlarmSheet> {
  late final TextEditingController _messageController;
  TimeOfDay _time = TimeOfDay.now();

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AlarmCubit, AlarmState>(
      listenWhen: (_, state) =>
          state is AlarmSuccesfulySetState || state is FailedToSetAlarmState,
      listener: (context, state) {
        if (state is AlarmSuccesfulySetState) {
          Navigator.of(context).pop();
          context.showSnackBar('Alarm set');
        }
        if (state is FailedToSetAlarmState) {
          context.showSnackBar(state.error.userFriendlyErrorMessage);
        }
      },
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                labelText: 'Message',
                hintText: 'Wake up bro',
              ),
            ),
            SizedBox(
              height: 180,
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                use24hFormat: true,
                onDateTimeChanged: (dateTime) => _time = TimeOfDay(
                  hour: dateTime.hour,
                  minute: dateTime.minute,
                ),
              ),
            ),
            const SizedBox(height: 8),
            BlocBuilder<AlarmCubit, AlarmState>(
              buildWhen: (_, state) =>
                  state is SettingAlarmState ||
                  state is AlarmSuccesfulySetState ||
                  state is FailedToSetAlarmState,
              builder: (context, state) {
                final busy = state is SettingAlarmState;
                return SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: busy ? null : _submit,
                    child: busy
                        ? const CupertinoActivityIndicator()
                        : const Text('Set alarm'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  DateTime _nextRingAt() {
    final now = DateTime.now();
    var ringAt = DateTime(
      now.year,
      now.month,
      now.day,
      _time.hour,
      _time.minute,
    );
    if (!ringAt.isAfter(now)) {
      ringAt = ringAt.add(const Duration(days: 1));
    }
    return ringAt;
  }

  void _submit() {
    final message = _messageController.text.trim().isEmpty
        ? 'Wake up'
        : _messageController.text.trim();
    context.read<AlarmCubit>().setAlarm(
      AlarmEntity(message: message, ringAt: _nextRingAt()),
    );
  }
}
