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
    required this.showCardProgress,
    required this.onToggle,
    required this.onEpisodeTap,
  });

  final String groupName;
  final List<Episode> episodes;
  final bool isExpanded;
  final String? currentEpisodeFilePath;
  final bool isPlaying;
  final bool showCardProgress;
  final VoidCallback onToggle;
  final ValueChanged<Episode> onEpisodeTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isExpanded ? Icons.folder_open_rounded : Icons.folder_rounded,
                      color: cs.onPrimaryContainer,
                      size: 22,
                    ),
                  ),
                  12.gap,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          groupName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: cs.onSurface,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${episodes.length} ${episodes.length == 1 ? 'episódio' : 'episódios'}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: Icon(Icons.keyboard_arrow_down_rounded, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
          ClipRect(
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              heightFactor: isExpanded ? 1.0 : 0.0,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: Column(
                  children: episodes.map((ep) {
                    final bool isCurrent = currentEpisodeFilePath == ep.filePath;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: EpisodeCard(
                        episode: ep,
                        playing: isCurrent && isPlaying,
                        showProgress: showCardProgress,
                        onTap: () => onEpisodeTap(ep),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
