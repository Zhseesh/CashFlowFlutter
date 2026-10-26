import 'package:flutter/foundation.dart';

class AppEvents {
  AppEvents._();
  static final ValueNotifier<int> dataChanged = ValueNotifier(0);
  static void notify() => dataChanged.value++;
}