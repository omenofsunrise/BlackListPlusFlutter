import 'package:flutter/foundation.dart';

class BottomNavController extends ValueNotifier<bool> {
  BottomNavController._() : super(true);

  static final BottomNavController instance = BottomNavController._();

  void show() => value = true;
  void hide() => value = false;
}
