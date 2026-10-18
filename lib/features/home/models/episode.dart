import 'dart:convert';

import 'chapter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class Episode {
  const Episode({
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
    this.customSpeed,
    this.skipSilenceOverride,
  });

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
  final double? customSpeed;
  final bool? skipSilenceOverride;

  double get progress => total.inSeconds == 0 ? 0 : listened.inSeconds / total.inSeconds;

  Episode copyWith({
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
    double? customSpeed,
    bool clearCustomSpeed = false,
    bool? skipSilenceOverride,
    bool clearSkipSilenceOverride = false,
  }) {
    return Episode(
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
      customSpeed: clearCustomSpeed ? null : (customSpeed ?? this.customSpeed),
      skipSilenceOverride: clearSkipSilenceOverride ? null : (skipSilenceOverride ?? this.skipSilenceOverride),
    );
  }

  ColorScheme scheme(BuildContext context) => Theme.of(context).colorScheme;

  Map<String, dynamic> toJson() => {
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
        if (customSpeed != null) 'customSpeed': customSpeed,
        if (skipSilenceOverride != null) 'skipSilenceOverride': skipSilenceOverride,
      };

  factory Episode.fromJson(Map<String, dynamic> json) => Episode(
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
        customSpeed: (json['customSpeed'] as num?)?.toDouble(),
        skipSilenceOverride: json['skipSilenceOverride'] as bool?,
      );
}
