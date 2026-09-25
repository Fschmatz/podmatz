import 'dart:convert';

import 'bucket.dart';
import 'chapter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class Episode {
  const Episode({
    required this.bucket,
    required this.channel,
    required this.host,
    required this.title,
    required this.date,
    required this.seed,
    required this.image,
    required this.total,
    required this.listened,
    this.filePath,
    this.imageBytes,
    this.playing = false,
    this.chapters = const [],
  });

  final Bucket bucket;
  final String channel;
  final String host;
  final String title;
  final String date;
  final Color seed;
  final String image;
  final Duration total;
  final Duration listened;
  final String? filePath;
  final Uint8List? imageBytes;
  final bool playing;
  final List<Chapter> chapters;

  double get progress => total.inSeconds == 0 ? 0 : listened.inSeconds / total.inSeconds;

  Episode copyWith({
    Bucket? bucket,
    String? channel,
    String? host,
    String? title,
    String? date,
    Color? seed,
    String? image,
    Duration? total,
    Duration? listened,
    String? filePath,
    Uint8List? imageBytes,
    bool? playing,
    List<Chapter>? chapters,
  }) {
    return Episode(
      bucket: bucket ?? this.bucket,
      channel: channel ?? this.channel,
      host: host ?? this.host,
      title: title ?? this.title,
      date: date ?? this.date,
      seed: seed ?? this.seed,
      image: image ?? this.image,
      total: total ?? this.total,
      listened: listened ?? this.listened,
      filePath: filePath ?? this.filePath,
      imageBytes: imageBytes ?? this.imageBytes,
      playing: playing ?? this.playing,
      chapters: chapters ?? this.chapters,
    );
  }

  ColorScheme scheme(BuildContext context) => Theme.of(context).colorScheme;

  Map<String, dynamic> toJson() => {
        'bucket': bucket.index,
        'channel': channel,
        'host': host,
        'title': title,
        'date': date,
        'seed': seed.toARGB32(),
        'image': image,
        'totalMs': total.inMilliseconds,
        'listenedMs': listened.inMilliseconds,
        'filePath': filePath,
        if (imageBytes != null) 'imageBytes': base64Encode(imageBytes!),
        'chapters': chapters.map((c) => c.toJson()).toList(),
      };

  factory Episode.fromJson(Map<String, dynamic> json) => Episode(
        bucket: Bucket.values[json['bucket'] as int? ?? 4],
        channel: json['channel'] as String? ?? '',
        host: json['host'] as String? ?? '',
        title: json['title'] as String? ?? '',
        date: json['date'] as String? ?? '',
        seed: Color(json['seed'] as int? ?? 0xFF000000),
        image: json['image'] as String? ?? '',
        total: Duration(milliseconds: json['totalMs'] as int? ?? 0),
        listened: Duration(milliseconds: json['listenedMs'] as int? ?? 0),
        filePath: json['filePath'] as String?,
        imageBytes: json['imageBytes'] != null ? base64Decode(json['imageBytes'] as String) : null,
        chapters: (json['chapters'] as List<dynamic>?)?.map((c) => Chapter.fromJson(c as Map<String, dynamic>)).toList() ?? const [],
      );
}
