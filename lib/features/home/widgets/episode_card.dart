import 'package:podmatz/podmatz.dart';
import 'package:flutter/material.dart';
import 'package:motor/motor.dart';

class EpisodeCard extends StatefulWidget {
  const EpisodeCard({
    super.key,
    required this.episode,
    required this.playing,
    required this.onTap,
    this.onLongPress,
    required this.isGroupFoldersView,
    this.borderRadius,
    this.compact,
  });

  final Episode episode;
  final bool playing;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool isGroupFoldersView;
  final BorderRadius? borderRadius;
  final bool? compact;

  bool get isCompact => compact ?? locator<AudioPlayerCubit>().state.compactCards;

  @override
  State<EpisodeCard> createState() => _EpisodeCardState();
}

class _EpisodeCardState extends State<EpisodeCard> {
  @override
  Widget build(BuildContext context) {
    final Episode episode = widget.episode;
    final ColorScheme cs = episode.scheme(context);
    final bool showCover = locator<AudioPlayerCubit>().state.showEpisodeCover;
    final BorderRadius effectiveRadius = widget.borderRadius ?? BorderRadius.circular(AppValues.defaultBorderRadius);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: cs.surfaceContainerHighest, borderRadius: effectiveRadius),
      child: Stack(
        children: [
          _content(context, cs, cs.onSurface, showCover),

          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(onTap: widget.onTap, onLongPress: widget.onLongPress),
            ),
          ),
        ],
      ),
    );
  }

  Widget _content(BuildContext context, ColorScheme cs, Color fg, bool showCover) {
    final Episode episode = widget.episode;
    final TextTheme tt = Theme.of(context).textTheme;
    final int titleMaxLines = widget.isCompact ? 1 : 2;
    final TextStyle? titleStyle = widget.isCompact ? tt.titleSmall : tt.titleMedium;
    final double coverSize = widget.isCompact ? AppValues.coverSizeCompact : AppValues.coverSize;
    final EdgeInsetsGeometry cardPadding = EdgeInsets.fromLTRB(16, 12, 16, 12);

    return Padding(
      padding: cardPadding,
      child: Row(
        children: [
          if (showCover) ...[
            SingleMotionBuilder(
              motion: const MaterialSpringMotion.standardSpatialFast(),
              value: widget.playing ? 1.0 : 0.0,
              builder: (context, t, child) => ClipPath(
                clipper: ShapeBorderClipper(shape: ShapeValues.coverBorder(t)),
                child: child,
              ),
              child: SizedBox(
                width: coverSize,
                height: coverSize,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _Cover(episode: episode, scheme: cs),
                    if (widget.playing)
                      Container(
                        color: Colors.black.withValues(alpha: 0.35),
                        child: Center(child: Icon(Icons.play_arrow_rounded, color: cs.primary, size: 32)),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  episode.title,
                  style: titleStyle?.copyWith(color: fg, fontWeight: FontWeight.w500),
                  maxLines: titleMaxLines,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Builder(
                  builder: (_) {
                    final String totalStr = episode.total.inSeconds > 0 ? episode.total.minutesLabel : '--:--';
                    final bool hasStarted = episode.listened.inMinutes >= 1;
                    final String timeText = hasStarted ? '${episode.listened.minutesLabel} / $totalStr' : totalStr;

                    return Text(
                      timeText,
                      style: tt.bodySmall?.copyWith(color: fg.withValues(alpha: 0.5), fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
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
      placeholderColor: scheme.secondaryContainer,
      placeholderChild: Icon(Icons.podcasts_rounded, color: scheme.onSecondaryContainer),
      errorChild: Icon(Icons.podcasts_rounded, color: scheme.onSecondaryContainer),
    );
  }
}
