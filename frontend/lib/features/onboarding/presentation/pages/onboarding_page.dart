import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/navigation/main_navigation_shell.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../home/data/models/banner_model.dart';
import '../../../product/data/models/category_model.dart';
import '../../../product/presentation/providers/product_provider.dart';
import 'package:menly_app/core/widgets/app_image.dart';

/// Man hinh gioi thieu (chi hien lan dau) duoc dung tu du lieu that:
/// banner dang hoat dong hoac danh muc san pham lay tu backend.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  static const String _seenKey = 'has_seen_onboarding';

  final PageController _controller = PageController();
  int _index = 0;
  bool _finishing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    if (_finishing) return;
    setState(() => _finishing = true);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_seenKey, true);
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (_, __, ___) => const MainNavigationShell(),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        ),
      ),
    );
  }

  void _next(int total) {
    if (_index >= total - 1) {
      _finish();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
    );
  }

  List<_IntroSlide> _buildSlides(ProductProvider provider) {
    final banners = provider.banners;
    if (banners.isNotEmpty) {
      return banners.map(_fromBanner).toList();
    }

    final categories = provider.categoryItems;
    if (categories.isNotEmpty) {
      return categories.take(5).map(_fromCategory).toList();
    }

    return const [_IntroSlide.fallback()];
  }

  _IntroSlide _fromBanner(BannerModel banner) {
    return _IntroSlide(
      imageUrl: banner.imageUrl,
      tag: 'BỘ SƯU TẬP',
      title: banner.title.isNotEmpty ? banner.title : 'Bộ sưu tập Menly',
      subtitle: 'Khám phá những thiết kế mới nhất dành cho phái mạnh.',
      icon: Icons.checkroom_rounded,
      colors: _gradients[banner.sortOrder % _gradients.length],
    );
  }

  _IntroSlide _fromCategory(CategoryModel category) {
    return _IntroSlide(
      tag: 'DANH MỤC',
      title: category.name,
      subtitle: 'Hàng chính hãng, cập nhật liên tục tại Menly.',
      icon: _iconFor(category.slug),
      colors: _gradients[category.sortOrder % _gradients.length],
    );
  }

  static const List<List<Color>> _gradients = [
    [Color(0xFF1C1B17), Color(0xFF4A3A28)],
    [Color(0xFF232019), Color(0xFF5A4632)],
    [Color(0xFF17140F), Color(0xFF3A3226)],
    [Color(0xFF2A2118), Color(0xFF6B5140)],
    [Color(0xFF1F1A14), Color(0xFF4A3E2E)],
  ];

  static IconData _iconFor(String slug) {
    switch (slug) {
      case 'ao-so-mi':
        return Icons.dry_cleaning_rounded;
      case 'ao-thun':
        return Icons.checkroom_rounded;
      case 'quan-jeans':
        return Icons.style_rounded;
      case 'quan-tay':
        return Icons.business_center_rounded;
      case 'ao-khoac':
        return Icons.ac_unit_rounded;
      default:
        return Icons.checkroom_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductProvider>();
    final slides = _buildSlides(provider);
    final index = _index.clamp(0, slides.length - 1);
    final slide = slides[index];
    final isLast = index >= slides.length - 1;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppTheme.primary,
        body: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              controller: _controller,
              itemCount: slides.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (_, i) => _SlideBackground(slide: slides[i]),
            ),
            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.55),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.30),
                      Colors.black.withValues(alpha: 0.94),
                    ],
                    stops: const [0.0, 0.28, 0.55, 1.0],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 14, 16, 0),
                    child: Row(
                      children: [
                        Text(
                          'MENLY',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.95),
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 5,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: _finish,
                          style: TextButton.styleFrom(
                            foregroundColor:
                                Colors.white.withValues(alpha: 0.85),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          child: const Text(
                            'Bỏ qua',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(26, 0, 26, 26),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _TagChip(label: slide.tag),
                        const SizedBox(height: 16),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 260),
                          layoutBuilder: (current, previous) => Stack(
                            alignment: Alignment.topLeft,
                            children: [
                              ...previous,
                              if (current != null) current
                            ],
                          ),
                          child: Column(
                            key: ValueKey(index),
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                slide.title,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 29,
                                  height: 1.16,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                slide.subtitle,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.78),
                                  fontSize: 14,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: List.generate(slides.length, (i) {
                            final active = i == index;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              width: active ? 22 : 6,
                              height: 6,
                              margin: const EdgeInsets.only(right: 6),
                              decoration: BoxDecoration(
                                color: active
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.32),
                                borderRadius: BorderRadius.circular(99),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 20),
                        PrimaryButton(
                          label: isLast ? 'Bắt đầu mua sắm' : 'Tiếp tục',
                          icon: isLast
                              ? Icons.shopping_bag_outlined
                              : Icons.arrow_forward_rounded,
                          loading: _finishing,
                          onPressed:
                              _finishing ? null : () => _next(slides.length),
                          background: Colors.white,
                          foreground: AppTheme.primary,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;

  const _TagChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.92),
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 2,
        ),
      ),
    );
  }
}

class _SlideBackground extends StatelessWidget {
  final _IntroSlide slide;

  const _SlideBackground({required this.slide});

  @override
  Widget build(BuildContext context) {
    final imageUrl = slide.imageUrl;

    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: slide.colors,
            ),
          ),
        ),
        if (imageUrl != null)
          AppImage(
            url: imageUrl,
            fit: BoxFit.cover,
            errorWidget: (_) => Center(
              child: Icon(
                slide.icon,
                size: 130,
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
            placeholder: (_) => Center(
              child: Icon(
                slide.icon,
                size: 130,
                color: Colors.white.withValues(alpha: 0.10),
              ),
            ),
          )
        else
          Center(
            child: Icon(
              slide.icon,
              size: 130,
              color: Colors.white.withValues(alpha: 0.12),
            ),
          ),
      ],
    );
  }
}

class _IntroSlide {
  final String? imageUrl;
  final String tag;
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> colors;

  const _IntroSlide({
    this.imageUrl,
    required this.tag,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.colors,
  });

  const _IntroSlide.fallback()
      : imageUrl = null,
        tag = 'MENLY',
        title = 'Chào mừng đến Menly',
        subtitle = 'Thời trang nam chuẩn mực phái mạnh.',
        icon = Icons.checkroom_rounded,
        colors = const [Color(0xFF1C1B17), Color(0xFF5A4632)];
}
