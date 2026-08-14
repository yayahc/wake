import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wake/features/alarm/cubit/alarm_cubit.dart';
import 'package:wake/features/alarm/screens/main_screen.dart';
import 'package:wake/features/quiz/screens/quiz_gate_screen.dart';
import 'package:wake/services/ios_alarm_channel.dart';

class Wake extends StatefulWidget {
  const Wake({super.key});

  @override
  State<Wake> createState() => _WakeState();
}

class _WakeState extends State<Wake> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  final _cubit = AlarmCubit()..getAlarms();

  StreamSubscription<int>? _quizSubscription;
  bool _quizVisible = false;

  @override
  void initState() {
    super.initState();
    if (Platform.isIOS) {
      _quizSubscription = IosAlarmChannel.quizRequests.listen(_openQuiz);
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final pending = await IosAlarmChannel.pendingQuizAlarmId();
        if (pending != null) _openQuiz(pending);
      });
    }
  }

  @override
  void dispose() {
    _quizSubscription?.cancel();
    _cubit.close();
    super.dispose();
  }

  Future<void> _openQuiz(int alarmId) async {
    if (_quizVisible) return;
    final navigator = _navigatorKey.currentState;
    if (navigator == null) return;

    _quizVisible = true;
    await navigator.push(
      MaterialPageRoute<bool>(
        fullscreenDialog: true,
        builder: (_) => QuizGateScreen(alarmId: alarmId),
      ),
    );
    _quizVisible = false;
    _cubit.getAlarms();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: MaterialApp(
        navigatorKey: _navigatorKey,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(useMaterial3: true),
        home: const AlarmMainScreen(),
      ),
    );
  }
}
