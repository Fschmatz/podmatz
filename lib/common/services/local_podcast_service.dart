import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

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

            final meta = await _extractAudioMetadata(entity);
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

  Future<_AudioMetadata> _extractAudioMetadata(File file) async {
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
      final header = raf.readSync(12);

      if (header.length >= 10 && header[0] == 0x49 && header[1] == 0x44 && header[2] == 0x33) {
        // ID3v2 tag (MP3, etc.)
        final id3Meta = _parseId3(raf, header, fileLength);
        coverBytes = id3Meta.coverBytes;
        title = id3Meta.title;
        duration ??= id3Meta.duration;
      } else if (header.length >= 8 &&
          ((header[4] == 0x66 && header[5] == 0x74 && header[6] == 0x79 && header[7] == 0x70) || // 'ftyp'
              (header[4] == 0x6D && header[5] == 0x6F && header[6] == 0x6F && header[7] == 0x76))) { // 'moov'
        // MP4 / M4A container
        final mp4Meta = _parseMp4(raf, fileLength);
        coverBytes = mp4Meta.coverBytes;
        title = mp4Meta.title;
        duration ??= mp4Meta.duration;
      } else if (header.length >= 4 &&
          header[0] == 0x66 && header[1] == 0x4C && header[2] == 0x61 && header[3] == 0x43) {
        // FLAC
        final flacMeta = _parseFlac(raf, fileLength);
        coverBytes = flacMeta.coverBytes;
        duration ??= flacMeta.duration;
      }

      // Fallback duration estimation if still null
      if (duration == null && fileLength > 0) {
        final seconds = (fileLength / 16000).round();
        if (seconds > 0) {
          duration = Duration(seconds: seconds);
        }
      }
    } catch (e) {
      debugPrint('Erro ao extrair metadados de ${file.path}: $e');
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

  static _AudioMetadata _parseId3(RandomAccessFile raf, Uint8List header, int fileLength) {
    Uint8List? coverBytes;
    Duration? duration;
    String? title;

    try {
      raf.setPositionSync(10);
      final version = header[3]; // 2 = v2.2, 3 = v2.3, 4 = v2.4
      final flags = header[5];
      final tagSize = ((header[6] & 0x7F) << 21) |
          ((header[7] & 0x7F) << 14) |
          ((header[8] & 0x7F) << 7) |
          (header[9] & 0x7F);

      Uint8List tagBytes = raf.readSync(tagSize);

      // Handle unsynchronization flag on tag header
      if ((flags & 0x80) != 0) {
        tagBytes = _deUnsynchronize(tagBytes);
      }

      int offset = 0;

      // Skip extended header if present
      if ((flags & 0x40) != 0 && tagBytes.length >= 4) {
        int extSize = (tagBytes[0] << 24) | (tagBytes[1] << 16) | (tagBytes[2] << 8) | tagBytes[3];
        if (version == 4) {
          extSize = ((tagBytes[0] & 0x7F) << 21) |
              ((tagBytes[1] & 0x7F) << 14) |
              ((tagBytes[2] & 0x7F) << 7) |
              (tagBytes[3] & 0x7F);
        }
        offset += extSize > 0 && extSize < tagBytes.length ? extSize : 4;
      }

      final isV2 = version == 2;
      final headerLen = isV2 ? 6 : 10;

      while (offset < tagBytes.length - headerLen) {
        final String frameId;
        int frameSize = 0;

        if (isV2) {
          frameId = String.fromCharCodes(tagBytes.sublist(offset, offset + 3));
          if (frameId.codeUnits.any((c) => c < 32 || c > 126)) break;
          frameSize = (tagBytes[offset + 3] << 16) | (tagBytes[offset + 4] << 8) | tagBytes[offset + 5];
        } else {
          frameId = String.fromCharCodes(tagBytes.sublist(offset, offset + 4));
          if (frameId.codeUnits.any((c) => c < 32 || c > 126)) break;

          frameSize = (tagBytes[offset + 4] << 24) |
              (tagBytes[offset + 5] << 16) |
              (tagBytes[offset + 6] << 8) |
              tagBytes[offset + 7];

          if (version == 4) {
            final syncsafe = ((tagBytes[offset + 4] & 0x7F) << 21) |
                ((tagBytes[offset + 5] & 0x7F) << 14) |
                ((tagBytes[offset + 6] & 0x7F) << 7) |
                (tagBytes[offset + 7] & 0x7F);
            if (syncsafe + offset + 10 <= tagBytes.length) {
              frameSize = syncsafe;
            }
          }
        }

        if (frameSize <= 0 || offset + headerLen + frameSize > tagBytes.length) {
          break;
        }

        offset += headerLen;

        if (frameId == 'TIT2' || frameId == 'TT2') {
          final frameData = tagBytes.sublist(offset, offset + frameSize);
          final parsed = _parseId3Text(frameData);
          if (parsed.isNotEmpty) {
            title = parsed;
          }
        } else if (frameId == 'APIC' || frameId == 'PIC') {
          final frameData = tagBytes.sublist(offset, offset + frameSize);
          int picType = 3;
          if (!isV2) {
            int mimeEnd = 1;
            while (mimeEnd < frameData.length && frameData[mimeEnd] != 0) {
              mimeEnd++;
            }
            if (mimeEnd + 1 < frameData.length) {
              picType = frameData[mimeEnd + 1];
            }
          } else {
            if (frameData.length > 4) {
              picType = frameData[4];
            }
          }

          final imgStart = _findImageOffset(frameData, isV2 ? 4 : 1);
          if (imgStart != null) {
            final bytes = Uint8List.fromList(frameData.sublist(imgStart));
            if (picType == 3 || coverBytes == null) {
              coverBytes = bytes;
            }
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
    } catch (_) {}

    return _AudioMetadata(coverBytes: coverBytes, duration: duration ?? Duration.zero, title: title);
  }

  static _AudioMetadata _parseMp4(RandomAccessFile raf, int fileLength) {
    Uint8List? coverBytes;
    Duration? duration;
    String? title;

    try {
      raf.setPositionSync(0);
      int offset = 0;

      while (offset < fileLength - 8) {
        raf.setPositionSync(offset);
        final header = raf.readSync(8);
        if (header.length < 8) break;

        int size = (header[0] << 24) | (header[1] << 16) | (header[2] << 8) | header[3];
        final type = String.fromCharCodes(header.sublist(4, 8));
        int headerSize = 8;

        if (size == 1) {
          final ext = raf.readSync(8);
          if (ext.length < 8) break;
          size = 0;
          for (int b in ext) {
            size = (size << 8) | b;
          }
          headerSize = 16;
        } else if (size == 0) {
          size = fileLength - offset;
        }

        if (size < headerSize) break;

        if (type == 'moov') {
          final payloadSize = (size - headerSize).clamp(0, 25 * 1024 * 1024);
          raf.setPositionSync(offset + headerSize);
          final moovBytes = raf.readSync(payloadSize);

          duration = _extractMp4Duration(moovBytes);
          coverBytes = _extractMp4Cover(moovBytes);
          title = _extractMp4Title(moovBytes);
          break;
        }

        offset += size;
      }
    } catch (_) {}

    return _AudioMetadata(coverBytes: coverBytes, duration: duration ?? Duration.zero, title: title);
  }

  static Uint8List? _extractMp4Cover(Uint8List moovBytes) {
    for (int i = 0; i < moovBytes.length - 8; i++) {
      if (moovBytes[i] == 0x63 &&
          moovBytes[i + 1] == 0x6F &&
          moovBytes[i + 2] == 0x76 &&
          moovBytes[i + 3] == 0x72) { // 'covr'
        int boxSize = (moovBytes[i - 4] << 24) |
            (moovBytes[i - 3] << 16) |
            (moovBytes[i - 2] << 8) |
            moovBytes[i - 1];
        if (boxSize <= 8 || i - 4 + boxSize > moovBytes.length) {
          boxSize = moovBytes.length - (i - 4);
        }
        final covrPayload = moovBytes.sublist(i + 4, i - 4 + boxSize);
        final imgStart = _findImageOffset(covrPayload);
        if (imgStart != null) {
          return covrPayload.sublist(imgStart);
        }
      }
    }
    return null;
  }

  static Duration? _extractMp4Duration(Uint8List moovBytes) {
    for (int i = 0; i < moovBytes.length - 28; i++) {
      if (moovBytes[i] == 0x6D &&
          moovBytes[i + 1] == 0x76 &&
          moovBytes[i + 2] == 0x68 &&
          moovBytes[i + 3] == 0x64) { // 'mvhd'
        final version = moovBytes[i + 4];
        if (version == 0) {
          final timescale = (moovBytes[i + 16] << 24) |
              (moovBytes[i + 17] << 16) |
              (moovBytes[i + 18] << 8) |
              moovBytes[i + 19];
          final dur = (moovBytes[i + 20] << 24) |
              (moovBytes[i + 21] << 16) |
              (moovBytes[i + 22] << 8) |
              moovBytes[i + 23];
          if (timescale > 0 && dur > 0) {
            return Duration(milliseconds: ((dur / timescale) * 1000).round());
          }
        } else if (version == 1 && i + 36 < moovBytes.length) {
          final timescale = (moovBytes[i + 24] << 24) |
              (moovBytes[i + 25] << 16) |
              (moovBytes[i + 26] << 8) |
              moovBytes[i + 27];
          int dur = 0;
          for (int k = 0; k < 8; k++) {
            dur = (dur << 8) | moovBytes[i + 28 + k];
          }
          if (timescale > 0 && dur > 0) {
            return Duration(milliseconds: ((dur / timescale) * 1000).round());
          }
        }
      }
    }
    return null;
  }

  static String? _extractMp4Title(Uint8List moovBytes) {
    for (int i = 0; i < moovBytes.length - 16; i++) {
      if (moovBytes[i] == 0xA9 &&
          moovBytes[i + 1] == 0x6E &&
          moovBytes[i + 2] == 0x61 &&
          moovBytes[i + 3] == 0x6D) { // '©nam'
        int boxSize = (moovBytes[i - 4] << 24) |
            (moovBytes[i - 3] << 16) |
            (moovBytes[i - 2] << 8) |
            moovBytes[i - 1];
        if (boxSize <= 8 || i - 4 + boxSize > moovBytes.length) {
          boxSize = moovBytes.length - (i - 4);
        }
        final namPayload = moovBytes.sublist(i + 4, i - 4 + boxSize);
        for (int j = 0; j < namPayload.length - 8; j++) {
          if (namPayload[j] == 0x64 &&
              namPayload[j + 1] == 0x61 &&
              namPayload[j + 2] == 0x74 &&
              namPayload[j + 3] == 0x61) { // 'data'
            if (j + 12 < namPayload.length) {
              return const Utf8Decoder(allowMalformed: true).convert(namPayload.sublist(j + 12)).trim();
            }
          }
        }
      }
    }
    return null;
  }

  static _AudioMetadata _parseFlac(RandomAccessFile raf, int fileLength) {
    Uint8List? coverBytes;
    Duration? duration;

    try {
      raf.setPositionSync(4); // Skip 'fLaC'
      bool isLast = false;

      while (!isLast) {
        final header = raf.readSync(4);
        if (header.length < 4) break;

        isLast = (header[0] & 0x80) != 0;
        final blockType = header[0] & 0x7F;
        final length = (header[1] << 16) | (header[2] << 8) | header[3];

        if (length <= 0) break;

        if (blockType == 0 && duration == null) {
          // STREAMINFO
          final info = raf.readSync(length.clamp(0, 34));
          if (info.length >= 18) {
            final sampleRate = (info[10] << 12) | (info[11] << 4) | (info[12] >> 4);
            final totalSamples = ((info[13] & 0x0F) << 32) |
                (info[14] << 24) |
                (info[15] << 16) |
                (info[16] << 8) |
                info[17];
            if (sampleRate > 0 && totalSamples > 0) {
              duration = Duration(seconds: (totalSamples / sampleRate).round());
            }
          }
          if (length > 34) {
            raf.setPositionSync(raf.positionSync() + length - 34);
          }
        } else if (blockType == 6 && coverBytes == null) {
          // PICTURE
          final picData = raf.readSync(length.clamp(0, 20 * 1024 * 1024));
          final imgStart = _findImageOffset(picData);
          if (imgStart != null) {
            coverBytes = picData.sublist(imgStart);
          }
          if (length > picData.length) {
            raf.setPositionSync(raf.positionSync() + length - picData.length);
          }
        } else {
          raf.setPositionSync(raf.positionSync() + length);
        }
      }
    } catch (_) {}

    return _AudioMetadata(coverBytes: coverBytes, duration: duration ?? Duration.zero);
  }

  static int? _findImageOffset(Uint8List data, [int start = 0]) {
    final len = data.length;
    for (int i = start; i < len - 3; i++) {
      // JPEG: FF D8 FF
      if (data[i] == 0xFF && data[i + 1] == 0xD8 && data[i + 2] == 0xFF) {
        return i;
      }
      // PNG: 89 50 4E 47
      if (data[i] == 0x89 && data[i + 1] == 0x50 && data[i + 2] == 0x4E && data[i + 3] == 0x47) {
        return i;
      }
      // WebP: RIFF .... WEBP
      if (data[i] == 0x52 &&
          data[i + 1] == 0x49 &&
          data[i + 2] == 0x46 &&
          data[i + 3] == 0x46 &&
          i + 11 < len &&
          data[i + 8] == 0x57 &&
          data[i + 9] == 0x45 &&
          data[i + 10] == 0x42 &&
          data[i + 11] == 0x50) {
        return i;
      }
      // GIF: GIF8
      if (data[i] == 0x47 && data[i + 1] == 0x49 && data[i + 2] == 0x46 && data[i + 3] == 0x38) {
        return i;
      }
    }
    return null;
  }

  static Uint8List _deUnsynchronize(Uint8List data) {
    final out = BytesBuilder(copy: false);
    for (int i = 0; i < data.length; i++) {
      out.addByte(data[i]);
      if (data[i] == 0xFF && i + 1 < data.length && data[i + 1] == 0x00) {
        i++; // Skip the stuffed 0x00 byte
      }
    }
    return out.takeBytes();
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
