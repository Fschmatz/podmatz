import 'package:podmatz/podmatz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PlayerPage extends StatefulWidget {
  const PlayerPage({super.key, required this.episode, this.fromChannel = false});

  final Episode episode;
  final bool fromChannel;

  static Route<void> route(Episode episode, {bool fromChannel = false}) {
    return MaterialPageRoute<void>(
      builder: (context) => PlayerPage(episode: episode, fromChannel: fromChannel),
    );
  }

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  double? _dragValue;

  @override
  Widget build(BuildContext context) {
    final Episode pageEpisode = widget.episode;
    final ColorScheme cs = pageEpisode.scheme(context);
    final TextTheme tt = Theme.of(context).textTheme;

    return BlocBuilder<AudioPlayerCubit, AudioPlayerState>(
      bloc: locator<AudioPlayerCubit>(),
      builder: (context, playerState) {
        final bool isCurrent = playerState.currentEpisode?.filePath == pageEpisode.filePath;
        final bool isPlaying = isCurrent && playerState.isPlaying;

        final Duration totalDuration = isCurrent && playerState.duration.inSeconds > 0 ? playerState.duration : pageEpisode.total;
        final Duration currentPos = isCurrent ? playerState.position : Duration.zero;

        final double maxSeconds = totalDuration.inSeconds > 0 ? totalDuration.inSeconds.toDouble() : 1.0;
        final double currentSeconds = currentPos.inSeconds.toDouble().clamp(0.0, maxSeconds);
        final double sliderValue = (_dragValue ?? currentSeconds).clamp(0.0, maxSeconds);

        final Duration displayPos = Duration(seconds: sliderValue.toInt());
        final Duration remaining = totalDuration - displayPos;
        final bool ended = remaining <= Duration.zero;

        // Calculate time left accounting for playback speed (e.g. 1.2x)
        final double speed = playerState.playbackSpeed > 0 ? playerState.playbackSpeed : 1.0;
        final Duration speedAdjustedRemaining = Duration(seconds: (remaining.inSeconds / speed).round());

        final String timeLabel = ended ? totalDuration.remainingLabel : '-${remaining.remainingLabel}';
        final String speedTimeLabel = speed != 1.0 && !ended
            ? '(-${speedAdjustedRemaining.remainingLabel} em ${speed.toStringAsFixed(1)}x)'
            : '';

        return Scaffold(
          backgroundColor: cs.surface,
          appBar: AppBar(backgroundColor: cs.surface, leading: const StyledBackButton()),
          body: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                16.gap,
                if (pageEpisode.channel.isNotEmpty && pageEpisode.channel.toUpperCase() != 'PODCAST LOCAL')
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        pageEpisode.channel.toUpperCase(),
                        style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                12.gap,
                Padding(
                  padding: const EdgeInsets.only(right: 56),
                  child: Text(
                    pageEpisode.title,
                    style: tt.displaySmall?.copyWith(color: cs.primary, fontWeight: FontWeight.w800),
                  ),
                ),
                8.gap,
                Row(
                  children: [
                    Icon(Icons.schedule_rounded, size: 16, color: cs.onSurfaceVariant),
                    6.gap,
                    Text(
                      'Duração total: ${totalDuration.remainingLabel}',
                      style: tt.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        timeLabel,
                        style: TextStyle(
                          color: cs.onSurface,
                          fontSize: 56,
                          fontWeight: FontWeight.w700,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      if (speedTimeLabel.isNotEmpty)
                        Text(
                          speedTimeLabel,
                          style: tt.titleMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
                8.gap,
                _InteractiveSeekBar(
                  value: sliderValue,
                  max: maxSeconds,
                  scheme: cs,
                  onChanged: (val) {
                    if (isCurrent) {
                      setState(() {
                        _dragValue = val;
                      });
                    }
                  },
                  onChangeEnd: (val) {
                    if (isCurrent) {
                      locator<AudioPlayerCubit>().seek(Duration(seconds: val.toInt()));
                      setState(() {
                        _dragValue = null;
                      });
                    }
                  },
                ),
                24.gap,
                PlayerControls(
                  scheme: cs,
                  playing: isPlaying,
                  seekIntervalSeconds: playerState.seekIntervalSeconds,
                  onPlayPause: () {
                    if (!isCurrent) {
                      locator<AudioPlayerCubit>().playEpisode(pageEpisode);
                    } else {
                      locator<AudioPlayerCubit>().togglePlayPause();
                    }
                  },
                  onSeekBackward: () {
                    if (isCurrent) locator<AudioPlayerCubit>().seekBackward();
                  },
                  onSeekForward: () {
                    if (isCurrent) locator<AudioPlayerCubit>().seekForward();
                  },
                ),
                const BottomPadding(),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _InteractiveSeekBar extends StatelessWidget {
  const _InteractiveSeekBar({required this.value, required this.max, required this.scheme, required this.onChanged, required this.onChangeEnd});

  final double value;
  final double max;
  final ColorScheme scheme;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeEnd;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = scheme;

    return SliderTheme(
      data: SliderThemeData(
        trackHeight: 10.0,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10.0, pressedElevation: 6.0),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 20.0),
        activeTrackColor: cs.primary,
        inactiveTrackColor: cs.onSurface.withValues(alpha: 0.16),
        thumbColor: cs.primary,
        overlayColor: cs.primary.withValues(alpha: 0.2),
      ),
      child: Slider(value: value.clamp(0.0, max), min: 0.0, max: max > 0 ? max : 1.0, onChanged: onChanged, onChangeEnd: onChangeEnd),
    );
  }
}
