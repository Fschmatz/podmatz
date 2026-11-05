import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';
import 'package:podmatz/podmatz.dart';

class PodcastAudioHandler extends BaseAudioHandler with SeekHandler {
  PodcastAudioHandler() {
    _init();
  }

  final AudioPlayer player = AudioPlayer();

  void _init() {
    // Initial playback state
    playbackState.add(
      PlaybackState(
        controls: const [MediaControl.rewind, MediaControl.play, MediaControl.fastForward],
        systemActions: const {
          MediaAction.play,
          MediaAction.pause,
          MediaAction.playPause,
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
          MediaAction.fastForward,
          MediaAction.rewind,
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState: AudioProcessingState.idle,
        playing: false,
      ),
    );

    player.playerStateStream.listen((playerState) {
      _broadcastState();
    });

    player.playbackEventStream.listen(
      (event) {
        _broadcastState();
      },
      onError: (Object e, StackTrace st) {
        // ignore playback errors silently
      },
    );

    player.durationStream.listen((duration) {
      if (duration == null || duration.inSeconds <= 0) return;
      final currentItem = mediaItem.value;
      if (currentItem != null && currentItem.duration != duration) {
        mediaItem.add(currentItem.copyWith(duration: duration));
      }
    });
  }

  void _broadcastState() {
    final playing = player.playing;
    final processingState = player.processingState;

    playbackState.add(
      playbackState.value.copyWith(
        controls: [
          MediaControl.rewind,
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.fastForward,
        ],
        systemActions: const {
          MediaAction.play,
          MediaAction.pause,
          MediaAction.playPause,
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
          MediaAction.fastForward,
          MediaAction.rewind,
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState: const {
          ProcessingState.idle: AudioProcessingState.idle,
          ProcessingState.loading: AudioProcessingState.loading,
          ProcessingState.buffering: AudioProcessingState.buffering,
          ProcessingState.ready: AudioProcessingState.ready,
          ProcessingState.completed: AudioProcessingState.completed,
        }[processingState] ?? AudioProcessingState.idle,
        playing: playing,
        updatePosition: player.position,
        bufferedPosition: player.bufferedPosition,
        speed: player.speed,
      ),
    );
  }

  Future<int> _getSeekIntervalSeconds() async {
    return PreferencesHelper.getSeekIntervalSeconds();
  }

  /// Loads an audio source, updates audio focus and MediaItem.
  /// If [autoPlay] is true, triggers playback immediately after preparing.
  Future<void> prepareAndPlay({
    required MediaItem item,
    required String filePath,
    required Duration initialPosition,
    required double speed,
    required bool skipSilence,
    bool autoPlay = true,
  }) async {
    try {
      final session = await AudioSession.instance;
      await session.setActive(true);

      // Update media item before or together with setting source so notification is in sync
      mediaItem.add(item);

      // Load source without calling stop() which breaks the media session
      await player.setAudioSource(
        AudioSource.file(filePath),
        initialPosition: initialPosition > Duration.zero ? initialPosition : null,
      );

      await player.setSpeed(speed);
      await player.setSkipSilenceEnabled(skipSilence);

      if (autoPlay) {
        player.play().catchError((_) {
          // ignore async play errors
        });
      }
    } catch (_) {
      rethrow;
    }
  }

  @override
  Future<void> play() async {
    try {
      final session = await AudioSession.instance;
      await session.setActive(true);

      // Re-load source if it was cleared
      if (player.audioSource == null && mediaItem.value != null) {
        final filePath = mediaItem.value!.id;
        final savedPosSec = await PreferencesHelper.getEpisodePositionSeconds(filePath);
        final initialPos = Duration(seconds: savedPosSec);
        await player.setAudioSource(
          AudioSource.file(filePath),
          initialPosition: initialPos > Duration.zero ? initialPos : null,
        );
      }

      // Start playback without blocking the MediaSession IPC callback.
      // player.play() completes only when playback finishes or pauses in just_audio,
      // which would keep this Future unresolved and cause Android notification timeouts.
      player.play().catchError((_) {
        // ignore async play errors
      });
    } catch (_) {
      // ignore
    }
  }

  @override
  Future<void> pause() async {
    try {
      await player.pause();
    } catch (_) {
      // ignore
    }
  }

  Future<void> playPause() async {
    if (player.playing) {
      await pause();
    } else {
      await play();
    }
  }

  @override
  Future<void> click([MediaButton button = MediaButton.media]) async {
    switch (button) {
      case MediaButton.media:
      case MediaButton.next:
        await playPause();
        break;
      case MediaButton.previous:
        await rewind();
        break;
    }
  }

  @override
  Future<void> stop() async {
    try {
      await player.stop();
      final session = await AudioSession.instance;
      await session.setActive(false);
    } catch (_) {
      // ignore
    }

    playbackState.add(
      playbackState.value.copyWith(
        playing: false,
        processingState: AudioProcessingState.idle,
      ),
    );
  }

  @override
  Future<void> seek(Duration position) async {
    try {
      await player.seek(position);
      playbackState.add(playbackState.value.copyWith(updatePosition: position));
    } catch (_) {
      // ignore
    }
  }

  @override
  Future<void> fastForward() async {
    try {
      final seconds = await _getSeekIntervalSeconds();
      final newPos = player.position + Duration(seconds: seconds);
      final duration = player.duration ?? Duration.zero;
      final target = newPos > duration ? duration : newPos;
      await player.seek(target);
      playbackState.add(playbackState.value.copyWith(updatePosition: target));
    } catch (_) {
      // ignore
    }
  }

  @override
  Future<void> rewind() async {
    try {
      final seconds = await _getSeekIntervalSeconds();
      final newPos = player.position - Duration(seconds: seconds);
      final target = newPos < Duration.zero ? Duration.zero : newPos;
      await player.seek(target);
      playbackState.add(playbackState.value.copyWith(updatePosition: target));
    } catch (_) {
      // ignore
    }
  }

  @override
  Future<void> skipToNext() => fastForward();

  @override
  Future<void> skipToPrevious() => rewind();
}
