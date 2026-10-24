import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:podmatz/podmatz.dart';

class PodcastAudioHandler extends BaseAudioHandler with SeekHandler {
  PodcastAudioHandler() {
    _init();
  }

  static const MethodChannel _wakeLockChannel = MethodChannel('com.fschmatz.podmatz/wakelock');

  final AudioPlayer player = AudioPlayer();

  /// Releases the AudioService native CPU WakeLock via reflection.
  /// Safe to call even if the MethodChannel handler isn't registered yet.
  void _releaseNativeWakeLock() {
    _wakeLockChannel.invokeMethod<void>('releaseWakeLock').catchError((_) {});
  }

  /// Acquires the AudioService native CPU WakeLock via reflection.
  void _acquireNativeWakeLock() {
    _wakeLockChannel.invokeMethod<void>('acquireWakeLock').catchError((_) {});
  }

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

    // SYNCHRONOUS listener — no async/await here.
    // WakeLock and AudioSession are managed in play() / pause() / stop() directly.
    player.playerStateStream.listen((playerState) {
      final playing = playerState.playing;
      final processingState = playerState.processingState;

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
          processingState:
              const {
                ProcessingState.idle: AudioProcessingState.idle,
                ProcessingState.loading: AudioProcessingState.loading,
                ProcessingState.buffering: AudioProcessingState.buffering,
                ProcessingState.ready: AudioProcessingState.ready,
                ProcessingState.completed: AudioProcessingState.completed,
              }[processingState] ??
              AudioProcessingState.idle,
          playing: playing,
          updatePosition: player.position,
          bufferedPosition: player.bufferedPosition,
          speed: player.speed,
        ),
      );
    });

    player.durationStream.listen((duration) {
      final currentItem = mediaItem.value;
      if (currentItem != null) {
        mediaItem.add(currentItem.copyWith(duration: duration));
      }
    });

    player.playbackEventStream.listen(
      (_) {},
      onError: (Object e, StackTrace st) {
        // Prevent uncaught stream errors from crashing the isolate
      },
    );
  }

  Future<int> _getSeekIntervalSeconds() async {
    return PreferencesHelper.getSeekIntervalSeconds();
  }

  @override
  Future<void> play() async {
    try {
      // Activate audio hardware session before playing
      final session = await AudioSession.instance;
      await session.setActive(true);

      // Re-load source if it was cleared (e.g. after stop())
      if (player.audioSource == null && mediaItem.value != null) {
        final filePath = mediaItem.value!.id;
        final savedPosSec = await PreferencesHelper.getEpisodePositionSeconds(filePath);
        final initialPos = Duration(seconds: savedPosSec);
        await player.setAudioSource(
          AudioSource.file(filePath),
          initialPosition: initialPos > Duration.zero ? initialPos : null,
        );
      }

      await player.play();

      // Re-acquire WakeLock to keep CPU awake during playback
      _acquireNativeWakeLock();
    } catch (_) {}
  }

  @override
  Future<void> pause() async {
    try {
      await player.pause();

      // Release WakeLock immediately on pause to allow CPU to sleep
      _releaseNativeWakeLock();

      // Deactivate audio hardware session so Android can reclaim resources
      final session = await AudioSession.instance;
      await session.setActive(false);
    } catch (_) {}
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

      // Release WakeLock and deactivate audio session on stop
      _releaseNativeWakeLock();
      final session = await AudioSession.instance;
      await session.setActive(false);
    } catch (_) {}

    playbackState.add(
      playbackState.value.copyWith(
        playing: false,
        processingState: AudioProcessingState.idle,
      ),
    );
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) async {
    try {
      await player.seek(position);
      playbackState.add(playbackState.value.copyWith(updatePosition: position));
    } catch (_) {}
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
    } catch (_) {}
  }

  @override
  Future<void> rewind() async {
    try {
      final seconds = await _getSeekIntervalSeconds();
      final newPos = player.position - Duration(seconds: seconds);
      final target = newPos < Duration.zero ? Duration.zero : newPos;
      await player.seek(target);
      playbackState.add(playbackState.value.copyWith(updatePosition: target));
    } catch (_) {}
  }

  @override
  Future<void> skipToNext() => fastForward();

  @override
  Future<void> skipToPrevious() => rewind();
}
