import 'dart:convert';
import 'dart:io';

import 'package:podmatz/podmatz.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalPodcastService {
  static const String _prefKeyFolder = 'local_podcast_folder_path';

  Future<String?> getSavedFolderPath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefKeyFolder);
  }

  Future<String?> pickFolder() async {
    if (Platform.isAndroid) {
      if (await Permission.audio.request().isDenied && await Permission.storage.request().isDenied) {
        // Continue to show picker even if system permission prompt status is soft
      }
    }

    final String? selectedDirectory = await FilePicker.getDirectoryPath(dialogTitle: 'Selecione a pasta dos Podcasts');

    if (selectedDirectory != null && selectedDirectory.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKeyFolder, selectedDirectory);
      return selectedDirectory;
    }

    return null;
  }

  Future<List<Episode>> scanFolder(String folderPath) async {
    final List<Episode> episodes = [];
    final prefs = await SharedPreferences.getInstance();
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

            final meta = _extractId3CoverAndDuration(entity, prefs);
            if (meta.coverBytes != null) {
              coverBytes = meta.coverBytes;
            }
            episodeDuration = meta.duration;
            final String episodeTitle = (meta.title != null && meta.title!.isNotEmpty) ? meta.title! : fileName;

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
                listened: Duration.zero,
                filePath: entity.path,
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

  _AudioMetadata _extractId3CoverAndDuration(File file, SharedPreferences prefs) {
    Uint8List? coverBytes;
    Duration? duration;
    String? title;

    final cachedSec = prefs.getInt('dur_${file.path.hashCode}');
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
        final tagSize = ((header[6] & 0x7F) << 21) | ((header[7] & 0x7F) << 14) | ((header[8] & 0x7F) << 7) | (header[9] & 0x7F);

        final tagBytes = raf.readSync(tagSize);
        int offset = 0;

        while (offset < tagBytes.length - 10) {
          final frameId = String.fromCharCodes(tagBytes.sublist(offset, offset + 4));
          if (frameId.codeUnits.any((c) => c == 0)) break;

          int frameSize;
          if (version == 4) {
            frameSize =
                ((tagBytes[offset + 4] & 0x7F) << 21) |
                ((tagBytes[offset + 5] & 0x7F) << 14) |
                ((tagBytes[offset + 6] & 0x7F) << 7) |
                (tagBytes[offset + 7] & 0x7F);
          } else {
            frameSize = (tagBytes[offset + 4] << 24) | (tagBytes[offset + 5] << 16) | (tagBytes[offset + 6] << 8) | tagBytes[offset + 7];
          }

          offset += 10;

          if (frameId == 'TIT2' || frameId == 'TT2') {
            if (offset + frameSize <= tagBytes.length) {
              final frameData = tagBytes.sublist(offset, offset + frameSize);
              if (frameData.length > 1) {
                try {
                  final encoding = frameData[0];
                  final bytes = frameData.sublist(1);
                  String parsed = '';

                  if (encoding == 1 || encoding == 2) {
                    // UTF-16 with BOM or UTF-16BE without BOM
                    // Strip BOM 0xFF 0xFE (ÿþ) or 0xFE 0xFF
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
                      final charCode = isLittleEndian
                          ? (bytes[i] | (bytes[i + 1] << 8))
                          : ((bytes[i] << 8) | bytes[i + 1]);
                      if (charCode != 0) {
                        codeUnits.add(charCode);
                      }
                    }
                    parsed = String.fromCharCodes(codeUnits);
                  } else if (encoding == 3) {
                    // UTF-8
                    parsed = const Utf8Decoder(allowMalformed: true).convert(bytes);
                  } else {
                    // ISO-8859-1 (Latin1)
                    parsed = String.fromCharCodes(bytes);
                  }

                  // Clean control characters and BOM residue
                  parsed = parsed.replaceAll(RegExp(r'[\x00-\x1F\x7F-\x9F\xFF\xFE]'), '').trim();
                  if (parsed.isNotEmpty) {
                    title = parsed;
                  }
                } catch (_) {}
              }
            }
          } else if (frameId == 'APIC' && coverBytes == null && offset + frameSize <= tagBytes.length) {
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
          } else if ((frameId == 'TLEN' || frameId == 'TLE') && duration == null && offset + frameSize <= tagBytes.length) {
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

    duration ??= const Duration(minutes: 30);
    return _AudioMetadata(coverBytes: coverBytes, duration: duration, title: title);
  }
}

class _AudioMetadata {
  final Uint8List? coverBytes;
  final Duration duration;
  final String? title;

  const _AudioMetadata({this.coverBytes, required this.duration, this.title});
}
