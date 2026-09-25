import 'package:flutter/material.dart';
import 'package:podmatz/podmatz.dart';

class ChapterTile extends StatelessWidget {
  const ChapterTile({super.key, required this.chapter, required this.index, required this.isActive, required this.scheme, required this.onTap});

  final Chapter chapter;
  final int index;
  final bool isActive;
  final ColorScheme scheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = scheme;
    final TextTheme tt = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: isActive ? cs.primaryContainer : cs.surfaceContainer, borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(color: isActive ? cs.primary : cs.surfaceContainerHigh, shape: BoxShape.circle),
          child: Center(
            child: Text(
              '${index + 1}',
              style: TextStyle(color: isActive ? cs.onPrimary : cs.onSurface, fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ),
        title: Text(
          chapter.title,
          style: tt.bodyMedium?.copyWith(
            fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
            color: isActive ? cs.onPrimaryContainer : cs.onSurface,
          ),
        ),
        subtitle: Text(
          chapter.startTime.minutesLabel,
          style: tt.bodySmall?.copyWith(color: isActive ? cs.onPrimaryContainer.withValues(alpha: 0.8) : cs.onSurfaceVariant),
        ),
        trailing: isActive ? Icon(Icons.play_circle_filled_rounded, color: cs.primary) : Icon(Icons.play_arrow_rounded, color: cs.onSurfaceVariant),
        onTap: onTap,
      ),
    );
  }
}
