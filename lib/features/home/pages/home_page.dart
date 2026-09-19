import 'package:podmatz/podmatz.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void _openPlayer(BuildContext context, Episode episode) {
    Navigator.of(context).push(PlayerPage.route(episode));
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    return BlocBuilder<AudioPlayerCubit, AudioPlayerState>(
      bloc: locator<AudioPlayerCubit>(),
      builder: (context, state) {
        final List<Episode> episodes = state.episodes;
        final Episode? playing = state.currentEpisode ?? (episodes.isNotEmpty ? episodes.first : null);

        if (state.isLoading) {
          return Scaffold(
            backgroundColor: cs.surface,
            appBar: const HomeAppBar(),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (state.folderPath == null || episodes.isEmpty) {
          return Scaffold(
            backgroundColor: cs.surface,
            appBar: const HomeAppBar(),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.folder_open_rounded, size: 72, color: cs.primary),
                    16.gap,
                    Text(
                      state.folderPath == null ? 'Nenhuma pasta selecionada' : 'Nenhum podcast encontrado nesta pasta',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    8.gap,
                    Text(
                      'Selecione a pasta do seu dispositivo onde estão salvos os podcasts.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                    ),
                    24.gap,
                    FilledButton.icon(
                      onPressed: () {
                        locator<AudioPlayerCubit>().pickFolder();
                      },
                      icon: const Icon(Icons.folder_open_rounded),
                      label: const Text('Selecionar Pasta de Podcasts'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: cs.surface,
          appBar: const HomeAppBar(),
          body: Column(
            children: [
              if (playing != null)
                Builder(
                  builder: (context) {
                    final Duration totalDur = state.duration.inSeconds > 0 ? state.duration : playing.total;
                    final Duration remaining = totalDur > state.position ? totalDur - state.position : Duration.zero;
                    final double cardProgress = totalDur.inSeconds > 0 ? (state.position.inSeconds / totalDur.inSeconds).clamp(0.0, 1.0) : 0.0;

                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      child: GestureDetector(
                        onTap: () => _openPlayer(context, playing),
                        child: HomePlayerCard(
                          scheme: playing.scheme(context),
                          imageUrl: playing.image,
                          imageBytes: playing.imageBytes,
                          channel: playing.channel,
                          title: playing.title,
                          progress: cardProgress,
                          timeLeft: remaining,
                          totalTime: totalDur,
                          coverShape: ShapeValues.coverFocused,
                          playing: state.isPlaying && state.currentEpisode?.filePath == playing.filePath,
                          onPlayPause: () {
                            locator<AudioPlayerCubit>().playEpisode(playing);
                          },
                        ),
                      ),
                    );
                  },
                ),

              Expanded(
                child: ListView.builder(
                  scrollCacheExtent: ScrollCacheExtent.pixels(600.0),
                  padding: EdgeInsets.fromLTRB(16, 0, 16, BottomPadding.of(context) + 16),
                  itemCount: episodes.length,
                  itemBuilder: (context, index) {
                    final Episode ep = episodes[index];
                    final bool isCurrent = state.currentEpisode?.filePath == ep.filePath;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: EpisodeCard(
                        episode: ep,
                        playing: isCurrent && state.isPlaying,
                        onTap: () {
                          _openPlayer(context, ep);
                        },
                      ),
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
