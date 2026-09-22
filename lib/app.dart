import 'package:dynamic_system_colors/dynamic_system_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'common/helpers/locator.dart';
import 'common/values/app_values.dart';
import 'features/home/pages/home_page.dart';
import 'features/menu/cubits/theme_mode_cubit.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  ColorScheme? _cachedLight;
  ColorScheme? _cachedDark;

  ThemeData _buildTheme(ColorScheme colorScheme) {
    return ThemeData(colorScheme: colorScheme, useMaterial3: true);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeModeCubit, ThemeMode>(
      bloc: locator<ThemeModeCubit>(),
      builder: (context, themeMode) {
        return DynamicColorBuilder(
          builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
            if (lightDynamic != null) _cachedLight = lightDynamic;
            if (darkDynamic != null) _cachedDark = darkDynamic;

            final lightScheme = _cachedLight ?? ColorScheme.fromSeed(seedColor: Colors.teal);
            final darkScheme = _cachedDark ?? ColorScheme.fromSeed(seedColor: Colors.teal, brightness: Brightness.dark);

            return MaterialApp(
              title: AppValues.title,
              debugShowCheckedModeBanner: false,
              themeMode: themeMode,
              theme: _buildTheme(lightScheme),
              darkTheme: _buildTheme(darkScheme),
              home: const HomePage(),
            );
          },
        );
      },
    );
  }
}
