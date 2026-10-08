import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../features/menu/cubits/theme_mode_cubit.dart';
import '../../features/player/cubit/audio_player_cubit.dart';

final GetIt locator = GetIt.instance;

void setupLocator({ThemeMode initialThemeMode = ThemeMode.system}) {
  locator.registerSingleton<ThemeModeCubit>(ThemeModeCubit(initialMode: initialThemeMode));
  locator.registerSingleton<AudioPlayerCubit>(AudioPlayerCubit());
}
