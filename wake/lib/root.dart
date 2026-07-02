import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wake/features/alarm/cubit/alarm_cubit.dart';
import 'package:wake/features/alarm/screens/main_screen.dart';

class Wake extends StatelessWidget {
  const Wake({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AlarmCubit()..getAlarms(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(useMaterial3: true),
        home: const AlarmMainScreen(),
      ),
    );
  }
}
