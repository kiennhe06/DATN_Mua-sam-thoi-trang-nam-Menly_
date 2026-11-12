import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/navigation/main_navigation_shell.dart';
import '../../../../core/navigation/staff_navigation_shell.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../product/presentation/providers/product_provider.dart';
import 'onboarding_page.dart';

/// Man cho khi mo app: doi du lieu that tu backend (banner, danh muc, san pham)
/// nap xong roi moi vao man gioi thieu / trang chu.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  static const Duration _minimumDisplay = Duration(milliseconds: 1800);
  static const Duration _dataTimeout = Duration(seconds: 6);

  late final AnimationController _progressController;

  double _progress = 0;
  bool _entered = false;
  bool _navigating = false;
  String _status = 'Đang kết nối cửa hàng Menly...';

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )
      ..addListener(() {
        if (!mounted) return;
        setState(() => _progress = _progressController.value * 0.9);
      })
      ..forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _entered = true);
      _bootstrap();
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final productProv = context.read<ProductProvider>();
    final startedAt = DateTime.now();
    var failed = false;

    try {
      await productProv.ensureInitialized().timeout(_dataTimeout);
    } catch (_) {
      failed = true;
    }

    final remaining = _minimumDisplay - DateTime.now().difference(startedAt);
    if (remaining > Duration.zero) {
      await Future<void>.delayed(remaining);
    }
    if (!mounted) return;

    final productCount = productProv.totalProductCount;
    final categoryCount = productProv.categoryCount;
    final isReady = !failed && productCount > 0;

    setState(() {
      _status = isReady
          ? 'Đã sẵn sàng • $productCount sản phẩm • $categoryCount danh mục'
          : 'Chưa kết nối được máy chủ, đang mở ứng dụng...';
    });

    await _progressController.animateTo(
      1,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
    );
    if (!mounted) return;
    await Future<void>.delayed(const Duration(milliseconds: 220));
    if (!mounted || _navigating) return;

    _navigating = true;

    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;
    if (!mounted) return;

    final authProv = context.read<AuthProvider>();
    if (authProv.user == null) {
      await authProv.loadProfile();
    }
    if (!mounted) return;

    final Widget next;
    if (authProv.isLoggedIn && authProv.user?.role == 'staff') {
      next = const StaffNavigationShell();
    } else {
      next = hasSeenOnboarding
          ? const MainNavigationShell()
          : const OnboardingPage();
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (_, __, ___) => next,
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: c.inkCard,
        body: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/splash_bg.jpg',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    c.inkCard.withValues(alpha: 0.45),
                    c.inkCard.withValues(alpha: 0.30),
                    c.inkCard.withValues(alpha: 0.94),
                  ],
                  stops: const [0.0, 0.42, 1.0],
                ),
              ),
            ),
            SafeArea(
              child: AnimatedOpacity(
                opacity: _entered ? 1 : 0,
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOut,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xxl,
                    AppSpacing.xxl,
                    AppSpacing.xxl,
                    AppSpacing.xxxl,
                  ),
                  child: Column(
                    children: [
                      const _TopMark(),
                      const Spacer(),
                      const _BrandBlock(),
                      const Spacer(),
                      _LoadingBlock(
                        progress: _progress,
                        status: _status,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopMark extends StatelessWidget {
  const _TopMark();

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: c.onInk.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            border: Border.all(color: c.onInk.withValues(alpha: 0.25)),
          ),
          child: Text(
            'M',
            style: TextStyle(
              color: c.onInk,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          'MENLY',
          style: TextStyle(
            color: c.onInk.withValues(alpha: 0.92),
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 4,
          ),
        ),
        const Spacer(),
        Text(
          'EST. 2025',
          style: TextStyle(
            color: c.onInk.withValues(alpha: 0.55),
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }
}

class _BrandBlock extends StatelessWidget {
  const _BrandBlock();

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 82,
          height: 82,
          decoration: BoxDecoration(
            color: c.onInk,
            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
            boxShadow: [
              // Lop phu toi duoi logo de noi bat tren anh nen.
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.28),
                blurRadius: 26,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Icon(
            Icons.checkroom_rounded,
            color: c.inkCard,
            size: 40,
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        Text(
          'MENLY',
          style: TextStyle(
            color: c.onInk,
            fontSize: 34,
            fontWeight: FontWeight.w900,
            letterSpacing: 12,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'FASHION FOR MEN',
          style: TextStyle(
            color: c.onInk.withValues(alpha: 0.72),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 5,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Container(
          width: 34,
          height: 2,
          decoration: BoxDecoration(
            color: c.onInk.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Chuẩn mực phái mạnh',
          style: TextStyle(
            color: c.onInk.withValues(alpha: 0.82),
            fontSize: 13,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _LoadingBlock extends StatelessWidget {
  final double progress;
  final String status;

  const _LoadingBlock({required this.progress, required this.status});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusPill),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 3,
            backgroundColor: c.onInk.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(c.onInk),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: Text(
            status,
            key: ValueKey(status),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: c.onInk.withValues(alpha: 0.8),
              fontSize: 12.5,
              height: 1.4,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ],
    );
  }
}
