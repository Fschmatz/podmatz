import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:podmatz/podmatz.dart';

import 'features/player/services/podcast_audio_handler.dart';

late AudioHandler audioHandler;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await PreferencesHelper.init();

  final session = await AudioSession.instance;
  await session.configure(const AudioSessionConfiguration.music());

  session.becomingNoisyEventStream.listen((_) {
    audioHandler.pause();
  });

  audioHandler = await AudioService.init(
    builder: () => PodcastAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.fschmatz.podmatz.channel.audio',
      androidNotificationChannelName: 'Podmatz Playback',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
      androidNotificationIcon: 'drawable/ic_notification',
    ),
  );

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
  };

  ErrorWidget.builder = (details) {
    return FriendlyErrorView(details: details);
  };

  final isDark = await PreferencesHelper.isDarkMode();
  final initialThemeMode = isDark ? ThemeMode.dark : ThemeMode.light;

  setupLocator(initialThemeMode: initialThemeMode);

  runApp(const App());
}
