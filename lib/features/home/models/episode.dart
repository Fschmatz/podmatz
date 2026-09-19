import 'bucket.dart';
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
    );
  }

  ColorScheme scheme(BuildContext context) => Theme.of(context).colorScheme;
}
