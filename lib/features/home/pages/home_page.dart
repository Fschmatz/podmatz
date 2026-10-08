import 'package:podmatz/podmatz.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? _openGroupName;
  final ScrollController _scrollController = ScrollController();
  double? _lockedScrollOffset;
  bool _suppressScrollLock = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  /// Keeps the scroll position locked while a group is animating open/closed.
  /// Prevents ListView from drifting when item heights change mid-layout.
  void _onScroll() {
    if (_lockedScrollOffset == null || !_scrollController.hasClients || _suppressScrollLock) return;
    final target = _lockedScrollOffset!;
    if ((_scrollController.offset - target).abs() > 0.5) {
      _suppressScrollLock = true;
      _scrollController.jumpTo(target.clamp(_scrollController.position.minScrollExtent, _scrollController.position.maxScrollExtent));
      _suppressScrollLock = false;
    }
  }

  void _toggleGroup(String groupName) {
    final isExpanded = _openGroupName == groupName;
    // Lock the scroll at the current position before the expansion
    _lockedScrollOffset = _scrollController.hasClients ? _scrollController.offset : null;
    setState(() => _openGroupName = isExpanded ? null : groupName);
    // Release the lock after the animation finishes
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) _lockedScrollOffset = null;
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _openPlayer(BuildContext context, Episode episode) {
    Navigator.of(context).push(PlayerPage.route(episode));
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    return BlocBuilder<AudioPlayerCubit, AudioPlayerState>(
      bloc: locator<AudioPlayerCubit>(),
      builder: (context, state) {
        final List<Episode> episodes = [...state.episodes]..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
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

        // Group episodes by folder/channel
        final Map<String, List<Episode>> groupedEpisodes = {};
        for (final ep in episodes) {
          final groupName = ep.channel.isNotEmpty ? ep.channel : AppValues.nomePastaRaiz;
          groupedEpisodes.putIfAbsent(groupName, () => []).add(ep);
        }

        // Sort groups: named folders first, nomePastaRaiz last
        final sortedGroupKeys = groupedEpisodes.keys.toList()
          ..sort((a, b) {
            if (a == AppValues.nomePastaRaiz) return 1;
            if (b == AppValues.nomePastaRaiz) return -1;
            return a.compareTo(b);
          });

        return Scaffold(
          backgroundColor: cs.surface,
          appBar: const HomeAppBar(),
          body: Column(
            children: [
              if (playing != null)
                Builder(
                  builder: (context) {
                    final bool isCurrentCard = state.currentEpisode?.filePath == playing.filePath;
                    final Duration currentPos = isCurrentCard && state.position.inSeconds > 0 ? state.position : playing.listened;
                    final Duration totalDur = isCurrentCard && state.duration.inSeconds > 0 ? state.duration : playing.total;
                    final Duration remaining = totalDur > currentPos ? totalDur - currentPos : Duration.zero;
                    final double cardProgress = totalDur.inSeconds > 0 ? (currentPos.inSeconds / totalDur.inSeconds).clamp(0.0, 1.0) : 0.0;

                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: GestureDetector(
                        onTap: () => _openPlayer(context, playing),
                        child: state.useMiniPlayerOnHome
                            ? HomeMiniPlayerCard(
                                scheme: playing.scheme(context),
                                channel: playing.channel,
                                title: playing.title,
                                progress: cardProgress,
                                position: currentPos,
                                timeLeft: remaining,
                                totalTime: totalDur,
                                playing: state.isPlaying && state.currentEpisode?.filePath == playing.filePath,
                                onPlayPause: () {
                                  locator<AudioPlayerCubit>().playEpisode(playing);
                                },
                              )
                            : HomePlayerCard(
                                scheme: playing.scheme(context),
                                imageUrl: playing.image,
                                imageBytes: playing.imageBytes,
                                channel: playing.channel,
                                title: playing.title,
                                progress: cardProgress,
                                position: currentPos,
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
                child: !state.groupFoldersView
                    ? ListView.builder(
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
                              showProgress: state.showCardProgress,
                              onTap: () {
                                _openPlayer(context, ep);
                              },
                            ),
                          );
                        },
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        scrollCacheExtent: ScrollCacheExtent.pixels(600.0),
                        padding: EdgeInsets.fromLTRB(16, 0, 16, BottomPadding.of(context) + 16),
                        itemCount: sortedGroupKeys.length,
                        itemBuilder: (context, groupIndex) {
                          final groupName = sortedGroupKeys[groupIndex];
                          final groupList = [...groupedEpisodes[groupName]!]..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
                          final bool isExpanded = _openGroupName == groupName;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: FolderGroupTile(
                              groupName: groupName,
                              episodes: groupList,
                              isExpanded: isExpanded,
                              currentEpisodeFilePath: state.currentEpisode?.filePath,
                              isPlaying: state.isPlaying,
                              showCardProgress: state.showCardProgress,
                              onToggle: () => _toggleGroup(groupName),
                              onEpisodeTap: (ep) => _openPlayer(context, ep),
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
