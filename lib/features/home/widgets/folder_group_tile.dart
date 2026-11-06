import 'package:flutter/material.dart';
import 'package:podmatz/podmatz.dart';

class FolderGroupTile extends StatelessWidget {
  const FolderGroupTile({
    super.key,
    required this.groupName,
    required this.episodes,
    required this.isExpanded,
    required this.currentEpisodeFilePath,
    required this.isPlaying,
    required this.onToggle,
    required this.onEpisodeTap,
    this.onEpisodeLongPress,
    this.compact,
  });

  final String groupName;
  final List<Episode> episodes;
  final bool isExpanded;
  final String? currentEpisodeFilePath;
  final bool isPlaying;
  final VoidCallback onToggle;
  final ValueChanged<Episode> onEpisodeTap;
  final ValueChanged<Episode>? onEpisodeLongPress;
  final bool? compact;

  bool get isCompact => compact ?? locator<AudioPlayerCubit>().state.compactCards;

  BorderRadius _episodeRadius(int index, int total) {
    const Radius outer = Radius.circular(AppValues.defaultBorderRadius);
    const Radius inner = Radius.circular(AppValues.innerBorderRadius);

    if (total == 1) {
      return const BorderRadius.vertical(top: inner, bottom: outer);
    }
    if (index == 0) {
      return const BorderRadius.all(inner);
    }
    if (index == total - 1) {
      return const BorderRadius.vertical(top: inner, bottom: outer);
    }
    return const BorderRadius.all(inner);
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    final BorderRadius headerRadius = BorderRadius.vertical(
      top: const Radius.circular(AppValues.defaultBorderRadius),
      bottom: Radius.circular(isExpanded && episodes.isNotEmpty ? AppValues.innerBorderRadius : AppValues.defaultBorderRadius),
    );

    final Color normalBg = cs.surfaceContainer;
    final Color openTintBg = Color.lerp(cs.surfaceContainerHighest, cs.primaryContainer, 0.45)!;
    final Color headerBackground = isExpanded ? openTintBg : normalBg;
    final Color headerTitleColor = cs.onSurface;
    final Color headerSubtitleColor = cs.onSurfaceVariant;
    final Color iconColor = isExpanded ? cs.primary : cs.onSurfaceVariant;
    final TextTheme tt = Theme.of(context).textTheme;
    final TextStyle? titleStyle = isCompact ? tt.titleSmall : tt.titleMedium;
    final double iconBoxSize = isCompact ? AppValues.coverSizeCompact : AppValues.coverSize;
    final EdgeInsetsGeometry headerPadding = EdgeInsets.fromLTRB(16, 12, 20, 12);
    final Color folderContainer = isExpanded ? cs.primaryContainer : cs.surfaceContainerHighest;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: headerBackground,
          shape: RoundedRectangleBorder(borderRadius: headerRadius),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onToggle,
            child: Padding(
              padding: headerPadding,
              child: Row(
                children: [
                  Container(
                    width: iconBoxSize,
                    height: iconBoxSize,
                    decoration: BoxDecoration(color: folderContainer, borderRadius: BorderRadius.circular(12)),
                    child: Icon(isExpanded ? Icons.folder_open_rounded : Icons.folder_rounded, color: iconColor, size: 28),
                  ),
                  12.gap,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          groupName,
                          style: titleStyle?.copyWith(fontWeight: FontWeight.w500, color: headerTitleColor),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        2.gap,
                        Text(
                          '${episodes.length} ${episodes.length == 1 ? 'episódio' : 'episódios'}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: headerSubtitleColor, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: Icon(Icons.keyboard_arrow_down_outlined, color: iconColor, size: 24),
                  ),
                ],
              ),
            ),
          ),
        ),
        ClipRect(
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            heightFactor: isExpanded ? 1.0 : 0.0,
            child: Column(
              children: [
                for (int i = 0; i < episodes.length; i++) ...[
                  AppValues.tileGap.gap,
                  EpisodeCard(
                    episode: episodes[i],
                    playing: currentEpisodeFilePath == episodes[i].filePath,
                    isGroupFoldersView: true,
                    borderRadius: _episodeRadius(i, episodes.length),
                    compact: isCompact,
                    onTap: () => onEpisodeTap(episodes[i]),
                    onLongPress: onEpisodeLongPress != null ? () => onEpisodeLongPress!(episodes[i]) : null,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
