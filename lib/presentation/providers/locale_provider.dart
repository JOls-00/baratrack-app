import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/localization/app_strings.dart';

/// Provider for app-wide language switching (Task 29).
/// Defaults to 'fil' (Filipino / Tagalog), persists in SharedPreferences.
class LocaleProvider extends ChangeNotifier {
  static const String _prefKey = 'selected_language_code';
  String _localeCode = AppStrings.localeFil;
  bool _hasExplicitSelection = false;
  bool _loaded = false;

  String get localeCode => _localeCode;
  bool get isFilipino => _localeCode == AppStrings.localeFil;
  bool get isLoaded => _loaded;
  Locale get flutterLocale => isFilipino ? const Locale('fil') : const Locale('en');

  LocaleProvider() {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefKey);
      // Do not overwrite if the user already changed language before prefs finished loading.
      if (!_hasExplicitSelection &&
          saved != null &&
          (saved == AppStrings.localeEn || saved == AppStrings.localeFil)) {
        _localeCode = saved;
        notifyListeners();
      }
    } catch (_) {
    } finally {
      _loaded = true;
    }
  }

  Future<void> setLocale(String code) async {
    if (code != AppStrings.localeEn && code != AppStrings.localeFil) return;
    _hasExplicitSelection = true;
    if (_localeCode == code) return;
    _localeCode = code;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, code);
    } catch (_) {}
  }

  String tr(String key) {
    return AppStrings.get(key, _localeCode);
  }
}
