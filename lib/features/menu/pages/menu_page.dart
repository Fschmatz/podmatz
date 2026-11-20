import 'package:podmatz/podmatz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: _AppBar(), body: _Body());
  }
}

class _Body extends StatefulWidget {
  const _Body();

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  bool _isScanning = false;

  void _showSeekIntervalDialog(BuildContext context, int current) {
    final controller = TextEditingController(text: current.toString());
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Tempo de Avanço/Retrocesso'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Selecione ou digite os segundos para o pulo de áudio:'),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AppValues.seekIntervals.map((s) {
                  return ChoiceChip(
                    label: Text('${s}s'),
                    selected: current == s,
                    onSelected: (_) {
                      locator<AudioPlayerCubit>().setSeekInterval(s);
                      Navigator.of(context).pop();
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Segundos personalizados', border: OutlineInputBorder(), suffixText: 's'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () {
                final val = int.tryParse(controller.text);
                if (val != null && val > 0) {
                  locator<AudioPlayerCubit>().setSeekInterval(val);
                }
                Navigator.of(context).pop();
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }

  void _showPlaybackSpeedDialog(BuildContext context, double current) {
    final controller = TextEditingController(text: current.toString());
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Velocidade de Reprodução'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Selecione ou digite a velocidade desejada:'),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AppValues.playbackSpeeds.map((s) {
                  return ChoiceChip(
                    label: Text('${s}x'),
                    selected: current == s,
                    onSelected: (_) {
                      locator<AudioPlayerCubit>().setPlaybackSpeed(s);
                      Navigator.of(context).pop();
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Velocidade personalizada', border: OutlineInputBorder(), suffixText: 'x'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () {
                final normalized = controller.text.replaceAll(',', '.').trim();
                final val = double.tryParse(normalized);
                if (val != null && val > 0 && val <= 4.0) {
                  locator<AudioPlayerCubit>().setPlaybackSpeed(val);
                }
                Navigator.of(context).pop();
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _rescan() async {
    setState(() => _isScanning = true);
    await locator<AudioPlayerCubit>().loadSavedFolder();
    if (mounted) setState(() => _isScanning = false);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AudioPlayerCubit, AudioPlayerState>(
      bloc: locator<AudioPlayerCubit>(),
      builder: (context, playerState) {
        final String folderPath = playerState.folderPath ?? 'Nenhuma pasta selecionada';

        return ListView(
          padding: EdgeInsets.fromLTRB(0, 8, 0, BottomPadding.of(context)),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Card(
                margin: EdgeInsets.zero,
                elevation: 0,
                color: Theme.of(context).colorScheme.primaryContainer,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppValues.specialBorderRadius)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
                  child: Column(
                    children: [
                      Text(
                        AppValues.title,
                        style: Theme.of(
                          context,
                        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onPrimaryContainer),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Version ${AppValues.version}',
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.8)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SectionSegmentedWidgetList(
              title: 'Aparência',
              children: [
                BlocBuilder<ThemeModeCubit, ThemeMode>(
                  bloc: locator<ThemeModeCubit>(),
                  builder: (context, themeMode) {
                    return SwitchListTile(
                      secondary: const Icon(Icons.brightness_6_outlined),
                      title: const Text('Tema Escuro'),
                      thumbIcon: const WidgetStateProperty<Icon?>.fromMap({
                        WidgetState.selected: Icon(Icons.dark_mode_rounded),
                        WidgetState.any: Icon(Icons.light_mode_rounded),
                      }),
                      value: themeMode == ThemeMode.dark,
                      onChanged: (_) {
                        locator<ThemeModeCubit>().toggle();
                      },
                    );
                  },
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.folder_copy_outlined),
                  title: const Text('Agrupar por Pastas'),
                  subtitle: const Text('Exibir podcasts por pasta na tela inicial'),
                  value: playerState.groupFoldersView,
                  onChanged: (val) {
                    locator<AudioPlayerCubit>().setGroupFoldersView(val);
                  },
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.image_outlined),
                  title: const Text('Capa nos Cards'),
                  subtitle: const Text('Exibir a capa do episódio nos cards'),
                  value: playerState.showEpisodeCover,
                  onChanged: (val) {
                    locator<AudioPlayerCubit>().setShowEpisodeCover(val);
                  },
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.view_agenda_outlined),
                  title: const Text('Cards Compactos'),
                  subtitle: const Text('Exibir cards em formato compacto'),
                  value: playerState.compactCards,
                  onChanged: (val) {
                    locator<AudioPlayerCubit>().setCompactCards(val);
                  },
                ),
              ],
            ),
            SectionSegmentedWidgetList(
              title: 'Player',
              children: [
                ListTile(
                  leading: const Icon(Icons.timer_outlined),
                  title: const Text('Pulo de Tempo (Forward / Rewind)'),
                  subtitle: Text('${playerState.seekIntervalSeconds} segundos'),
                  onTap: () => _showSeekIntervalDialog(context, playerState.seekIntervalSeconds),
                ),
                ListTile(
                  leading: const Icon(Icons.speed_outlined),
                  title: const Text('Velocidade de Reprodução'),
                  subtitle: Text('${playerState.playbackSpeed}x'),
                  onTap: () => _showPlaybackSpeedDialog(context, playerState.playbackSpeed),
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.volume_off_outlined),
                  title: const Text('Pular Silêncio'),
                  subtitle: const Text('Remover trechos silenciosos automaticamente'),
                  value: playerState.skipSilence,
                  onChanged: (val) {
                    locator<AudioPlayerCubit>().setSkipSilence(val);
                  },
                ),
              ],
            ),
            SectionSegmentedWidgetList(
              title: 'Biblioteca',
              children: [
                ListTile(
                  leading: const Icon(Icons.folder_outlined),
                  title: const Text('Pasta de Podcasts'),
                  subtitle: Text(folderPath),
                  onTap: () {
                    locator<AudioPlayerCubit>().pickFolder();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.refresh_outlined),
                  title: const Text('Re-escanear Pasta'),
                  trailing: _isScanning ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : null,
                  onTap: _isScanning
                      ? null
                      : () async {
                          final messenger = ScaffoldMessenger.of(context);
                          await _rescan();
                          if (mounted) {
                            messenger.showSnackBar(const SnackBar(content: Text('Pasta re-escaneada com sucesso.')));
                          }
                        },
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _AppBar extends StatelessWidget implements PreferredSizeWidget {
  const _AppBar();

  @override
  Widget build(BuildContext context) {
    return AppBar(leading: const StyledBackButton());
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
