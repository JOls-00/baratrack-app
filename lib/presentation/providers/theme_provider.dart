import 'package:flutter/material.dart';

enum ThemeCombo {
  barangayRosario,
  dustyRoseWind,
  caramelWheat,
  blackishCaramel,
}

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  ThemeCombo _themeCombo = ThemeCombo.barangayRosario;

  ThemeMode get themeMode => _themeMode;
  ThemeCombo get themeCombo => _themeCombo;

  void setThemeCombo(ThemeCombo combo) {
    _themeCombo = combo;
    if (combo == ThemeCombo.blackishCaramel) {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.light;
    }
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }
}
