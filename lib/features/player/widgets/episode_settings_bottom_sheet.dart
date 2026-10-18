import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:podmatz/podmatz.dart';

class EpisodeSettingsBottomSheet extends StatefulWidget {
  const EpisodeSettingsBottomSheet({super.key, required this.episode});

  final Episode episode;

  static void show(BuildContext context, {required Episode episode}) {
    final ColorScheme cs = episode.scheme(context);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: cs.surfaceContainerHigh,
      builder: (context) => EpisodeSettingsBottomSheet(episode: episode),
    );
  }

  @override
  State<EpisodeSettingsBottomSheet> createState() => _EpisodeSettingsBottomSheetState();
}

class _EpisodeSettingsBottomSheetState extends State<EpisodeSettingsBottomSheet> {
  late final TextEditingController _speedController;

  @override
  void initState() {
    super.initState();
    final custom = widget.episode.customSpeed;
    _speedController = TextEditingController(text: custom != null ? custom.toString() : '');
  }

  @override
  void dispose() {
    _speedController.dispose();
    super.dispose();
  }

  void _applySpeed(Episode episode, double? speed) {
    locator<AudioPlayerCubit>().setEpisodeCustomSpeed(episode, speed);
    setState(() {
      _speedController.text = speed != null ? speed.toString() : '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme tt = Theme.of(context).textTheme;

    return BlocBuilder<AudioPlayerCubit, AudioPlayerState>(
      bloc: locator<AudioPlayerCubit>(),
      builder: (context, playerState) {
        final activeEpisode = playerState.episodes.firstWhere(
          (ep) => ep.filePath == widget.episode.filePath,
          orElse: () => playerState.currentEpisode?.filePath == widget.episode.filePath ? playerState.currentEpisode! : widget.episode,
        );
        final ColorScheme cs = activeEpisode.scheme(context);
        final bool isCustomSpeed = activeEpisode.customSpeed != null;
        final double effectiveSpeed = activeEpisode.customSpeed ?? playerState.playbackSpeed;
        final bool hasSkipSilenceOverride = activeEpisode.skipSilenceOverride != null;
        final bool effectiveSkipSilence = activeEpisode.skipSilenceOverride ?? playerState.skipSilence;

        final double viewInsetsBottom = MediaQuery.viewInsetsOf(context).bottom;
        final double navBarPadding = BottomPadding.of(context);
        final double bottomPadding = viewInsetsBottom > 0 ? viewInsetsBottom + 16 : navBarPadding + 16;

        return Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 16, bottom: bottomPadding),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: cs.onSurfaceVariant.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                16.gap,
                Row(
                  children: [
                    Icon(Icons.tune_rounded, color: cs.primary),
                    8.gap,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Opções do Episódio',
                            style: tt.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: cs.onSurface),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                16.gap,

                // --- Card: Velocidade de Reprodução ---
                Card(
                  margin: EdgeInsets.zero,
                  elevation: 0,
                  color: cs.surfaceContainer,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.speed_outlined, color: cs.onSurfaceVariant),
                            12.gap,
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Velocidade', style: tt.bodyLarge?.copyWith()),
                                  Text(
                                    isCustomSpeed ? 'Personalizada: ${effectiveSpeed}x' : 'Padrão: ${playerState.playbackSpeed}x',
                                    style: tt.bodySmall?.copyWith(
                                      color: isCustomSpeed ? cs.primary : cs.onSurfaceVariant,
                                      fontWeight: isCustomSpeed ? FontWeight.w600 : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: isCustomSpeed,
                              onChanged: (enabled) {
                                if (enabled) {
                                  _applySpeed(activeEpisode, playerState.playbackSpeed);
                                } else {
                                  _applySpeed(activeEpisode, null);
                                }
                              },
                            ),
                          ],
                        ),
                        if (isCustomSpeed) ...[
                          16.gap,
                          const Divider(height: 1),
                          12.gap,
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: AppValues.playbackSpeeds.map((s) {
                              final isSelected = activeEpisode.customSpeed == s;
                              return ChoiceChip(
                                label: Text('${s}x'),
                                selected: isSelected,
                                onSelected: (selected) {
                                  if (selected) {
                                    _applySpeed(activeEpisode, s);
                                  }
                                },
                              );
                            }).toList(),
                          ),
                          12.gap,
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _speedController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: InputDecoration(
                                    labelText: 'Velocidade',
                                    hintText: 'Ex: 1.15, 1.35',
                                    suffixText: 'x',
                                    border: const OutlineInputBorder(),
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                    suffixIcon: IconButton(
                                      icon: const Icon(Icons.check_rounded),
                                      tooltip: 'Aplicar',
                                      onPressed: () {
                                        final text = _speedController.text.replaceAll(',', '.').trim();
                                        final val = double.tryParse(text);
                                        if (val != null && val > 0 && val <= 4.0) {
                                          _applySpeed(activeEpisode, val);
                                        }
                                      },
                                    ),
                                  ),
                                  onSubmitted: (text) {
                                    final normalized = text.replaceAll(',', '.').trim();
                                    final val = double.tryParse(normalized);
                                    if (val != null && val > 0 && val <= 4.0) {
                                      _applySpeed(activeEpisode, val);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                8.gap,

                // --- Card: Pular Silêncio ---
                Card(
                  margin: EdgeInsets.zero,
                  elevation: 0,
                  color: cs.surfaceContainer,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(effectiveSkipSilence ? Icons.volume_off_outlined : Icons.volume_up_outlined, color: cs.onSurfaceVariant),
                        12.gap,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Pular Silêncio', style: tt.bodyLarge?.copyWith()),
                              Text(
                                hasSkipSilenceOverride
                                    ? (effectiveSkipSilence ? 'Ligado (Personalizado)' : 'Desligado (Personalizado)')
                                    : 'Padrão (${playerState.skipSilence ? 'Ligado' : 'Desligado'})',
                                style: tt.bodySmall?.copyWith(
                                  color: hasSkipSilenceOverride ? cs.primary : cs.onSurfaceVariant,
                                  fontWeight: hasSkipSilenceOverride ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: effectiveSkipSilence,
                          onChanged: (val) {
                            if (val == playerState.skipSilence) {
                              locator<AudioPlayerCubit>().setEpisodeSkipSilenceOverride(activeEpisode, null);
                            } else {
                              locator<AudioPlayerCubit>().setEpisodeSkipSilenceOverride(activeEpisode, val);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                8.gap,
              ],
            ),
          ),
        );
      },
    );
  }
}
