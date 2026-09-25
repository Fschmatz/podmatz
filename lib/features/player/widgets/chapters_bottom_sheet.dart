import 'package:flutter/material.dart';
import 'package:podmatz/podmatz.dart';

class ChaptersBottomSheet extends StatelessWidget {
  const ChaptersBottomSheet({
    super.key,
    required this.episode,
    required this.currentPos,
    required this.isCurrent,
  });

  final Episode episode;
  final Duration currentPos;
  final bool isCurrent;

  static void show(
    BuildContext context,
    Episode episode,
    Duration currentPos,
    bool isCurrent,
  ) {
    final ColorScheme cs = episode.scheme(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cs.surface,
      builder: (context) {
        return ChaptersBottomSheet(
          episode: episode,
          currentPos: currentPos,
          isCurrent: isCurrent,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = episode.scheme(context);
    final TextTheme tt = Theme.of(context).textTheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              16.gap,
              Row(
                children: [
                  Icon(Icons.bookmarks_rounded, color: cs.primary),
                  10.gap,
                  Text(
                    'Capítulos (${episode.chapters.length})',
                    style: tt.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                  ),
                ],
              ),
              16.gap,
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: episode.chapters.length,
                  itemBuilder: (context, index) {
                    final Chapter chapter = episode.chapters[index];
                    final bool isActive = (index == episode.chapters.length - 1)
                        ? currentPos >= chapter.startTime
                        : (currentPos >= chapter.startTime &&
                            currentPos < episode.chapters[index + 1].startTime);

                    return ChapterTile(
                      chapter: chapter,
                      index: index,
                      isActive: isActive,
                      scheme: cs,
                      onTap: () {
                        Navigator.pop(context);
                        if (isCurrent) {
                          locator<AudioPlayerCubit>().seek(chapter.startTime);
                        } else {
                          locator<AudioPlayerCubit>().playEpisode(episode).then((_) {
                            locator<AudioPlayerCubit>().seek(chapter.startTime);
                          });
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
