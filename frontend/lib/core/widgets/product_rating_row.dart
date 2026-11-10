import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Hang sao danh gia theo rating_avg / rating_count that tu backend.
class ProductRatingRow extends StatelessWidget {
  final double ratingAvg;
  final int ratingCount;
  final double iconSize;
  final double fontSize;

  const ProductRatingRow({
    super.key,
    required this.ratingAvg,
    required this.ratingCount,
    this.iconSize = 12,
    this.fontSize = 11,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    if (ratingCount <= 0) {
      return Text(
        'Chưa có đánh giá',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: fontSize,
          color: c.textMuted,
          fontWeight: FontWeight.w500,
        ),
      );
    }

    final avg = ratingAvg.clamp(0, 5).toDouble();
    final label = avg.toStringAsFixed(avg.truncateToDouble() == avg ? 0 : 1);

    return Row(
      children: [
        ...List.generate(5, (index) {
          final starValue = index + 1;
          IconData icon = Icons.star_border_rounded;
          if (avg >= starValue - 0.25) {
            icon = Icons.star_rounded;
          } else if (avg >= starValue - 0.75) {
            icon = Icons.star_half_rounded;
          }
          // Sao to bang mau ink chu khong phai c.secondary: tong accent be nhat
          // gan trung mau nen nen sao se chim hoan toan.
          return Icon(icon, size: iconSize, color: c.textPrimary);
        }),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Text(
            '$label ($ratingCount)',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: c.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
