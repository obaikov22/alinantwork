import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WhatsNewService extends ChangeNotifier {
  static final WhatsNewService instance = WhatsNewService._();
  WhatsNewService._();

  static const _key = 'last_seen_version';

  bool _shouldShow = false;
  String _currentVersion = '';

  bool get shouldShow => _shouldShow;
  String get currentVersion => _currentVersion;

  Future<void> init() async {
    final info = await PackageInfo.fromPlatform();
    _currentVersion = info.version;
    final prefs = await SharedPreferences.getInstance();
    final lastSeen = prefs.getString(_key);
    _shouldShow = lastSeen != _currentVersion;
  }

  Future<void> markSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, _currentVersion);
    _shouldShow = false;
    notifyListeners();
  }
}
