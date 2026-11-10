import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/banner_model.dart';
import 'package:menly_app/core/widgets/app_image.dart';

class HomeBannerSlider extends StatelessWidget {
  final PageController controller;
  final List<BannerModel> banners;
  final int currentIndex;
  final ValueChanged<int> onPageChanged;

  const HomeBannerSlider({
    super.key,
    required this.controller,
    required this.banners,
    required this.currentIndex,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (banners.isEmpty) return const SizedBox.shrink();

    final c = AppColors.of(context);
    // Anh lon bo goc manh: cung mot ban kinh cho anh, lop phu va vung cham.
    final bannerRadius = BorderRadius.circular(AppTheme.radiusXl);

    return Column(
      children: [
        SizedBox(
          height: 170,
          child: PageView.builder(
            controller: controller,
            itemCount: banners.length,
            onPageChanged: onPageChanged,
            itemBuilder: (ctx, i) {
              final b = banners[i];
              final anhNen = appImageProvider(b.imageUrl);
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                decoration: BoxDecoration(
                  color: c.surfaceVariant,
                  borderRadius: bannerRadius,
                  image: anhNen == null
                      ? null
                      : DecorationImage(image: anhNen, fit: BoxFit.cover),
                  // Bong rat nhe: anh tu noi len khoi nen, khong vien cung.
                  boxShadow: [
                    BoxShadow(
                      color: c.shadow,
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    borderRadius: bannerRadius,
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.75),
                        Colors.transparent,
                      ],
                      begin: Alignment.bottomLeft,
                      end: Alignment.topRight,
                    ),
                  ),
                  alignment: Alignment.bottomLeft,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nhan nho dang vien thuoc de len anh.
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: c.danger,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusPill),
                        ),
                        child: Text(
                          'BỘ SƯU TẬP MỚI',
                          style: TextStyle(
                            color: c.onInk,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        b.title,
                        style: TextStyle(
                          color: c.onInk,
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                          letterSpacing: -0.3,
                          // Bong chu do tren anh, giu mau den nhu lop phu
                          shadows: const [
                            Shadow(color: Colors.black54, blurRadius: 4),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            banners.length,
            (idx) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: currentIndex == idx ? 18 : 6,
              height: 6,
              margin: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: currentIndex == idx ? c.primary : c.border,
                borderRadius: BorderRadius.circular(AppTheme.radiusPill),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
