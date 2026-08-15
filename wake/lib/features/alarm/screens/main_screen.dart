import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wake/core/domain/entities/alarm_entity.dart';
import 'package:wake/core/extensions/context_extension.dart';
import 'package:wake/features/alarm/cubit/alarm_state.dart';
import 'package:wake/features/alarm/widgets/permission_banner.dart';
import 'package:wake/features/alarm/widgets/set_alarm_sheet.dart';

import '../cubit/alarm_cubit.dart';

class AlarmMainScreen extends StatelessWidget {
  const AlarmMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Alarms')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _setNewAlarm(context),
        child: const Icon(Icons.add_alarm),
      ),
      body: Column(
        children: [
          const PermissionBanner(),
          Expanded(child: _buildList(context)),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context) {
    return BlocConsumer<AlarmCubit, AlarmState>(
        listenWhen: (_, state) =>
            state is FailedToLoadAlarmsState ||
            state is FailedToDeleteAlarmState,
        listener: (context, state) {
          if (state is FailedToLoadAlarmsState) {
            context.showSnackBar(state.error.userFriendlyErrorMessage);
          }
          if (state is FailedToDeleteAlarmState) {
            context.showSnackBar(state.error.userFriendlyErrorMessage);
          }
        },
        builder: (context, state) {
          if (state is LoadingAlarmsState) {
            return const Center(child: CircularProgressIndicator());
          }
          final alarms = context.read<AlarmCubit>().alarms;
          if (alarms.isEmpty) {
            return const Center(child: Text('No alarms yet'));
          }
          return ListView.separated(
            itemCount: alarms.length,
            separatorBuilder: (_, index) => const Divider(height: 1),
            itemBuilder: (context, index) => _AlarmTile(alarm: alarms[index]),
          );
        },
    );
  }

  void _setNewAlarm(BuildContext context) {
    final cubit = context.read<AlarmCubit>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) =>
          BlocProvider.value(value: cubit, child: const SetAlarmSheet()),
    );
  }
}

class _AlarmTile extends StatelessWidget {
  const _AlarmTile({required this.alarm});

  final AlarmEntity alarm;

  @override
  Widget build(BuildContext context) {
    final time = TimeOfDay.fromDateTime(alarm.ringAt).format(context);
    return ListTile(
      leading: const Icon(Icons.alarm),
      title: Text(time, style: const TextStyle(fontSize: 24)),
      subtitle: Text(alarm.message),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        onPressed: alarm.id == null
            ? null
            : () => context.read<AlarmCubit>().deleteAlarm(alarm.id!),
      ),
    );
  }
}
