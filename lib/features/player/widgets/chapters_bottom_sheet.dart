import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:podmatz/podmatz.dart';

class ChaptersBottomSheet extends StatelessWidget {
  const ChaptersBottomSheet({super.key, required this.episode, required this.currentPos, required this.isCurrent});

  final Episode episode;
  final Duration currentPos;
  final bool isCurrent;

  static void show(BuildContext context, Episode episode, Duration currentPos, bool isCurrent) {
    final ColorScheme cs = episode.scheme(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cs.surfaceContainerHigh,
      builder: (context) {
        return ChaptersBottomSheet(episode: episode, currentPos: currentPos, isCurrent: isCurrent);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme tt = Theme.of(context).textTheme;

    return BlocBuilder<AudioPlayerCubit, AudioPlayerState>(
      bloc: locator<AudioPlayerCubit>(),
      builder: (context, playerState) {
        final activeEpisode = playerState.episodes.firstWhere(
          (ep) => ep.filePath == episode.filePath,
          orElse: () => playerState.currentEpisode?.filePath == episode.filePath ? playerState.currentEpisode! : episode,
        );
        final ColorScheme cs = activeEpisode.scheme(context);

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
                        'Capítulos (${activeEpisode.chapters.length})',
                        style: tt.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: cs.onSurface),
                      ),
                    ],
                  ),
                  16.gap,
                  Expanded(
                    child: activeEpisode.chapters.isEmpty
                        ? Center(
                            child: Text(
                              'Nenhum capítulo cadastrado.',
                              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                            ),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            itemCount: activeEpisode.chapters.length,
                            itemBuilder: (context, index) {
                              final Chapter chapter = activeEpisode.chapters[index];
                              final bool isActive = (index == activeEpisode.chapters.length - 1)
                                  ? currentPos >= chapter.startTime
                                  : (currentPos >= chapter.startTime && currentPos < activeEpisode.chapters[index + 1].startTime);

                              return ChapterTile(
                                chapter: chapter,
                                index: index,
                                isActive: isActive,
                                scheme: cs,
                                onEdit: () {
                                  AddChapterDialog.show(
                                    context,
                                    episode: activeEpisode,
                                    initialTime: chapter.startTime,
                                    initialChapter: chapter,
                                  );
                                },
                                onDelete: () {
                                  locator<AudioPlayerCubit>().deleteChapter(
                                    episode: activeEpisode,
                                    chapter: chapter,
                                  );
                                },
                                onTap: () {
                                  Navigator.pop(context);
                                  if (isCurrent) {
                                    locator<AudioPlayerCubit>().seek(chapter.startTime);
                                  } else {
                                    locator<AudioPlayerCubit>().playEpisode(activeEpisode).then((_) {
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
      },
    );
  }
}
