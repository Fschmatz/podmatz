import 'package:flutter/material.dart';
import 'package:podmatz/podmatz.dart';

class CurrentChapterCard extends StatelessWidget {
  const CurrentChapterCard({super.key, required this.scheme, required this.chaptersCount, required this.onTap, this.currentChapterTitle});

  final ColorScheme scheme;
  final int chaptersCount;
  final VoidCallback onTap;
  final String? currentChapterTitle;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = scheme;
    final TextTheme tt = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(color: cs.surfaceContainerHigh, borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            Icon(Icons.bookmarks_rounded, size: 20, color: cs.primary),
            10.gap,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Capítulo Atual',
                    style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    currentChapterTitle ?? 'Capítulos ($chaptersCount)',
                    style: tt.bodyMedium?.copyWith(color: cs.onSurface, fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
