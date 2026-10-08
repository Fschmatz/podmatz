import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:podmatz/podmatz.dart';

class ThemeModeCubit extends Cubit<ThemeMode> {
  ThemeModeCubit({ThemeMode initialMode = ThemeMode.system}) : super(initialMode) {
    _loadSavedTheme();
  }

  Future<void> _loadSavedTheme() async {
    final isDark = await PreferencesHelper.isDarkMode();
    final loadedMode = isDark ? ThemeMode.dark : ThemeMode.light;
    if (state != loadedMode) {
      emit(loadedMode);
    }
  }

  Future<void> toggle() async {
    final ThemeMode newMode = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    await PreferencesHelper.setDarkMode(newMode == ThemeMode.dark);

    emit(newMode);
  }
}
