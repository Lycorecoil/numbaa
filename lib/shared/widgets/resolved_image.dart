import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/di/service_locator.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';

/// Renders a photo coming either from the device (a freshly picked file, or
/// a path stored by the offline mock repository) or from the backend (a
/// server-relative `/uploads/...` path returned by the upload endpoints).
///
/// Centralizing this here means the merchant's in-app preview and the
/// product list both resolve photos the same way, and a failed/broken image
/// always falls back to a clear icon instead of a Flutter error box.
class ResolvedImage extends StatelessWidget {
  final String path;
  final double? width;
  final double? height;
  final BoxFit fit;

  const ResolvedImage({
    super.key,
    required this.path,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  bool get _isServerPath => path.startsWith('/uploads');
  bool get _isAbsoluteUrl =>
      path.startsWith('http://') || path.startsWith('https://');

  @override
  Widget build(BuildContext context) {
    final errorIcon = Icon(
      Icons.broken_image_outlined,
      color: AppColors.neutralMid,
      size: (width != null && width! < 40) ? 16 : 24,
    );

    if (_isAbsoluteUrl || _isServerPath) {
      final url = _isAbsoluteUrl
          ? path
          : getIt<ApiClient>().resolveMediaUrl(path);
      return Image.network(
        url,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => errorIcon,
        // On a limited data connection the image can take a moment to
        // arrive — show a small spinner instead of a blank box so it never
        // looks like the photo silently failed, then fade the photo in
        // once it lands instead of popping in abruptly.
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Center(
            child: SizedBox(
              width: (width != null && width! < 40) ? 14 : 18,
              height: (width != null && width! < 40) ? 14 : 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.neutralMid.withValues(alpha: 0.5),
                value: progress.expectedTotalBytes != null
                    ? progress.cumulativeBytesLoaded /
                        progress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded) return child;
          return AnimatedOpacity(
            opacity: frame == null ? 0 : 1,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            child: child,
          );
        },
      );
    }

    // Anything else is a local on-device file path (either a photo just
    // picked and not yet uploaded, or the mock repository's offline path).
    return Image.file(
      File(path),
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) => errorIcon,
    );
  }
}
