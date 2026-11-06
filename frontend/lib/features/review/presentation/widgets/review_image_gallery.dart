import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

void showReviewImagePreview(BuildContext context, String url) {
  showDialog<void>(
    context: context,
    builder: (dialogContext) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(12),
      child: GestureDetector(
        onTap: () => Navigator.of(dialogContext).pop(),
        child: InteractiveViewer(
          minScale: 0.8,
          maxScale: 4,
          child: Image.network(
            url,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: const Text(
                'Không tải được ảnh',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class ReviewImageGallery extends StatelessWidget {
  final List<String> images;
  final double size;
  final double spacing;

  const ReviewImageGallery({
    super.key,
    required this.images,
    this.size = 72,
    this.spacing = 8,
  });

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) return const SizedBox.shrink();
    final c = AppColors.of(context);

    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children: [
        for (final url in images)
          GestureDetector(
            onTap: () => showReviewImagePreview(context, url),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              child: Image.network(
                url,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: size,
                  height: size,
                  color: c.surfaceVariant,
                  child: Icon(Icons.broken_image_outlined, color: c.textMuted),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
