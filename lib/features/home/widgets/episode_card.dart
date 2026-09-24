import 'package:podmatz/podmatz.dart';
import 'package:flutter/material.dart';
import 'package:material_shapes/material_shapes.dart';
import 'package:motor/motor.dart';

class EpisodeCard extends StatefulWidget {
  const EpisodeCard({super.key, required this.episode, required this.playing, required this.onTap});

  final Episode episode;
  final bool playing;
  final VoidCallback onTap;

  @override
  State<EpisodeCard> createState() => _EpisodeCardState();
}

class _EpisodeCardState extends State<EpisodeCard> {
  @override
  Widget build(BuildContext context) {
    final Episode episode = widget.episode;
    final bool playing = widget.playing;
    final ColorScheme cs = episode.scheme(context);
    final double progress = episode.progress;

    //final Color fill = cs.primary;
    //final Color onFill = cs.onPrimary;
    final Color fill = cs.secondaryContainer;
    final Color onFill = cs.onSecondaryContainer;

    return SingleMotionBuilder(
      motion: const MaterialSpringMotion.standardSpatialFast(),
      value: playing ? 1.0 : 0.0,
      builder: (context, t, child) {
        final double radius = 24 + (40 - 24) * t;
        return Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(color: cs.surfaceContainerHigh, borderRadius: BorderRadius.circular(radius < 0 ? 0 : radius)),
          child: child,
        );
      },
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRect(
              clipper: _FillClipper(start: _kFillStart, fraction: progress),
              child: ColoredBox(color: fill),
            ),
          ),
          _content(context, cs, cs.onSurface),
          Positioned.fill(
            child: ClipRect(
              clipper: _FillClipper(start: _kFillStart, fraction: progress),
              child: _content(context, cs, onFill),
            ),
          ),
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(onTap: widget.onTap),
            ),
          ),
        ],
      ),
    );
  }

  Widget _trailing(BuildContext context, ColorScheme cs, Color fg) {
    final Episode episode = widget.episode;

    if (episode.progress >= 1.0) {
      return Container(
        width: 30,
        height: 30,
        decoration: ShapeDecoration(
          color: fg,
          shape: MaterialShapeBorder(shape: MaterialShapes.cookie7Sided),
        ),
        child: Icon(Icons.check_rounded, size: 18, color: cs.primary),
      );
    }

    final bool started = episode.listened > Duration.zero;
    final Duration remaining = episode.total - episode.listened;

    return Text(
      started ? '-${remaining.remainingLabel}' : remaining.remainingLabel,
      style: TextStyle(color: fg, fontSize: 15, fontWeight: FontWeight.w600, fontFeatures: const [FontFeature.tabularFigures()]),
    );
  }

  Widget _content(BuildContext context, ColorScheme cs, Color fg) {
    final Episode episode = widget.episode;
    final TextTheme tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          SingleMotionBuilder(
            motion: const MaterialSpringMotion.standardSpatialFast(),
            value: widget.playing ? 1.0 : 0.0,
            builder: (context, t, child) => ClipPath(
              clipper: ShapeBorderClipper(shape: ShapeValues.coverBorder(t)),
              child: child,
            ),
            child: SizedBox(
              width: 56,
              height: 56,
              child: _Cover(episode: episode, scheme: cs),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (episode.channel.isNotEmpty && episode.channel.toUpperCase() != 'PODCAST LOCAL') ...[
                  Text(
                    episode.channel.toUpperCase(),
                    style: tt.labelSmall?.copyWith(color: fg, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                ],
                Text(
                  episode.title,
                  style: tt.titleMedium?.copyWith(color: fg, fontWeight: FontWeight.w700),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          _trailing(context, cs, fg),
        ],
      ),
    );
  }
}

const double _kFillStart = 0;

class _FillClipper extends CustomClipper<Rect> {
  const _FillClipper({required this.start, required this.fraction});

  final double start;
  final double fraction;

  @override
  Rect getClip(Size size) => Rect.fromLTWH(start, 0, (size.width - start) * fraction, size.height);

  @override
  bool shouldReclip(_FillClipper oldClipper) => oldClipper.start != start || oldClipper.fraction != fraction;
}

class _Cover extends StatelessWidget {
  const _Cover({required this.episode, required this.scheme});

  final Episode episode;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return SmoothImage(
      url: episode.image,
      imageBytes: episode.imageBytes,
      placeholderColor: scheme.primaryContainer,
      placeholderChild: Icon(Icons.podcasts_rounded, color: scheme.onPrimaryContainer),
      errorChild: Icon(Icons.podcasts_rounded, color: scheme.onPrimaryContainer),
    );
  }
}
