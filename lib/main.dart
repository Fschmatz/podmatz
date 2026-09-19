import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'app.dart';
import 'common/helpers/locator.dart';
import 'common/widgets/friendly_error_view.dart';
import 'features/player/services/podcast_audio_handler.dart';

late AudioHandler audioHandler;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Permission.notification.request();

  audioHandler = await AudioService.init(
    builder: () => PodcastAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.fschmatz.podmatz.channel.audio',
      androidNotificationChannelName: 'Podmatz Playback',
      androidNotificationOngoing: false,
      androidStopForegroundOnPause: false,
      androidNotificationIcon: 'drawable/ic_notification',
    ),
  );

  ErrorWidget.builder = (details) {
    return FriendlyErrorView(details: details);
  };

  setupLocator();

  runApp(const App());
}
