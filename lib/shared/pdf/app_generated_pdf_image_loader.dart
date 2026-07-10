import 'dart:typed_data';

import 'app_generated_pdf_export_estimator.dart';

typedef AppGeneratedPdfImageLoader =
    Future<Uint8List?> Function({
      required String attachmentId,
      required AppGeneratedPdfExportMode mode,
    });

typedef AppGeneratedPdfImageCacheRead =
    Future<Uint8List?> Function(String cacheKey);

typedef AppGeneratedPdfImageCacheWrite =
    Future<void> Function(String cacheKey, Uint8List bytes);

class AppGeneratedPdfImageResolutionException implements Exception {
  const AppGeneratedPdfImageResolutionException(this.reasonCode);

  final String reasonCode;

  @override
  String toString() => 'PDF image resolution failed: $reasonCode';
}

class AppGeneratedPdfImageResolver {
  const AppGeneratedPdfImageResolver({
    required this.fetch,
    this.cacheRead,
    this.cacheWrite,
  });

  static const maxThumbnailBytes = 4 * 1024 * 1024;
  static const maxFullImageBytes = 12 * 1024 * 1024;

  final AppGeneratedPdfImageLoader fetch;
  final AppGeneratedPdfImageCacheRead? cacheRead;
  final AppGeneratedPdfImageCacheWrite? cacheWrite;

  Future<Uint8List> resolve({
    required String attachmentId,
    required AppGeneratedPdfExportMode mode,
    bool allowFullImageDownload = false,
  }) async {
    final cacheKey = '$attachmentId:${mode.name}';
    final cached = await cacheRead?.call(cacheKey);
    if (cached != null && cached.isNotEmpty) {
      _validateBytes(cached, mode);
      return cached;
    }
    if (mode == AppGeneratedPdfExportMode.fullImages &&
        !allowFullImageDownload) {
      throw const AppGeneratedPdfImageResolutionException(
        'full_image_download_requires_explicit_selection',
      );
    }
    final fetched = await fetch(attachmentId: attachmentId, mode: mode);
    if (fetched == null || fetched.isEmpty) {
      throw const AppGeneratedPdfImageResolutionException('image_unavailable');
    }
    _validateBytes(fetched, mode);
    try {
      await cacheWrite?.call(cacheKey, fetched);
    } catch (_) {
      // Caching is an optimization; PDF generation must still finish.
    }
    return fetched;
  }

  static void _validateBytes(Uint8List bytes, AppGeneratedPdfExportMode mode) {
    final limit = mode == AppGeneratedPdfExportMode.thumbnails
        ? maxThumbnailBytes
        : maxFullImageBytes;
    if (bytes.lengthInBytes > limit) {
      throw AppGeneratedPdfImageResolutionException(
        mode == AppGeneratedPdfExportMode.thumbnails
            ? 'thumbnail_too_large'
            : 'full_image_too_large',
      );
    }
  }
}
