import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../product/data/models/product_model.dart';
import '../../../product/presentation/pages/product_detail_page.dart';
import 'package:menly_app/core/widgets/app_image.dart';
import 'package:menly_app/core/widgets/section_header.dart';

class HomeRecentlyViewed extends StatelessWidget {
  final List<ProductModel> items;
  final VoidCallback onClear;

  const HomeRecentlyViewed({
    super.key,
    required this.items,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final c = AppColors.of(context);
    const tileWidth = 104.0;
    const imageHeight = 86.0;
    final tileRadius = BorderRadius.circular(AppTheme.radiusXl);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xl,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: SectionHeader(
            title: 'Đã xem gần đây',
            actionLabel: 'Xóa',
            onAction: onClear,
          ),
        ),
        SizedBox(
          height: 134,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
            itemBuilder: (ctx, i) {
              final item = items[i];
              return InkWell(
                borderRadius: tileRadius,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProductDetailPage(product: item),
                  ),
                ),
                child: Container(
                  width: tileWidth,
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: tileRadius,
                    border: Border.all(color: c.border),
                    // Bong rat nhe, chi du tach the khoi nen be.
                    boxShadow: [
                      BoxShadow(
                        color: c.shadow,
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Anh bo cung ban kinh the o hai goc tren.
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(AppTheme.radiusXl),
                        ),
                        child: AppImage(
                          url: item.thumbnailUrl,
                          width: tileWidth,
                          height: imageHeight,
                          fit: BoxFit.cover,
                          placeholder: (_) => Container(
                            width: tileWidth,
                            height: imageHeight,
                            color: c.surfaceVariant,
                          ),
                          errorWidget: (_) => Container(
                            width: tileWidth,
                            height: imageHeight,
                            color: c.surfaceVariant,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.sm,
                          AppSpacing.sm,
                          AppSpacing.sm,
                          AppSpacing.md,
                        ),
                        child: Text(
                          item.name,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: c.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}
