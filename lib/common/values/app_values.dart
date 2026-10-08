abstract final class AppValues {
  static String get title => 'Podmatz';

  static String get version => '1.2.3';

  static String get nomePastaRaiz => 'Vários';

  // Config presets
  static const List<int> seekIntervals = [5, 10, 15, 30, 60];
  static const List<double> playbackSpeeds = [0.75, 1.0, 1.10, 1.15, 1.2, 1.25, 1.3, 1.5, 1.75, 2.0, 2.5, 3.0];

  // SharedPreferences Keys
  static const String prefKeyFolderPath = 'local_podcast_folder_path';
  static const String prefKeyLastPlayedPath = 'last_played_file_path';
  static const String prefKeyLastDurationSec = 'last_played_duration_seconds';
  static const String prefKeySeekIntervalSec = 'seek_interval_seconds';
  static const String prefKeyPlaybackSpeed = 'playback_speed';
  static const String prefKeyGroupFoldersView = 'group_folders_view';
  static const String prefKeyShowCardProgress = 'show_card_progress';
  static const String prefKeyShowEpisodeCover = 'show_episode_cover';
  static const String prefKeySkipSilence = 'skip_silence';
  static const String prefKeyCachedEpisodes = 'cached_episodes';
  static const String prefKeyUseMiniPlayerOnHome = 'use_mini_player_on_home';
  static const String prefKeyThemeModeDark = 'theme_mode_dark';

  static String prefEpisodePosKey(String path) => 'pos_${path.hashCode}';

  static String prefEpisodeDurKey(String path) => 'dur_${path.hashCode}';
}
