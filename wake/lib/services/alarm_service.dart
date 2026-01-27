import 'package:wake/services/notification_service.dart';

@pragma('vm:entry-point')
void printHello() {
  final DateTime now = DateTime.now();
  sendNofitication('[$now] Hello, world!', 'wakup bro !');
}
