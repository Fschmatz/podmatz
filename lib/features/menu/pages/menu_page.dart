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

class _Body extends StatelessWidget {
  const _Body();

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
                children: [5, 10, 15, 30, 60].map((s) {
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
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Velocidade de Reprodução'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Selecione a velocidade desejada:'),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [0.75, 1.0, 1.10, 1.2, 1.3, 1.5, 1.75, 2.0, 2.5, 3.0].map((s) {
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
            ],
          ),
          actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar'))],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AudioPlayerCubit, AudioPlayerState>(
      bloc: locator<AudioPlayerCubit>(),
      builder: (context, playerState) {
        final String folderPath = playerState.folderPath ?? 'Nenhuma pasta selecionada';

        return ListView(
          padding: EdgeInsets.fromLTRB(16, 8, 16, BottomPadding.of(context)),
          children: [
            Card(
              margin: const EdgeInsets.fromLTRB(0, 0, 0, 24),
              elevation: 0,
              color: Theme.of(context).colorScheme.primaryContainer,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
                child: Column(
                  children: [
                    Text(
                      "${AppValues.title} Fschmatz",
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
            MenuSection(
              label: 'Biblioteca Local',
              children: [
                MenuTile(
                  icon: Icons.folder_outlined,
                  title: 'Pasta de Podcasts',
                  subtitle: folderPath,
                  onTap: () {
                    locator<AudioPlayerCubit>().pickFolder();
                  },
                ),
                MenuTile(
                  icon: Icons.refresh_outlined,
                  title: 'Re-escanear Pasta',
                  onTap: () {
                    locator<AudioPlayerCubit>().loadSavedFolder();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pasta re-escaneada com sucesso.')));
                  },
                ),
              ],
            ),
            32.gap,
            MenuSection(
              label: 'Preferências do Player',
              children: [
                MenuTile(
                  icon: Icons.timer_outlined,
                  title: 'Pulo de Tempo (Forward / Rewind)',
                  subtitle: '${playerState.seekIntervalSeconds} segundos',
                  onTap: () => _showSeekIntervalDialog(context, playerState.seekIntervalSeconds),
                ),
                MenuTile(
                  icon: Icons.speed_outlined,
                  title: 'Velocidade de Reprodução',
                  subtitle: '${playerState.playbackSpeed}x',
                  onTap: () => _showPlaybackSpeedDialog(context, playerState.playbackSpeed),
                ),
                MenuTile(
                  icon: Icons.brightness_6_outlined,
                  title: 'Tema Escuro',
                  trailing: BlocBuilder<ThemeModeCubit, ThemeMode>(
                    bloc: locator<ThemeModeCubit>(),
                    builder: (context, state) {
                      final ThemeMode themeMode = state;

                      return Switch(
                        value: themeMode == ThemeMode.dark,
                        thumbIcon: const WidgetStateProperty<Icon?>.fromMap({
                          WidgetState.selected: Icon(Icons.dark_mode_rounded),
                          WidgetState.any: Icon(Icons.light_mode_rounded),
                        }),
                        onChanged: (_) {
                          locator<ThemeModeCubit>().toggle();
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
            64.gap,
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
