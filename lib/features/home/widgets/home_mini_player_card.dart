import 'package:podmatz/podmatz.dart';
import 'package:flutter/material.dart';
import 'package:material_shapes/material_shapes.dart';

class HomeMiniPlayerCard extends StatelessWidget {
  const HomeMiniPlayerCard({
    super.key,
    required this.scheme,
    required this.channel,
    required this.title,
    required this.progress,
    required this.position,
    required this.timeLeft,
    this.totalTime,
    this.playing = false,
    this.onPlayPause,
  });

  final ColorScheme scheme;
  final String channel;
  final String title;
  final double progress;
  final Duration position;
  final Duration timeLeft;
  final Duration? totalTime;
  final bool playing;
  final VoidCallback? onPlayPause;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = scheme;
    final TextTheme tt = Theme.of(context).textTheme;

    final String posStr = position.minutesLabel;
    final String remainingStr = timeLeft.minutesLabel;
    final String totalStr = totalTime != null && totalTime!.inSeconds > 0 ? totalTime!.minutesLabel : '--:--';

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: cs.primary, borderRadius: BorderRadius.circular(20)),
      child: Stack(
        children: [
          Positioned(
            top: -30,
            right: -30,
            child: Opacity(
              opacity: 0.12,
              child: ClipPath(
                clipper: ShapeBorderClipper(shape: MaterialShapeBorder(shape: MaterialShapes.sunny)),
                child: SizedBox(width: 130, height: 130, child: ColoredBox(color: cs.onPrimary)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (channel.isNotEmpty && channel.toUpperCase() != 'PODCAST LOCAL') ...[
                        Text(
                          channel.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: tt.labelSmall?.copyWith(color: cs.onPrimary.withValues(alpha: 0.8), fontWeight: FontWeight.w600),
                        ),
                        2.gap,
                      ],
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: tt.titleMedium?.copyWith(color: cs.onPrimary, fontWeight: FontWeight.w700),
                      ),
                      4.gap,
                      Row(
                        children: [
                          Text(
                            '$posStr / $totalStr',
                            style: tt.bodySmall?.copyWith(color: cs.onPrimary, fontWeight: FontWeight.w600),
                          ),
                          8.gap,
                          Text(
                            '•   Faltam $remainingStr',
                            style: tt.bodySmall?.copyWith(color: cs.onPrimary.withValues(alpha: 0.8), fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                12.gap,
                Material(
                  color: cs.onPrimary,
                  shape: MaterialShapeBorder(shape: ShapeValues.heroButtonShape),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: onPlayPause,
                    child: SizedBox(
                      width: 50,
                      height: 50,
                      child: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded, color: cs.primary, size: 24),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
