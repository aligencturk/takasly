import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:takasly/core/http_headers.dart';
import 'package:takasly/utils/logger.dart';

class AppNetworkImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadiusGeometry? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;

  const AppNetworkImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
  });

  bool _isValidUrl(String url) {
    if (url.isEmpty || url == 'null' || url == 'undefined') return false;
    try {
      final uri = Uri.parse(url);
      return uri.scheme == 'http' || uri.scheme == 'https';
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isValidUrl(imageUrl)) {
      return _wrap(
        Container(
          width: width,
          height: height,
          color: Colors.grey[100],
          child: const Icon(
            Icons.image_not_supported_outlined,
            color: Colors.grey,
            size: 20,
          ),
        ),
      );
    }

    final image = CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      httpHeaders: HttpHeadersUtil.basicAuthHeaders(),
      placeholder: (context, url) => placeholder ?? _defaultPlaceholder(),
      errorWidget: (context, url, error) {
        Logger.warning('Görsel yüklenemedi: $url -> $error');
        return errorWidget ?? _defaultError();
      },
    );

    return borderRadius != null
        ? ClipRRect(borderRadius: borderRadius!, child: image)
        : image;
  }

  Widget _wrap(Widget child) {
    if (borderRadius == null) return child;
    return ClipRRect(borderRadius: borderRadius!, child: child);
  }

  Widget _defaultPlaceholder() => Container(
    width: width,
    height: height,
    color: Colors.grey[200],
    child: const Center(
      child: SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    ),
  );

  Widget _defaultError() => Container(
    width: width,
    height: height,
    color: Colors.grey[300],
    child: const Icon(Icons.broken_image, color: Colors.grey, size: 24),
  );
}
