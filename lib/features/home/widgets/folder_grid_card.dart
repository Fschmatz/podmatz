import 'package:flutter/material.dart';
import 'package:podmatz/podmatz.dart';

class FolderGridCard extends StatelessWidget {
  const FolderGridCard({super.key, required this.groupName, required this.episodeCount, required this.isSelected, required this.onTap, this.compact});

  final String groupName;
  final int episodeCount;
  final bool isSelected;
  final VoidCallback onTap;
  final bool? compact;

  bool get isCompact => compact ?? locator<AudioPlayerCubit>().state.compactCards;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final TextTheme tt = Theme.of(context).textTheme;

    final Color normalBg = cs.surfaceContainer;
    final Color openTintBg = Color.lerp(cs.surfaceContainerHighest, cs.primaryContainer, 0.45)!;
    final Color cardBg = isSelected ? openTintBg : normalBg;

    final Color folderContainer = isSelected ? cs.primaryContainer : cs.surfaceContainerHighest;
    final Color iconColor = isSelected ? cs.primary : cs.onSurfaceVariant;
    final Color titleColor = cs.onSurface;
    final Color subtitleColor = cs.onSurfaceVariant;

    final double iconBoxSize = isCompact ? 36 : 42;
    final double iconSize = isCompact ? 20 : 24;
    final TextStyle? titleStyle = isCompact ? tt.labelLarge : tt.titleSmall;

    return Material(
      color: cardBg,
      borderRadius: BorderRadius.circular(AppValues.defaultBorderRadius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: iconBoxSize,
                height: iconBoxSize,
                decoration: BoxDecoration(color: folderContainer, borderRadius: BorderRadius.circular(12)),
                child: Icon(isSelected ? Icons.folder_open_rounded : Icons.folder_rounded, color: iconColor, size: iconSize),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      groupName,
                      style: titleStyle?.copyWith(fontWeight: FontWeight.w600, color: titleColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$episodeCount ${episodeCount == 1 ? 'episódio' : 'episódios'}',
                      style: tt.bodySmall?.copyWith(color: subtitleColor, fontWeight: FontWeight.w700, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
