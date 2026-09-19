import 'package:get_it/get_it.dart';

import '../../features/menu/cubits/theme_mode_cubit.dart';
import '../../features/player/cubit/audio_player_cubit.dart';

final GetIt locator = GetIt.instance;

void setupLocator() {
  locator.registerSingleton<ThemeModeCubit>(ThemeModeCubit());
  locator.registerSingleton<AudioPlayerCubit>(AudioPlayerCubit());
}
