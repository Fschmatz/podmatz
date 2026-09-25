import 'dart:convert';

import 'package:podmatz/podmatz.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../values/app_values.dart';

class PreferencesHelper {
  /// Returns the cached episode list from the last scan, if available.
  static Future<List<Episode>> getCachedEpisodes() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(AppValues.prefKeyCachedEpisodes);
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      final List<dynamic> list = jsonDecode(jsonStr) as List<dynamic>;
      return list.map((e) => Episode.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Caches the episode list as JSON after a scan.
  static Future<void> setCachedEpisodes(List<Episode> episodes) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(episodes.map((e) => e.toJson()).toList());
    await prefs.setString(AppValues.prefKeyCachedEpisodes, jsonStr);
  }

  /// Returns the saved local podcast folder path, if any.
  static Future<String?> getSavedFolderPath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppValues.prefKeyFolderPath);
  }

  /// Saves the selected local podcast folder path.
  static Future<void> setSavedFolderPath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppValues.prefKeyFolderPath, path);
  }

  /// Returns the file path of the last played episode.
  static Future<String?> getLastPlayedPath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppValues.prefKeyLastPlayedPath);
  }

  /// Saves the file path of the last played episode.
  static Future<void> setLastPlayedPath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppValues.prefKeyLastPlayedPath, path);
  }

  /// Returns the last playback position in seconds.
  static Future<int> getLastPositionSeconds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(AppValues.prefKeyLastPositionSec) ?? 0;
  }

  /// Saves the last playback position in seconds.
  static Future<void> setLastPositionSeconds(int seconds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppValues.prefKeyLastPositionSec, seconds);
  }

  /// Returns the last playback duration in seconds.
  static Future<int> getLastDurationSeconds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(AppValues.prefKeyLastDurationSec) ?? 0;
  }

  /// Saves the last playback duration in seconds.
  static Future<void> setLastDurationSeconds(int seconds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppValues.prefKeyLastDurationSec, seconds);
  }

  /// Returns the saved listened position in seconds for a specific episode.
  static Future<int> getEpisodePositionSeconds(String filePath) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(AppValues.prefEpisodePosKey(filePath)) ?? 0;
  }

  /// Saves the listened position in seconds for a specific episode.
  static Future<void> setEpisodePositionSeconds(String filePath, int seconds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppValues.prefEpisodePosKey(filePath), seconds);
  }

  /// Returns the cached duration in seconds for a specific episode file, if available.
  static Future<int?> getCachedDurationSeconds(String filePath) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(AppValues.prefEpisodeDurKey(filePath));
  }

  /// Caches the duration in seconds for a specific episode file.
  static Future<void> setCachedDurationSeconds(String filePath, int seconds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppValues.prefEpisodeDurKey(filePath), seconds);
  }

  /// Returns the saved seek interval in seconds (default: 15).
  static Future<int> getSeekIntervalSeconds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(AppValues.prefKeySeekIntervalSec) ?? 15;
  }

  /// Saves the seek interval in seconds.
  static Future<void> setSeekIntervalSeconds(int seconds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppValues.prefKeySeekIntervalSec, seconds);
  }

  /// Returns the saved playback speed (default: 1.0).
  static Future<double> getPlaybackSpeed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(AppValues.prefKeyPlaybackSpeed) ?? 1.0;
  }

  /// Saves the playback speed.
  static Future<void> setPlaybackSpeed(double speed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(AppValues.prefKeyPlaybackSpeed, speed);
  }

  /// Returns whether group folders view is enabled (default: true).
  static Future<bool> getGroupFoldersView() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppValues.prefKeyGroupFoldersView) ?? true;
  }

  /// Saves the group folders view setting.
  static Future<void> setGroupFoldersView(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppValues.prefKeyGroupFoldersView, enabled);
  }

  /// Returns whether card progress view is enabled (default: true).
  static Future<bool> getShowCardProgress() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppValues.prefKeyShowCardProgress) ?? true;
  }

  /// Saves the card progress setting.
  static Future<void> setShowCardProgress(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppValues.prefKeyShowCardProgress, enabled);
  }

  /// Returns whether dark mode is enabled (default: false).
  static Future<bool> isDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppValues.prefKeyThemeModeDark) ?? false;
  }

  /// Saves dark mode setting.
  static Future<void> setDarkMode(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppValues.prefKeyThemeModeDark, isDark);
  }
}
