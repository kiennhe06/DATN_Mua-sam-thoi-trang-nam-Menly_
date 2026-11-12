import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import 'package:menly_app/core/widgets/app_image.dart';

void showReviewImagePreview(BuildContext context, String url) {
  final c = AppColors.of(context);
  showDialog<void>(
    context: context,
    builder: (dialogContext) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(AppSpacing.md),
      child: GestureDetector(
        onTap: () => Navigator.of(dialogContext).pop(),
        child: InteractiveViewer(
          minScale: 0.8,
          maxScale: 4,
          child: AppImage(
            url: url,
            fit: BoxFit.contain,
            errorWidget: (_) => Container(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              decoration: BoxDecoration(
                color: c.inkCard,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Text(
                'Không tải được ảnh',
                style: TextStyle(color: c.onInk),
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
    this.spacing = AppSpacing.sm,
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
              child: AppImage(
                url: url,
                width: size,
                height: size,
                fit: BoxFit.cover,
                placeholder: (_) => Container(
                  width: size,
                  height: size,
                  color: c.surfaceVariant,
                ),
                errorWidget: (_) => Container(
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
