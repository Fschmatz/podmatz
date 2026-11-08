import 'package:permission_handler/permission_handler.dart';
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
  String? _lastClosingGroupName;
  final Map<String, List<Episode>> _lastGroupEpisodes = {};
  final ScrollController _scrollController = ScrollController();
  double? _lockedScrollOffset;
  bool _suppressScrollLock = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Permission.notification.request();
    });
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
    setState(() {
      if (isExpanded) {
        _lastClosingGroupName = groupName;
        _openGroupName = null;
      } else {
        _lastClosingGroupName = _openGroupName;
        _openGroupName = groupName;
      }
    });
    // Release the lock after the animation finishes
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) {
        _lockedScrollOffset = null;
        if (_lastClosingGroupName != null) {
          setState(() => _lastClosingGroupName = null);
        }
      }
    });
  }

  BorderRadius _episodeRadius(int index, int total) {
    const Radius outer = Radius.circular(AppValues.defaultBorderRadius);
    const Radius inner = Radius.circular(AppValues.innerBorderRadius);

    if (total == 1) {
      return const BorderRadius.all(outer);
    }
    if (index == 0) {
      return const BorderRadius.vertical(top: outer, bottom: inner);
    }
    if (index == total - 1) {
      return const BorderRadius.vertical(top: inner, bottom: outer);
    }
    return const BorderRadius.all(inner);
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

  void _onEpisodeLongPress(Episode episode) {
    final cubit = locator<AudioPlayerCubit>();
    final isCurrent = cubit.state.currentEpisode?.filePath == episode.filePath;
    if (isCurrent) {
      cubit.togglePlayPause();
    } else {
      cubit.playEpisode(episode);
    }
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

        return Scaffold(
          backgroundColor: cs.surface,
          appBar: const HomeAppBar(),
          body: Stack(
            children: [
              BlocBuilder<AudioPlayerCubit, AudioPlayerState>(
                bloc: locator<AudioPlayerCubit>(),
                buildWhen: (prev, curr) =>
                    prev.episodes != curr.episodes ||
                    prev.groupFoldersView != curr.groupFoldersView ||
                    prev.isPlaying != curr.isPlaying ||
                    prev.currentEpisode?.filePath != curr.currentEpisode?.filePath,
                builder: (context, listState) {
                  final List<Episode> listEpisodes = [...listState.episodes]..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));

                  final bool hasPlayer = listState.currentEpisode != null || listEpisodes.isNotEmpty;
                  final double listBottomPadding = BottomPadding.of(context) + (hasPlayer ? 136 : 16);

                  if (!listState.groupFoldersView) {
                    return ListView.builder(
                      scrollCacheExtent: ScrollCacheExtent.pixels(600.0),
                      padding: EdgeInsets.fromLTRB(16, 0, 16, listBottomPadding),
                      itemCount: listEpisodes.length,
                      itemBuilder: (context, index) {
                        final Episode ep = listEpisodes[index];
                        final bool isCurrent = listState.currentEpisode?.filePath == ep.filePath;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: EpisodeCard(
                            episode: ep,
                            playing: isCurrent,
                            isGroupFoldersView: false,
                            onTap: () => _openPlayer(context, ep),
                            onLongPress: () => _onEpisodeLongPress(ep),
                          ),
                        );
                      },
                    );
                  }

                  final Map<String, List<Episode>> groupedEpisodes = {};
                  for (final ep in listEpisodes) {
                    final groupName = ep.channel.isNotEmpty ? ep.channel : AppValues.rootFolderName;
                    groupedEpisodes.putIfAbsent(groupName, () => []).add(ep);
                  }
                  final sortedGroupKeys = groupedEpisodes.keys.toList()
                    ..sort((a, b) {
                      if (a == AppValues.rootFolderName) return 1;
                      if (b == AppValues.rootFolderName) return -1;
                      return a.compareTo(b);
                    });

                  final List<List<String>> folderRows = [];
                  for (int i = 0; i < sortedGroupKeys.length; i += 2) {
                    folderRows.add(sortedGroupKeys.sublist(i, (i + 2 > sortedGroupKeys.length) ? sortedGroupKeys.length : i + 2));
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    scrollCacheExtent: ScrollCacheExtent.pixels(600.0),
                    padding: EdgeInsets.fromLTRB(16, 0, 16, listBottomPadding),
                    itemCount: folderRows.length,
                    itemBuilder: (context, rowIndex) {
                      final row = folderRows[rowIndex];
                      final firstFolder = row[0];
                      final secondFolder = row.length > 1 ? row[1] : null;

                      final bool isFirstExpanded = _openGroupName == firstFolder;
                      final bool isSecondExpanded = secondFolder != null && _openGroupName == secondFolder;
                      final bool isRowExpanded = isFirstExpanded || isSecondExpanded;

                      final bool isFirstClosing = _lastClosingGroupName == firstFolder;
                      final bool isSecondClosing = secondFolder != null && _lastClosingGroupName == secondFolder;

                      // Mantém em cache a lista de episódios da pasta da linha para animar suavemente ao fechar
                      for (final f in [firstFolder, ?secondFolder]) {
                        if (groupedEpisodes[f] != null) {
                          _lastGroupEpisodes[f] = [...groupedEpisodes[f]!]..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
                        }
                      }

                      // Se a linha estiver aberta, usa a pasta aberta.
                      // Se estiver fechando esta linha, usa a pasta que estava aberta nesta linha.
                      final String? activeFolder = isFirstExpanded
                          ? firstFolder
                          : (isSecondExpanded ? secondFolder : (isFirstClosing ? firstFolder : (isSecondClosing ? secondFolder : null)));

                      final List<Episode> displayEpisodes = (activeFolder != null ? _lastGroupEpisodes[activeFolder] : null) ?? const [];

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: FolderGridCard(
                                    groupName: firstFolder,
                                    episodeCount: groupedEpisodes[firstFolder]?.length ?? 0,
                                    isSelected: isFirstExpanded,
                                    onTap: () => _toggleGroup(firstFolder),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: secondFolder != null
                                      ? FolderGridCard(
                                          groupName: secondFolder,
                                          episodeCount: groupedEpisodes[secondFolder]?.length ?? 0,
                                          isSelected: isSecondExpanded,
                                          onTap: () => _toggleGroup(secondFolder),
                                        )
                                      : const SizedBox.shrink(),
                                ),
                              ],
                            ),
                            ClipRect(
                              child: AnimatedAlign(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                                alignment: Alignment.topCenter,
                                heightFactor: isRowExpanded ? 1.0 : 0.0,
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(0, 8, 0, 2),
                                  child: Column(
                                    children: [
                                      for (int i = 0; i < displayEpisodes.length; i++) ...[
                                        AppValues.tileGap.gap,
                                        EpisodeCard(
                                          episode: displayEpisodes[i],
                                          playing: listState.currentEpisode?.filePath == displayEpisodes[i].filePath,
                                          isGroupFoldersView: true,
                                          borderRadius: _episodeRadius(i, displayEpisodes.length),
                                          onTap: () => _openPlayer(context, displayEpisodes[i]),
                                          onLongPress: () => _onEpisodeLongPress(displayEpisodes[i]),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
              if (playing != null)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: BottomPadding.of(context) + 8,
                  child: Builder(
                    builder: (context) {
                      final bool isCurrentCard = state.currentEpisode?.filePath == playing.filePath;
                      final Duration currentPos = isCurrentCard && state.position.inSeconds > 0 ? state.position : playing.listened;
                      final Duration totalDur = isCurrentCard && state.duration.inSeconds > 0 ? state.duration : playing.total;
                      final Duration remaining = totalDur > currentPos ? totalDur - currentPos : Duration.zero;
                      final double cardProgress = totalDur.inSeconds > 0 ? (currentPos.inSeconds / totalDur.inSeconds).clamp(0.0, 1.0) : 0.0;

                      return GestureDetector(
                        onTap: () => _openPlayer(context, playing),
                        child: HomeMiniPlayerCard(
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
