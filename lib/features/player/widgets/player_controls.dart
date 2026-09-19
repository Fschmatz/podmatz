import 'package:podmatz/podmatz.dart';
import 'package:flutter/material.dart';

class PlayerControls extends StatelessWidget {
  const PlayerControls({
    super.key,
    required this.scheme,
    required this.playing,
    required this.onPlayPause,
    this.fav = false,
    this.onFav,
    this.onSeekForward,
    this.onSeekBackward,
    this.seekIntervalSeconds = 15,
  });

  final ColorScheme scheme;
  final bool playing;
  final bool fav;
  final VoidCallback onPlayPause;
  final VoidCallback? onFav;
  final VoidCallback? onSeekForward;
  final VoidCallback? onSeekBackward;
  final int seekIntervalSeconds;

  static const double _heroGap = 8;
  static const double _innerGap = 6;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = scheme;
    final Color tonal = cs.surfaceContainerHighest;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double heroSide = (constraints.maxWidth - _heroGap) / 2;

        return SizedBox(
          height: heroSide,
          child: Row(
            children: [
              SizedBox(
                width: heroSide,
                height: heroSide,
                child: PlayButton(playing: playing, color: cs.onSurface, foreground: cs.surface, onTap: onPlayPause),
              ),
              _heroGap.gap,
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: heroSide,
                        child: SeekButton(
                          forward: false,
                          color: tonal,
                          iconColor: cs.onSurface,
                          intervalSeconds: seekIntervalSeconds,
                          onTap: onSeekBackward ?? () {},
                        ),
                      ),
                    ),
                    const SizedBox(width: _innerGap),
                    Expanded(
                      child: SizedBox(
                        height: heroSide,
                        child: SeekButton(
                          forward: true,
                          color: tonal,
                          iconColor: cs.onSurface,
                          intervalSeconds: seekIntervalSeconds,
                          onTap: onSeekForward ?? () {},
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
