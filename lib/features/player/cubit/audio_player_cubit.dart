import 'package:audio_service/audio_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../common/services/local_podcast_service.dart';
import '../../../../main.dart';
import '../../home/models/models.dart';
import '../services/podcast_audio_handler.dart';

class AudioPlayerState {
  const AudioPlayerState({
    this.currentEpisode,
    this.isPlaying = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.folderPath,
    this.episodes = const [],
    this.isLoading = false,
    this.seekIntervalSeconds = 15,
    this.playbackSpeed = 1.0,
  });

  final Episode? currentEpisode;
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final String? folderPath;
  final List<Episode> episodes;
  final bool isLoading;
  final int seekIntervalSeconds;
  final double playbackSpeed;

  AudioPlayerState copyWith({
    Episode? currentEpisode,
    bool? isPlaying,
    Duration? position,
    Duration? duration,
    String? folderPath,
    List<Episode>? episodes,
    bool? isLoading,
    int? seekIntervalSeconds,
    double? playbackSpeed,
  }) {
    return AudioPlayerState(
      currentEpisode: currentEpisode ?? this.currentEpisode,
      isPlaying: isPlaying ?? this.isPlaying,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      folderPath: folderPath ?? this.folderPath,
      episodes: episodes ?? this.episodes,
      isLoading: isLoading ?? this.isLoading,
      seekIntervalSeconds: seekIntervalSeconds ?? this.seekIntervalSeconds,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
    );
  }
}

class AudioPlayerCubit extends Cubit<AudioPlayerState> {
  AudioPlayerCubit({LocalPodcastService? podcastService})
    : _podcastService = podcastService ?? LocalPodcastService(),
      super(const AudioPlayerState()) {
    _initPlayer();
  }

  final LocalPodcastService _podcastService;

  PodcastAudioHandler get _handler => audioHandler as PodcastAudioHandler;

  AudioPlayer get _audioPlayer => _handler.player;

  static const _lastPlayedKey = 'last_played_file_path';
  static const _lastPositionKey = 'last_played_position_seconds';
  static const _lastDurationKey = 'last_played_duration_seconds';
  static const _playbackSpeedKey = 'playback_speed';

  /// Tracks whether the AudioPlayer has an actual source loaded.
  /// After app restart this is false even if currentEpisode is restored.
  bool _isSourceLoaded = false;

  /// Debounce: last time position was persisted.
  DateTime _lastPositionSave = DateTime.fromMillisecondsSinceEpoch(0);

  void _initPlayer() {
    _audioPlayer.playerStateStream.listen((playerState) {
      final playing = playerState.playing;
      final processingState = playerState.processingState;
      emit(state.copyWith(isPlaying: playing));

      // Save position when paused or completed
      if (!playing || processingState == ProcessingState.completed) {
        _persistPosition();
      }
    });

    _audioPlayer.positionStream.listen((pos) {
      emit(state.copyWith(position: pos));

      // Debounce: save position at most every 5 seconds
      final now = DateTime.now();
      if (now.difference(_lastPositionSave).inSeconds >= 5) {
        _persistPosition();
      }
    });

    _audioPlayer.durationStream.listen((dur) {
      if (dur != null && dur.inSeconds > 0) {
        final currentPath = state.currentEpisode?.filePath;

        // Update state duration and also update the episode in episodes list
        List<Episode> updatedEpisodes = state.episodes;
        Episode? updatedCurrent = state.currentEpisode;

        if (currentPath != null) {
          updatedEpisodes = state.episodes.map((ep) {
            if (ep.filePath == currentPath) {
              return ep.copyWith(total: dur);
            }
            return ep;
          }).toList();

          if (updatedCurrent != null && updatedCurrent.filePath == currentPath) {
            updatedCurrent = updatedCurrent.copyWith(total: dur);
          }
        }

        emit(state.copyWith(duration: dur, episodes: updatedEpisodes, currentEpisode: updatedCurrent));

        if (updatedCurrent != null) {
          _updateMediaItem(updatedCurrent);
        }

        if (currentPath != null) {
          SharedPreferences.getInstance().then((prefs) {
            prefs.setInt(_lastDurationKey, dur.inSeconds);
            prefs.setInt('dur_${currentPath.hashCode}', dur.inSeconds);
          });
        }
      }
    });

    loadSavedFolder();
    loadSavedSeekInterval();
    _loadSavedPlaybackSpeed();
  }

