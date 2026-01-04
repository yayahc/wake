import 'package:flutter/material.dart';

extension ContextExtension on BuildContext {
  void showDefaultButtonSheet(Widget child) {
    showBottomSheet(context: this, builder: (context) => child);
  }

  void showSnackBar(String message) {
    ScaffoldMessenger.of(this).removeCurrentSnackBar();
    ScaffoldMessenger.of(this).showSnackBar(SnackBar(content: Text(message)));
  }
}
