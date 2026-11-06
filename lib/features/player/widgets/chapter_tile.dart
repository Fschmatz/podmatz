import 'package:flutter/material.dart';
import 'package:podmatz/podmatz.dart';

class ChapterTile extends StatelessWidget {
  const ChapterTile({
    super.key,
    required this.chapter,
    required this.index,
    required this.isActive,
    required this.scheme,
    required this.onTap,
    this.onEdit,
    this.onDelete,
  });

  final Chapter chapter;
  final int index;
  final bool isActive;
  final ColorScheme scheme;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = scheme;
    final TextTheme tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isActive ? cs.primaryContainer : cs.surfaceContainer,
        borderRadius: BorderRadius.circular(AppValues.defaultBorderRadius),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          contentPadding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppValues.defaultBorderRadius)),
          dense: true,
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: isActive ? cs.primary : cs.surfaceContainerHighest, shape: BoxShape.circle),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(color: isActive ? cs.onPrimary : cs.onSurface, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
          title: Text(
            chapter.title,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: tt.bodyMedium?.copyWith(
              fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
              color: isActive ? cs.onPrimaryContainer : cs.onSurface,
            ),
          ),
          subtitle: Text(
            chapter.startTime.minutesLabel,
            style: tt.bodySmall?.copyWith(color: isActive ? cs.onPrimaryContainer.withValues(alpha: 0.8) : cs.onSurfaceVariant),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (onEdit != null || onDelete != null)
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert_rounded, size: 20, color: isActive ? cs.onPrimaryContainer : cs.onSurfaceVariant),
                  onSelected: (value) {
                    if (value == 'edit' && onEdit != null) {
                      onEdit!();
                    } else if (value == 'delete' && onDelete != null) {
                      onDelete!();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(children: [Icon(Icons.edit_outlined, size: 20), SizedBox(width: 8), Text('Editar')]),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(children: [Icon(Icons.delete_outline_rounded, size: 20), SizedBox(width: 8), Text('Excluir')]),
                    ),
                  ],
                ),
            ],
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}
