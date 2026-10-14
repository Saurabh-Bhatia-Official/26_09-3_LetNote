import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';

class ThemeState {
  final ThemeMode themeMode;
  final AppAccentColor accentColor;

  const ThemeState({
    this.themeMode = ThemeMode.dark,
    this.accentColor = AppAccentColor.emerald,
  });

  ThemeState copyWith({
    ThemeMode? themeMode,
    AppAccentColor? accentColor,
  }) {
    return ThemeState(
      themeMode: themeMode ?? this.themeMode,
      accentColor: accentColor ?? this.accentColor,
    );
  }
}

class ThemeNotifier extends Notifier<ThemeState> {
  @override
  ThemeState build() => const ThemeState();

  void setThemeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
  }

  void setAccentColor(AppAccentColor color) {
    state = state.copyWith(accentColor: color);
  }

  void toggleTheme() {
    if (state.themeMode == ThemeMode.dark) {
      state = state.copyWith(themeMode: ThemeMode.light);
    } else {
      state = state.copyWith(themeMode: ThemeMode.dark);
    }
  }
}

final themeProvider = NotifierProvider<ThemeNotifier, ThemeState>(ThemeNotifier.new);
