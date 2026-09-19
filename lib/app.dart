import 'package:dynamic_system_colors/dynamic_system_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'common/helpers/locator.dart';
import 'common/values/app_values.dart';
import 'features/home/pages/home_page.dart';
import 'features/menu/cubits/theme_mode_cubit.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeModeCubit, ThemeMode>(
      bloc: locator<ThemeModeCubit>(),
      builder: (context, state) {
        final ThemeMode themeMode = state;

        return DynamicColorBuilder(
          builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
            final lightScheme = lightDynamic ?? ColorScheme.fromSeed(seedColor: Colors.teal);
            final darkScheme = darkDynamic ?? ColorScheme.fromSeed(seedColor: Colors.teal, brightness: Brightness.dark);

            ThemeData buildTheme(ColorScheme colorScheme) {
              return ThemeData(colorScheme: colorScheme, useMaterial3: true);
            }

            return MaterialApp(
              title: AppValues.title,
              debugShowCheckedModeBanner: false,
              themeMode: themeMode,
              theme: buildTheme(lightScheme),
              darkTheme: buildTheme(darkScheme),
              home: const HomePage(),
            );
          },
        );
      },
    );
  }
}
