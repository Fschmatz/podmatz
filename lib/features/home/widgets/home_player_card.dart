import 'package:podmatz/podmatz.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:material_shapes/material_shapes.dart';

class HomePlayerCard extends StatelessWidget {
  const HomePlayerCard({
    super.key,
    required this.scheme,
    required this.imageUrl,
    this.imageBytes,
    required this.channel,
    required this.title,
    required this.progress,
    required this.position,
    required this.timeLeft,
    this.totalTime,
    required this.coverShape,
    this.playing = false,
    this.onPlayPause,
  });

  final ColorScheme scheme;
  final String imageUrl;
  final Uint8List? imageBytes;
  final String channel;
  final String title;
  final double progress;
  final Duration position;
  final Duration timeLeft;
  final Duration? totalTime;
  final RoundedPolygon coverShape;
  final bool playing;
  final VoidCallback? onPlayPause;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = scheme;
    final TextTheme tt = Theme.of(context).textTheme;

    final String posStr = position.remainingLabel;
    final String remainingStr = timeLeft.remainingLabel;
    final String totalStr = totalTime != null && totalTime!.inSeconds > 0 ? totalTime!.remainingLabel : '--:--';

    return Container(
      clipBehavior: .antiAlias,
      decoration: BoxDecoration(color: cs.primary, borderRadius: .circular(36)),
      child: Stack(
        children: [
          Positioned(
            top: -44,
            right: -44,
            child: Opacity(
              opacity: 0.12,
              child: ClipPath(
                clipper: ShapeBorderClipper(shape: MaterialShapeBorder(shape: MaterialShapes.sunny)),
                child: SizedBox(width: 180, height: 180, child: ColoredBox(color: cs.onPrimary)),
              ),
            ),
          ),
          Padding(
            padding: const .all(24),
            child: Column(
              mainAxisSize: .min,
              crossAxisAlignment: .start,
              children: [
                Column(
                  mainAxisSize: .min,
                  crossAxisAlignment: .start,
                  children: [
                    if (channel.isNotEmpty && channel.toUpperCase() != 'PODCAST LOCAL')
                      Row(
                        children: [
                          ClipPath(
                            clipper: ShapeBorderClipper(shape: MaterialShapeBorder(shape: coverShape)),
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: _Cover(imageUrl: imageUrl, imageBytes: imageBytes, scheme: cs),
                            ),
                          ),
                          8.gap,
                          Text(
                            channel.toUpperCase(),
                            style: tt.labelSmall?.copyWith(color: cs.onPrimary.withValues(alpha: 0.85), fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    4.gap,
                    Text(
                      title,
                      maxLines: 2,
                      overflow: .ellipsis,
                      style: tt.headlineSmall?.copyWith(color: cs.onPrimary, fontWeight: .w800),
                    ),
                  ],
                ),
                16.gap,
                Row(
                  crossAxisAlignment: .center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: .start,
                        children: [
                          Text(
                            '$posStr / $totalStr',
                            style: tt.titleMedium?.copyWith(color: cs.onPrimary, fontWeight: FontWeight.bold),
                          ),
                          4.gap,
                          Text(
                            'Faltam $remainingStr',
                            style: tt.labelMedium?.copyWith(color: cs.onPrimary.withValues(alpha: 0.8), fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    16.gap,
                    Material(
                      color: cs.onPrimary,
                      shape: MaterialShapeBorder(shape: _heroButtonShapes[_kHeroButtonShape]),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: onPlayPause,
                        child: SizedBox(
                          width: 64,
                          height: 64,
                          child: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded, color: cs.primary, size: 32),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

final List<RoundedPolygon> _heroButtonShapes = <RoundedPolygon>[
  MaterialShapes.cookie7Sided,
  MaterialShapes.clover4Leaf,
  MaterialShapes.pentagon,
  MaterialShapes.gem,
  MaterialShapes.puffy,
  MaterialShapes.sunny,
  MaterialShapes.flower,
];
const int _kHeroButtonShape = 0;

class _Cover extends StatelessWidget {
  const _Cover({required this.imageUrl, this.imageBytes, required this.scheme});

  final String imageUrl;
  final Uint8List? imageBytes;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return SmoothImage(
      url: imageUrl,
      imageBytes: imageBytes,
      placeholderColor: scheme.primaryContainer,
      placeholderChild: Icon(Icons.podcasts_rounded, color: scheme.onPrimaryContainer),
      errorChild: Icon(Icons.podcasts_rounded, color: scheme.onPrimaryContainer),
    );
  }
}
