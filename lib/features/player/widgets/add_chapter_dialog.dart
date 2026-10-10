import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:podmatz/podmatz.dart';

class AddChapterDialog extends StatefulWidget {
  const AddChapterDialog({super.key, required this.episode, required this.initialTime, this.initialChapter});

  final Episode episode;
  final Duration initialTime;
  final Chapter? initialChapter;

  static Future<void> show(BuildContext context, {required Episode episode, required Duration initialTime, Chapter? initialChapter}) {
    return showDialog<void>(
      context: context,
      builder: (context) => AddChapterDialog(episode: episode, initialTime: initialTime, initialChapter: initialChapter),
    );
  }

  @override
  State<AddChapterDialog> createState() => _AddChapterDialogState();
}

class _AddChapterDialogState extends State<AddChapterDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _timeController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final isEditing = widget.initialChapter != null;
    final timeDuration = isEditing ? widget.initialChapter!.startTime : widget.initialTime;

    _titleController = TextEditingController(text: widget.initialChapter?.title ?? '');
    _timeController = TextEditingController(text: LocalPodcastService.formatDurationTimestamp(timeDuration));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final title = _titleController.text.trim();
    final timeStr = _timeController.text.trim();
    final parsedDuration = LocalPodcastService.parseTimeString(timeStr);

    final chapter = Chapter(title: title.isEmpty ? 'Capítulo' : title, startTime: parsedDuration);

    locator<AudioPlayerCubit>().saveChapter(episode: widget.episode, chapter: chapter, oldChapter: widget.initialChapter);

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialChapter != null;

    return AlertDialog(
      scrollable: true,
      title: Text(isEditing ? 'Editar Capítulo' : 'Novo Capítulo'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _timeController,
              keyboardType: TextInputType.datetime,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d:\.]')),
              ],
              decoration: const InputDecoration(
                labelText: 'Tempo (ex: 01:15:30 ou 15:30)',
                border: OutlineInputBorder(),
                hintText: '00:00:00.000',
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Informe o tempo do capítulo';
                }
                final trimmed = val.trim();
                final timeRegex = RegExp(r'^(?:(?:\d+:)?(?:[0-5]?\d):(?:[0-5]\d)(?:\.\d{1,3})?|\d+(?:\.\d{1,3})?)$');
                if (!timeRegex.hasMatch(trimmed)) {
                  return 'Formato inválido (ex: 01:15:30 ou 15:30)';
                }
                final duration = LocalPodcastService.parseTimeString(trimmed);
                if (widget.episode.total > Duration.zero && duration > widget.episode.total) {
                  return 'O tempo excede a duração total (${widget.episode.total.minutesLabel})';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              maxLength: 200,
              decoration: const InputDecoration(
                labelText: 'Nome',
                border: OutlineInputBorder(),
                // prefixIcon: Icon(Icons.title_rounded)
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Informe o nome do capítulo';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        FilledButton(onPressed: _save, child: const Text('Salvar')),
      ],
    );
  }
}