  Future<void> _persistPosition() async {
    _lastPositionSave = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastPositionKey, state.position.inSeconds);
    if (state.duration.inSeconds > 0) {
      await prefs.setInt(_lastDurationKey, state.duration.inSeconds);
    }
  }

  Future<void> loadSavedSeekInterval() async {
    final prefs = await SharedPreferences.getInstance();
    final interval = prefs.getInt('seek_interval_seconds') ?? 15;
    emit(state.copyWith(seekIntervalSeconds: interval));
  }

  Future<void> setSeekInterval(int seconds) async {
    if (seconds <= 0) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('seek_interval_seconds', seconds);
    emit(state.copyWith(seekIntervalSeconds: seconds));
  }

  Future<void> _loadSavedPlaybackSpeed() async {
    final prefs = await SharedPreferences.getInstance();
    final speed = prefs.getDouble(_playbackSpeedKey) ?? 1.0;
    emit(state.copyWith(playbackSpeed: speed));
    await _audioPlayer.setSpeed(speed);
  }

  Future<void> setPlaybackSpeed(double speed) async {
    if (speed <= 0) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_playbackSpeedKey, speed);
    await _audioPlayer.setSpeed(speed);
    emit(state.copyWith(playbackSpeed: speed));
  }

  Future<void> loadSavedFolder() async {
    emit(state.copyWith(isLoading: true));
    final savedPath = await _podcastService.getSavedFolderPath();
    if (savedPath != null) {
      final list = await _podcastService.scanFolder(savedPath);
      final prefs = await SharedPreferences.getInstance();
      final lastPlayedPath = prefs.getString(_lastPlayedKey);
      final lastPositionSec = prefs.getInt(_lastPositionKey) ?? 0;
      final lastDurationSec = prefs.getInt(_lastDurationKey) ?? 0;

      Episode? lastPlayed;
      if (lastPlayedPath != null && list.isNotEmpty) {
        lastPlayed = list.cast<Episode?>().firstWhere((e) => e?.filePath == lastPlayedPath, orElse: () => null);
      }
      final restoredDuration = lastDurationSec > 0 ? Duration(seconds: lastDurationSec) : (lastPlayed?.total ?? Duration.zero);

      emit(
        state.copyWith(
          folderPath: savedPath,
          episodes: list,
          isLoading: false,
          currentEpisode: lastPlayed,
          position: Duration(seconds: lastPositionSec),
          duration: restoredDuration,
        ),
      );
      if (lastPlayed != null) {
        _updateMediaItem(lastPlayed);
      }
      _inspectUncachedDurations(list);
    } else {
      emit(state.copyWith(isLoading: false));
    }
  }

  /// Inspects uncached episode durations using a temporary player instance
  /// in background without interrupting current playback.
  Future<void> _inspectUncachedDurations(List<Episode> episodes) async {
    final prefs = await SharedPreferences.getInstance();
    final uncached = episodes.where((ep) {
      if (ep.filePath == null) return false;
      final cachedSec = prefs.getInt('dur_${ep.filePath.hashCode}');
      return cachedSec == null || cachedSec <= 0;
    }).toList();

    if (uncached.isEmpty) return;

    final tempPlayer = AudioPlayer();
    try {
      for (final episode in uncached) {
        if (episode.filePath == null) continue;
        try {
          final dur = await tempPlayer.setAudioSource(AudioSource.file(episode.filePath!), preload: true);
          if (dur != null && dur.inSeconds > 0) {
            await prefs.setInt('dur_${episode.filePath.hashCode}', dur.inSeconds);

            // Update Cubit state list if episode is still present
            final currentList = state.episodes;
            final updatedList = currentList.map((ep) {
              if (ep.filePath == episode.filePath) {
                return ep.copyWith(total: dur);
              }
              return ep;
            }).toList();

            Episode? updatedCurrent = state.currentEpisode;
            if (updatedCurrent?.filePath == episode.filePath) {
              updatedCurrent = updatedCurrent?.copyWith(total: dur);
            }

            emit(
              state.copyWith(
                episodes: updatedList,
                currentEpisode: updatedCurrent,
                duration: updatedCurrent?.filePath == episode.filePath ? dur : state.duration,
              ),
            );
          }
        } catch (_) {}
      }
    } finally {
      await tempPlayer.dispose();
    }
  }

  Future<void> pickFolder() async {
    emit(state.copyWith(isLoading: true));
    final selected = await _podcastService.pickFolder();
    if (selected != null) {
      final list = await _podcastService.scanFolder(selected);
      emit(state.copyWith(folderPath: selected, episodes: list, isLoading: false));
      _inspectUncachedDurations(list);
    } else {
      emit(state.copyWith(isLoading: false));
    }
  }

  Future<void> selectEpisode(Episode episode) async {
    if (episode.filePath == null) return;
    if (state.currentEpisode?.filePath == episode.filePath) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastPlayedKey, episode.filePath!);
    await prefs.setInt(_lastPositionKey, 0);

    _isSourceLoaded = false;
    await _audioPlayer.stop();

    emit(state.copyWith(currentEpisode: episode, position: Duration.zero, duration: episode.total, isPlaying: false));
    _updateMediaItem(episode);
  }

  void _updateMediaItem(Episode episode) {
    _handler.mediaItem.add(
      MediaItem(
        id: episode.filePath!,
        album: 'Podmatz',
        title: episode.title,
        artist: episode.host,
        duration: state.duration > Duration.zero ? state.duration : episode.total,
      ),
    );
  }

  Future<void> playEpisode(Episode episode) async {
    if (episode.filePath == null) return;

    if (state.currentEpisode?.filePath == episode.filePath) {
      if (_isSourceLoaded) {
        // Source is loaded — just toggle play/pause
        if (state.isPlaying) {
          await _audioPlayer.pause();
        } else {
          await _audioPlayer.play();
        }
        return;
      }
      // Source NOT loaded (cold restore) — load file and seek to saved position
      final savedPosition = state.position;
      try {
        _isSourceLoaded = true;
        emit(state.copyWith(isPlaying: true));
        _updateMediaItem(episode);
        await _audioPlayer.setAudioSource(AudioSource.file(episode.filePath!), initialPosition: savedPosition > Duration.zero ? savedPosition : null);
        if (state.playbackSpeed != 1.0) {
          await _audioPlayer.setSpeed(state.playbackSpeed);
        }
        await _audioPlayer.play();
      } catch (e) {
        _isSourceLoaded = false;
        emit(state.copyWith(isPlaying: false));
      }
      return;
    }

    // Different episode — load new file
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastPlayedKey, episode.filePath!);
    await prefs.setInt(_lastPositionKey, 0);

    emit(state.copyWith(currentEpisode: episode, position: Duration.zero, duration: episode.total));

    try {
      _isSourceLoaded = true;
      await _audioPlayer.stop();
      _updateMediaItem(episode);
      await _audioPlayer.setAudioSource(AudioSource.file(episode.filePath!));
      if (state.playbackSpeed != 1.0) {
        await _audioPlayer.setSpeed(state.playbackSpeed);
      }
      await _audioPlayer.play();
    } catch (e) {
      _isSourceLoaded = false;
      emit(state.copyWith(isPlaying: false));
    }
  }

  Future<void> togglePlayPause() async {
    if (!_isSourceLoaded && state.currentEpisode != null) {
      // Cold restore — need to actually load the file first
      await playEpisode(state.currentEpisode!);
      return;
    }
    if (state.isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play();
    }
  }

  Future<void> seek(Duration position) async {
    emit(state.copyWith(position: position));
    await _audioPlayer.seek(position);
  }

  Future<void> seekForward() async {
    final newPos = state.position + Duration(seconds: state.seekIntervalSeconds);
    await seek(newPos > state.duration ? state.duration : newPos);
  }

  Future<void> seekBackward() async {
    final newPos = state.position - Duration(seconds: state.seekIntervalSeconds);
    await seek(newPos < Duration.zero ? Duration.zero : newPos);
  }

  @override
  Future<void> close() {
    _persistPosition();
    _audioPlayer.dispose();
    return super.close();
  }
}
