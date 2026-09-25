import 'dart:convert';
import 'dart:typed_data';

class Chapter {
  const Chapter({
    required this.title,
    required this.startTime,
    this.endTime,
    this.imageBytes,
  });

  final String title;
  final Duration startTime;
  final Duration? endTime;
  final Uint8List? imageBytes;

  Map<String, dynamic> toJson() => {
        'title': title,
        'startTimeMs': startTime.inMilliseconds,
        if (endTime != null) 'endTimeMs': endTime!.inMilliseconds,
        if (imageBytes != null) 'imageBytes': base64Encode(imageBytes!),
      };

  factory Chapter.fromJson(Map<String, dynamic> json) => Chapter(
        title: json['title'] as String? ?? 'Capítulo',
        startTime: Duration(milliseconds: json['startTimeMs'] as int? ?? 0),
        endTime: json['endTimeMs'] != null ? Duration(milliseconds: json['endTimeMs'] as int) : null,
        imageBytes: json['imageBytes'] != null ? base64Decode(json['imageBytes'] as String) : null,
      );
}
