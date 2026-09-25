import 'dart:convert';
import 'dart:io';

import 'package:podmatz/podmatz.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';

class LocalPodcastService {
  Future<String?> getSavedFolderPath() async {
    return PreferencesHelper.getSavedFolderPath();
  }

  Future<String?> pickFolder() async {
    if (Platform.isAndroid) {
      try {
        if (await Permission.manageExternalStorage.isGranted == false) {
          await Permission.manageExternalStorage.request();
        }
      } catch (_) {}
      try {
        if (await Permission.storage.isGranted == false) {
          await Permission.storage.request();
        }
      } catch (_) {}
      try {
        if (await Permission.audio.isGranted == false) {
          await Permission.audio.request();
        }
      } catch (_) {}
    }

    final String? selectedDirectory = await FilePicker.getDirectoryPath(dialogTitle: 'Selecione a pasta dos Podcasts');

    if (selectedDirectory != null && selectedDirectory.isNotEmpty) {
      await PreferencesHelper.setSavedFolderPath(selectedDirectory);
      return selectedDirectory;
    }

    return null;
  }

  Future<List<Episode>> scanFolder(String folderPath) async {
    if (Platform.isAndroid) {
      try {
        if (await Permission.manageExternalStorage.isGranted == false) {
          await Permission.manageExternalStorage.request();
        }
      } catch (_) {}
    }

    final List<Episode> episodes = [];
    final dir = Directory(folderPath);

    if (!await dir.exists()) {
      return episodes;
    }

    final validExtensions = {'.mp3', '.m4a', '.aac', '.wav', '.ogg', '.opus'};

    try {
      final List<FileSystemEntity> entities = dir.listSync(recursive: true);

      for (final entity in entities) {
        if (entity is File) {
          final ext = p.extension(entity.path).toLowerCase();
          if (validExtensions.contains(ext)) {
            final fileName = p.basenameWithoutExtension(entity.path);
            final parentFolder = p.basename(entity.parent.path);

            // Generate seed color based on parent folder name
            final int hash = parentFolder.hashCode;
            final Color seedColor = Color((hash & 0xFFFFFF) | 0xFF000000);

            final stat = entity.statSync();
            final dateStr = '${stat.modified.day}/${stat.modified.month}/${stat.modified.year}';

            // Determine bucket
            final now = DateTime.now();
            final difference = now.difference(stat.modified).inDays;
            Bucket bucket;
            if (difference <= 0) {
              bucket = Bucket.today;
            } else if (difference == 1) {
              bucket = Bucket.yesterday;
            } else if (difference <= 7) {
              bucket = Bucket.thisWeek;
            } else if (difference <= 30) {
              bucket = Bucket.thisMonth;
            } else {
              bucket = Bucket.earlier;
            }

            final String channelName = parentFolder.isEmpty || parentFolder == p.basename(folderPath) ? '' : parentFolder;

            // Search for local cover image file or embedded ID3 APIC artwork & duration
            String coverImagePath = 'assets/images/default_podcast_cover.png';
            Uint8List? coverBytes;
            Duration episodeDuration = const Duration(minutes: 30);

            final folderCoverPath = _findLocalCoverImage(entity);
            if (folderCoverPath != null) {
              coverImagePath = folderCoverPath;
            }

            final meta = await _extractId3CoverAndDuration(entity);
            if (meta.coverBytes != null) {
              coverBytes = meta.coverBytes;
            }
            episodeDuration = meta.duration;
            final String episodeTitle = (meta.title != null && meta.title!.isNotEmpty) ? meta.title! : fileName;

            final int savedPosSec = await PreferencesHelper.getEpisodePositionSeconds(entity.path);
            final Duration listenedDuration = Duration(seconds: savedPosSec);

            episodes.add(
              Episode(
                bucket: bucket,
                channel: channelName,
                host: '',
                title: episodeTitle,
                date: dateStr,
                seed: seedColor,
                image: coverImagePath,
                imageBytes: coverBytes,
                total: episodeDuration,
                listened: listenedDuration,
                filePath: entity.path,
                chapters: meta.chapters,
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Erro ao escanear pasta local: $e');
    }

    return episodes;
  }

  String? _findLocalCoverImage(File audioFile) {
    try {
      final dir = audioFile.parent;
      final baseName = p.basenameWithoutExtension(audioFile.path);

      final sameNameJpg = File(p.join(dir.path, '$baseName.jpg'));
      if (sameNameJpg.existsSync()) return sameNameJpg.path;

      final sameNamePng = File(p.join(dir.path, '$baseName.png'));
      if (sameNamePng.existsSync()) return sameNamePng.path;

      final candidates = ['cover.jpg', 'cover.png', 'folder.jpg', 'folder.png', 'album.jpg', 'art.jpg'];
      for (final name in candidates) {
        final f = File(p.join(dir.path, name));
        if (f.existsSync()) return f.path;
      }
    } catch (_) {}

    return null;
  }

  Future<_AudioMetadata> _extractId3CoverAndDuration(File file) async {
    Uint8List? coverBytes;
    Duration? duration;
    String? title;

    final cachedSec = await PreferencesHelper.getCachedDurationSeconds(file.path);
    if (cachedSec != null && cachedSec > 0) {
      duration = Duration(seconds: cachedSec);
    }

    RandomAccessFile? raf;
    try {
      raf = file.openSync(mode: FileMode.read);
      final fileLength = file.lengthSync();
      final header = raf.readSync(10);

      if (header.length >= 10 && header[0] == 0x49 && header[1] == 0x44 && header[2] == 0x33) {
        final version = header[3];
        final flags = header[5];
        final tagSize = ((header[6] & 0x7F) << 21) | ((header[7] & 0x7F) << 14) | ((header[8] & 0x7F) << 7) | (header[9] & 0x7F);

        final tagBytes = raf.readSync(tagSize);
        int offset = 0;

        // Skip extended header if present
        if ((flags & 0x40) != 0 && tagBytes.length >= 4) {
          int extSize = (tagBytes[0] << 24) | (tagBytes[1] << 16) | (tagBytes[2] << 8) | tagBytes[3];
          if (version == 4) {
            extSize = ((tagBytes[0] & 0x7F) << 21) | ((tagBytes[1] & 0x7F) << 14) | ((tagBytes[2] & 0x7F) << 7) | (tagBytes[3] & 0x7F);
          }
          offset += extSize > 0 && extSize < tagBytes.length ? extSize : 4;
        }

        while (offset < tagBytes.length - 10) {
          final frameId = String.fromCharCodes(tagBytes.sublist(offset, offset + 4));
          if (frameId.codeUnits.any((c) => c < 32 || c > 126)) break;

          int frameSize = (tagBytes[offset + 4] << 24) | (tagBytes[offset + 5] << 16) | (tagBytes[offset + 6] << 8) | tagBytes[offset + 7];
          if (version == 4) {
            final syncsafe =
                ((tagBytes[offset + 4] & 0x7F) << 21) |
                ((tagBytes[offset + 5] & 0x7F) << 14) |
                ((tagBytes[offset + 6] & 0x7F) << 7) |
                (tagBytes[offset + 7] & 0x7F);
            if (syncsafe + offset + 10 <= tagBytes.length) {
              frameSize = syncsafe;
            }
          }

          if (frameSize <= 0 || offset + 10 + frameSize > tagBytes.length) {
            break;
          }

          offset += 10;

          if (frameId == 'TIT2' || frameId == 'TT2') {
            final frameData = tagBytes.sublist(offset, offset + frameSize);
            final parsed = _parseId3Text(frameData);
            if (parsed.isNotEmpty) {
              title = parsed;
            }
          } else if (frameId == 'APIC' && coverBytes == null) {
            final frameData = tagBytes.sublist(offset, offset + frameSize);
            int p = 1;
            while (p < frameData.length && frameData[p] != 0) {
              p++;
            }
            p++; // skip null
            p++; // skip picture type
            while (p < frameData.length && frameData[p] != 0) {
              p++;
            }
            p++; // skip null

            if (p < frameData.length) {
              coverBytes = Uint8List.fromList(frameData.sublist(p));
            }
          } else if ((frameId == 'TLEN' || frameId == 'TLE') && duration == null) {
            final frameData = tagBytes.sublist(offset, offset + frameSize);
            if (frameData.length > 1) {
              final str = String.fromCharCodes(frameData.sublist(1)).trim();
              final ms = int.tryParse(str.replaceAll(RegExp(r'[^\d]'), ''));
              if (ms != null && ms > 0) {
                duration = Duration(milliseconds: ms);
              }
            }
          }

          offset += frameSize;
        }

        if (duration == null && fileLength > tagSize + 10) {
          final seconds = (fileLength / 16000).round();
          if (seconds > 0) {
            duration = Duration(seconds: seconds);
          }
        }
      } else if (duration == null) {
        final seconds = (fileLength / 16000).round();
        if (seconds > 0) {
          duration = Duration(seconds: seconds);
        }
      }
    } catch (e) {
      debugPrint('Erro ao extrair metadados ID3 de ${file.path}: $e');
    } finally {
      try {
        raf?.closeSync();
      } catch (_) {}
    }

    final List<Chapter> chapters = _findSidecarChapters(file);
    chapters.sort((a, b) => a.startTime.compareTo(b.startTime));

    duration ??= const Duration(minutes: 30);
    return _AudioMetadata(coverBytes: coverBytes, duration: duration, title: title, chapters: chapters);
  }

  static String _parseId3Text(Uint8List frameData) {
    if (frameData.length <= 1) return '';
    try {
      final encoding = frameData[0];
      final bytes = frameData.sublist(1);
      String parsed = '';

      if (encoding == 1 || encoding == 2) {
        int start = 0;
        bool isLittleEndian = true;
        if (bytes.length >= 2) {
          if (bytes[0] == 0xFF && bytes[1] == 0xFE) {
            start = 2;
            isLittleEndian = true;
          } else if (bytes[0] == 0xFE && bytes[1] == 0xFF) {
            start = 2;
            isLittleEndian = false;
          }
        }

        final codeUnits = <int>[];
        for (int i = start; i < bytes.length - 1; i += 2) {
          final charCode = isLittleEndian ? (bytes[i] | (bytes[i + 1] << 8)) : ((bytes[i] << 8) | bytes[i + 1]);
          if (charCode != 0) {
            codeUnits.add(charCode);
          }
        }
        parsed = String.fromCharCodes(codeUnits);
      } else if (encoding == 3) {
        parsed = const Utf8Decoder(allowMalformed: true).convert(bytes);
      } else {
        parsed = String.fromCharCodes(bytes);
      }
      return parsed.replaceAll(RegExp(r'[\x00-\x1F\x7F-\x9F\xFF\xFE]'), '').trim();
    } catch (_) {
      return '';
    }
  }

  List<Chapter> _findSidecarChapters(File audioFile) {
    final chapters = <Chapter>[];

    try {
      final parentDir = audioFile.parent;
      final audioBaseName = p.basenameWithoutExtension(audioFile.path);
      final candidates = [File(p.join(parentDir.path, '$audioBaseName.chapters.json')), File(p.join(parentDir.path, '$audioBaseName.json'))];

      for (final file in candidates) {
        if (file.existsSync()) {
          final res = _parseJsonChapterFile(file);

          if (res.isNotEmpty) return res;
        }
      }
    } catch (e) {
      debugPrint('Erro ao buscar arquivo JSON de capítulos: $e');
    }

    return chapters;
  }

  List<Chapter> _parseJsonChapterFile(File file) {
    final chapters = <Chapter>[];

    try {
      final bytes = file.readAsBytesSync();
      final content = const Utf8Decoder(allowMalformed: true).convert(bytes);
      final dynamic parsed = jsonDecode(content);
      List<dynamic>? list;

      if (parsed is List) {
        list = parsed;
      } else if (parsed is Map && parsed['chapters'] is List) {
        list = parsed['chapters'] as List;
      }

      if (list != null) {
        for (final item in list) {
          if (item is Map) {
            final title = item['title']?.toString() ?? item['name']?.toString() ?? 'Capítulo';
            final startRaw = item['start'] ?? item['startTime'] ?? item['time'] ?? '0';
            Duration start = Duration.zero;

            if (startRaw is num) {
              start = Duration(milliseconds: (startRaw * 1000).toInt());
            } else if (startRaw is String) {
              start = _parseTimeString(startRaw);
            }

            chapters.add(Chapter(title: title, startTime: start));
          }
        }
      }
    } catch (e) {
      debugPrint('Erro ao ler arquivo JSON de capitulos ${file.path}: $e');
    }

    return chapters;
  }

  static Duration _parseTimeString(String s) {
    final parts = s.split(':');
    if (parts.length == 3) {
      final h = int.tryParse(parts[0]) ?? 0;
      final m = int.tryParse(parts[1]) ?? 0;
      final secParts = parts[2].split('.');
      final sec = int.tryParse(secParts[0]) ?? 0;
      final ms = secParts.length > 1 ? (int.tryParse(secParts[1].padRight(3, '0').substring(0, 3)) ?? 0) : 0;
      return Duration(hours: h, minutes: m, seconds: sec, milliseconds: ms);
    } else if (parts.length == 2) {
      final m = int.tryParse(parts[0]) ?? 0;
      final secParts = parts[1].split('.');
      final sec = int.tryParse(secParts[0]) ?? 0;
      final ms = secParts.length > 1 ? (int.tryParse(secParts[1].padRight(3, '0').substring(0, 3)) ?? 0) : 0;
      return Duration(minutes: m, seconds: sec, milliseconds: ms);
    } else {
      final val = double.tryParse(s) ?? 0;
      return Duration(milliseconds: (val * 1000).toInt());
    }
  }
}

class _AudioMetadata {
  final Uint8List? coverBytes;
  final Duration duration;
  final String? title;
  final List<Chapter> chapters;

  const _AudioMetadata({this.coverBytes, required this.duration, this.title, this.chapters = const []});
}
