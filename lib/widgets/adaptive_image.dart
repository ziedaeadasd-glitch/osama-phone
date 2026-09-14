import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

/// ويدجت ذكي لعرض الصور من أي مصدر (روابط إنترنت، Base64 محلي، أو بيانات مدمجة)
class AdaptiveImageWidget extends StatelessWidget {
  final String? imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? placeholder;
  final BorderRadius? borderRadius;

  const AdaptiveImageWidget({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholder,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    Widget imageWidget = _buildImageContent();
    if (borderRadius != null) {
      imageWidget = ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }
    return SizedBox(
      width: width,
      height: height,
      child: imageWidget,
    );
  }

  Widget _buildImageContent() {
    if (imageUrl == null || imageUrl!.trim().isEmpty) {
      return placeholder ?? _defaultPlaceholder();
    }

    final src = imageUrl!.trim();

    // 1. صورة بصيغة Data URI أو Base64
    if (src.startsWith('data:image') || (!src.startsWith('http') && src.length > 100)) {
      try {
        String base64Str = src;
        if (src.contains('base64,')) {
          base64Str = src.split('base64,').last;
        }
        final Uint8List bytes = base64Decode(base64Str.trim());
        return Image.memory(
          bytes,
          fit: fit,
          width: width,
          height: height,
          errorBuilder: (ctx, err, stack) => placeholder ?? _defaultPlaceholder(),
        );
      } catch (e) {
        return placeholder ?? _defaultPlaceholder();
      }
    }

    // 2. صورة برابط إنترنت عادي
    if (src.startsWith('http://') || src.startsWith('https://')) {
      return Image.network(
        src,
        fit: fit,
        width: width,
        height: height,
        loadingBuilder: (ctx, child, progress) {
          if (progress == null) return child;
          return Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                value: progress.expectedTotalBytes != null
                    ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                    : null,
                color: const Color(0xFF0EA5E9),
              ),
            ),
          );
        },
        errorBuilder: (ctx, err, stack) => placeholder ?? _defaultPlaceholder(),
      );
    }

    return placeholder ?? _defaultPlaceholder();
  }

  Widget _defaultPlaceholder() {
    return Container(
      color: const Color(0xFF0F172A),
      alignment: Alignment.center,
      child: const Icon(
        Icons.phone_android,
        color: Colors.white24,
        size: 36,
      ),
    );
  }
}
