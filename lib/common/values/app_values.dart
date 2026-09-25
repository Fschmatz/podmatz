abstract final class AppValues {
  static String get title => 'Podmatz';

  static String get version => '1.1.4';

  static String get nomePastaRaiz => 'Vários';

  // SharedPreferences Keys
  static const String prefKeyFolderPath = 'local_podcast_folder_path';
  static const String prefKeyLastPlayedPath = 'last_played_file_path';
  static const String prefKeyLastPositionSec = 'last_played_position_seconds';
  static const String prefKeyLastDurationSec = 'last_played_duration_seconds';
  static const String prefKeySeekIntervalSec = 'seek_interval_seconds';
  static const String prefKeyPlaybackSpeed = 'playback_speed';
  static const String prefKeyGroupFoldersView = 'group_folders_view';
  static const String prefKeyShowCardProgress = 'show_card_progress';
  static const String prefKeyCachedEpisodes = 'cached_episodes';
  static const String prefKeyThemeModeDark = 'theme_mode_dark';

  static String prefEpisodePosKey(String path) => 'pos_${path.hashCode}';

  static String prefEpisodeDurKey(String path) => 'dur_${path.hashCode}';
}
