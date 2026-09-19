import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

class PodcastAudioHandler extends BaseAudioHandler with SeekHandler {
  PodcastAudioHandler() {
    _init();
  }

  final AudioPlayer player = AudioPlayer();

  void _init() {
    // Broadcast player state -> audio_service state
    player.playerStateStream.listen((playerState) {
      final playing = playerState.playing;
      final processingState = playerState.processingState;

      playbackState.add(
        playbackState.value.copyWith(
          controls: [
            if (playing) MediaControl.pause else MediaControl.play,
          ],
          systemActions: const {
            MediaAction.seek,
          },
          androidCompactActionIndices: const [0],
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
    });

    player.positionStream.listen((position) {
      playbackState.add(
        playbackState.value.copyWith(
          updatePosition: position,
        ),
      );
    });

    player.durationStream.listen((duration) {
      final currentItem = mediaItem.value;
      if (currentItem != null) {
        mediaItem.add(currentItem.copyWith(duration: duration));
      }
    });
  }

  @override
  Future<void> play() => player.play();

  @override
  Future<void> pause() => player.pause();

  @override
  Future<void> stop() => player.stop();

  @override
  Future<void> seek(Duration position) => player.seek(position);
}
