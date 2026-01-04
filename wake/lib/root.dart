import 'package:flutter/material.dart';
import 'package:wake/features/alarm/screens/main_screen.dart';

class Wake extends StatelessWidget {
  const Wake({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      showPerformanceOverlay: true,
      debugShowCheckedModeBanner: true,
      builder: (context, child) => AlarmMainScreen(),
    );
  }
}