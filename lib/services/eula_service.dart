import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EulaService extends ChangeNotifier {
  static final EulaService instance = EulaService._();
  EulaService._();

  static const _key = 'eula_accepted';

  bool _accepted = false;
  bool get accepted => _accepted;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _accepted = prefs.getBool(_key) ?? false;
  }

  Future<void> accept() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
    _accepted = true;
    notifyListeners();
  }
}
