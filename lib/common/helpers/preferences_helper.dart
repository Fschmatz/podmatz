import 'dart:convert';

import 'package:podmatz/podmatz.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesHelper {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static Future<List<Episode>> getCachedEpisodes() async {
    final jsonStr = _prefs!.getString(AppValues.prefKeyCachedEpisodes);

    if (jsonStr == null || jsonStr.isEmpty) return [];

    try {
      final List<dynamic> list = jsonDecode(jsonStr) as List<dynamic>;

      return list.map((e) => Episode.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> setCachedEpisodes(List<Episode> episodes) async {
    final jsonStr = jsonEncode(episodes.map((e) => e.toJson()).toList());

    await _prefs!.setString(AppValues.prefKeyCachedEpisodes, jsonStr);
  }

  static Future<String?> getSavedFolderPath() async {
    return _prefs!.getString(AppValues.prefKeyFolderPath);
  }

  static Future<void> setSavedFolderPath(String path) async {
    await _prefs!.setString(AppValues.prefKeyFolderPath, path);
  }

  static Future<String?> getLastPlayedPath() async {
    return _prefs!.getString(AppValues.prefKeyLastPlayedPath);
  }

  static Future<void> setLastPlayedPath(String path) async {
    await _prefs!.setString(AppValues.prefKeyLastPlayedPath, path);
  }

  static Future<int> getLastDurationSeconds() async {
    return _prefs!.getInt(AppValues.prefKeyLastDurationSec) ?? 0;
  }

  static Future<void> setLastDurationSeconds(int seconds) async {
    await _prefs!.setInt(AppValues.prefKeyLastDurationSec, seconds);
  }

  static Future<int> getEpisodePositionSeconds(String filePath) async {
    return _prefs!.getInt(AppValues.prefEpisodePosKey(filePath)) ?? 0;
  }

  static Future<void> setEpisodePositionSeconds(String filePath, int seconds) async {
    await _prefs!.setInt(AppValues.prefEpisodePosKey(filePath), seconds);
  }

  static Future<int?> getCachedDurationSeconds(String filePath) async {
    return _prefs!.getInt(AppValues.prefEpisodeDurKey(filePath));
  }

  static Future<void> setCachedDurationSeconds(String filePath, int seconds) async {
    await _prefs!.setInt(AppValues.prefEpisodeDurKey(filePath), seconds);
  }

  static Future<int> getSeekIntervalSeconds() async {
    return _prefs!.getInt(AppValues.prefKeySeekIntervalSec) ?? 15;
  }

  static Future<void> setSeekIntervalSeconds(int seconds) async {
    await _prefs!.setInt(AppValues.prefKeySeekIntervalSec, seconds);
  }

  static Future<double> getPlaybackSpeed() async {
    return _prefs!.getDouble(AppValues.prefKeyPlaybackSpeed) ?? 1.0;
  }

  static Future<void> setPlaybackSpeed(double speed) async {
    await _prefs!.setDouble(AppValues.prefKeyPlaybackSpeed, speed);
  }

  static Future<bool> getGroupFoldersView() async {
    return _prefs!.getBool(AppValues.prefKeyGroupFoldersView) ?? true;
  }

  static Future<void> setGroupFoldersView(bool enabled) async {
    await _prefs!.setBool(AppValues.prefKeyGroupFoldersView, enabled);
  }

  static Future<bool> getShowCardProgress() async {
    return _prefs!.getBool(AppValues.prefKeyShowCardProgress) ?? true;
  }

  static Future<void> setShowCardProgress(bool enabled) async {
    await _prefs!.setBool(AppValues.prefKeyShowCardProgress, enabled);
  }

  static Future<bool> getShowEpisodeCover() async {
    return _prefs!.getBool(AppValues.prefKeyShowEpisodeCover) ?? true;
  }

  static Future<void> setShowEpisodeCover(bool enabled) async {
    await _prefs!.setBool(AppValues.prefKeyShowEpisodeCover, enabled);
  }

  static Future<bool> isDarkMode() async {
    return _prefs!.getBool(AppValues.prefKeyThemeModeDark) ?? false;
  }

  static Future<void> setDarkMode(bool isDark) async {
    await _prefs!.setBool(AppValues.prefKeyThemeModeDark, isDark);
  }

  static Future<bool> getSkipSilence() async {
    return _prefs!.getBool(AppValues.prefKeySkipSilence) ?? false;
  }

  static Future<void> setSkipSilence(bool enabled) async {
    await _prefs!.setBool(AppValues.prefKeySkipSilence, enabled);
  }

  static Future<bool> getUseMiniPlayerOnHome() async {
    return _prefs!.getBool(AppValues.prefKeyUseMiniPlayerOnHome) ?? false;
  }

  static Future<void> setUseMiniPlayerOnHome(bool enabled) async {
    await _prefs!.setBool(AppValues.prefKeyUseMiniPlayerOnHome, enabled);
  }
}
