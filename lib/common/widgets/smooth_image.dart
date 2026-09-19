import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class SmoothImage extends StatelessWidget {
  const SmoothImage({
    super.key,
    required this.url,
    this.imageBytes,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholderColor,
    this.placeholderChild,
    this.errorChild,
  });

  final String url;
  final Uint8List? imageBytes;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Color? placeholderColor;
  final Widget? placeholderChild;
  final Widget? errorChild;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Color bg = placeholderColor ?? cs.surfaceContainerHighest;

    Widget errorWidget() => Container(
          width: width,
          height: height,
          color: bg,
          alignment: Alignment.center,
          child: errorChild ??
              Icon(
                Icons.podcasts_rounded,
                size: 24,
                color: cs.primary,
              ),
        );

    if (imageBytes != null && imageBytes!.isNotEmpty) {
      return Image.memory(
        imageBytes!,
        fit: fit,
        width: width,
        height: height,
        cacheWidth: width != null ? (width! * MediaQuery.devicePixelRatioOf(context)).toInt() : 160,
        cacheHeight: height != null ? (height! * MediaQuery.devicePixelRatioOf(context)).toInt() : 160,
        errorBuilder: (_, __, ___) => errorWidget(),
      );
    }

    if (url.startsWith('assets/')) {
      return Image.asset(
        url,
        fit: fit,
        width: width,
        height: height,
        cacheWidth: width != null ? (width! * MediaQuery.devicePixelRatioOf(context)).toInt() : 160,
        cacheHeight: height != null ? (height! * MediaQuery.devicePixelRatioOf(context)).toInt() : 160,
        errorBuilder: (_, __, ___) => errorWidget(),
      );
    } else if (url.startsWith('/') || url.contains(':\\') || url.contains(':/')) {
      return Image.file(
        File(url),
        fit: fit,
        width: width,
        height: height,
        cacheWidth: width != null ? (width! * MediaQuery.devicePixelRatioOf(context)).toInt() : 160,
        cacheHeight: height != null ? (height! * MediaQuery.devicePixelRatioOf(context)).toInt() : 160,
        errorBuilder: (_, __, ___) => errorWidget(),
      );
    } else if (url.startsWith('http://') || url.startsWith('https://')) {
      return Image.network(
        url,
        fit: fit,
        width: width,
        height: height,
        cacheWidth: width != null ? (width! * MediaQuery.devicePixelRatioOf(context)).toInt() : 160,
        cacheHeight: height != null ? (height! * MediaQuery.devicePixelRatioOf(context)).toInt() : 160,
        errorBuilder: (_, __, ___) => errorWidget(),
      );
    } else {
      return errorWidget();
    }
  }
}
