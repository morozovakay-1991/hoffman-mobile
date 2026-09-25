import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoffman/core/config/feature_flags.dart';
import 'package:hoffman/core/router/app_routes.dart';
import 'package:hoffman/core/theme/index.dart';
import 'package:hoffman/core/widgets/index.dart';
import 'package:hoffman/features/auth/application/auth_controller.dart';
import 'package:hoffman/features/onboarding/data/onboarding_repository.dart';

/// Splash: logo (Figma 131:2674 `Loading 1`) → wordmark (131:2679
/// `Loading 2`) → statistics (131:2685 `Loading 3`), while the session is
/// restored via `GET /auth/me`. Then routes to home (signed in), onboarding
/// (first launch) or login. A failed restore (offline) shows a retry.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  /// How long each phase stays on screen; the last one lasts until the
  /// session check finishes.
  static const List<Duration> phaseDurations = [
    Duration(milliseconds: 1000),
    Duration(milliseconds: 1000),
    Duration(milliseconds: 1800),
  ];

  static const Duration fadeDuration = Duration(milliseconds: 400);

  static Duration get totalDuration =>
      phaseDurations.fold(Duration.zero, (sum, d) => sum + d);

  static const String backgroundAsset =
      'assets/images/splash/splash_background.png';
  static const String logoAsset = 'assets/images/splash/hoffman_logo.png';

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  int _phase = 0;
  Timer? _timer;
  bool _animationDone = false;
  String? _target;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _schedulePhase();
    unawaited(_resolveTarget());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _schedulePhase() {
    _timer = Timer(SplashScreen.phaseDurations[_phase], () {
      if (_phase < SplashScreen.phaseDurations.length - 1) {
        setState(() => _phase++);
        _schedulePhase();
      } else {
        _animationDone = true;
        _navigateIfReady();
      }
    });
  }

  Future<void> _resolveTarget() async {
    try {
      final auth = await ref.read(authControllerProvider.future);
      final onboardingSeen = await ref.read(onboardingSeenProvider.future);
      // Warm the flag up so Login/the router see the fetched value.
      await ref.read(registrationEnabledProvider.future);

      _target = switch (auth) {
        Authenticated() => AppRoutes.home,
        Unauthenticated() when !onboardingSeen => AppRoutes.onboarding,
        Unauthenticated() => AppRoutes.login,
      };
      _navigateIfReady();
    } on Object {
      if (mounted) setState(() => _failed = true);
    }
  }

  void _navigateIfReady() {
    if (!mounted || !_animationDone || _target == null) return;
    context.go(_target!);
  }

  void _retry() {
    ref.invalidate(authControllerProvider);
    setState(() => _failed = false);
    unawaited(_resolveTarget());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _SplashBackground(),
          // Figma centers the phases on the whole frame, not the safe area.
          if (_failed)
            SafeArea(
              child: ErrorStateWidget(
                message: 'Нет соединения с интернетом',
                onRetry: _retry,
              ),
            )
          else
            AnimatedSwitcher(
              duration: SplashScreen.fadeDuration,
              child: KeyedSubtree(
                key: ValueKey(_phase),
                child: switch (_phase) {
                  0 => const _Logo(),
                  1 => const _Wordmark(),
                  _ => const _Statistics(),
                },
              ),
            ),
        ],
      ),
    );
  }
}

/// The flower photo at 20% opacity over white, cropped exactly like the
/// Figma `CROP` image fill of 131:2674 (a rotated crop).
class _SplashBackground extends StatelessWidget {
  const _SplashBackground();

  /// Figma `imageTransform`: maps frame-normalized coordinates (u, v) to
  /// image-normalized ones — `image = A · (u, v) + t`.
  static const double _a = 0.45181095600128174;
  static const double _b = 0.3245818316936493;
  static const double _tx = 0.0041295001283288;
  static const double _c = -0.10557114332914352;
  static const double _d = 0.6906721591949463;
  static const double _ty = 0.20737136900424957;

  /// The inverse mapping in pixels: the image, stretched over a w×h box, is
  /// placed so that each frame pixel shows the image point Figma shows.
  static Matrix4 _transform(double w, double h) {
    const det = _a * _d - _b * _c;
    const ia = _d / det;
    const ib = -_b / det;
    const ic = -_c / det;
    const id = _a / det;
    // p = S · A⁻¹ · (S⁻¹ · q − t), with S = diag(w, h).
    return Matrix4(
      ia,
      ic * h / w,
      0,
      0, //
      ib * w / h,
      id,
      0,
      0,
      0,
      0,
      1,
      0,
      -(ia * _tx + ib * _ty) * w,
      -(ic * _tx + id * _ty) * h,
      0,
      1,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        return Opacity(
          opacity: 0.2,
          child: ClipRect(
            child: OverflowBox(
              alignment: Alignment.topLeft,
              maxWidth: w,
              maxHeight: h,
              child: Transform(
                transform: _transform(w, h),
                child: Image.asset(
                  SplashScreen.backgroundAsset,
                  width: w,
                  height: h,
                  fit: BoxFit.fill,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// `HP LOGO com 1`, 45×46, centered.
class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Image.asset(SplashScreen.logoAsset, width: 45, height: 46),
    );
  }
}

class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('hoffman', style: Theme.of(context).textTheme.headlineLarge),
    );
  }
}

/// `Loading 3`: countries, participants and the recommendation rate.
class _Statistics extends StatelessWidget {
  const _Statistics();

  /// Width of the bottom paragraph in the mockup.
  static const double _paragraphWidth = 361;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('16 стран', style: textTheme.headlineLarge),
          const SizedBox(height: AppSpacing.xl),
          Text(
            '150 000\nучастников',
            textAlign: TextAlign.center,
            style: textTheme.titleLarge?.copyWith(height: 28 / 20),
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: _paragraphWidth,
            child: Text(
              '97% всех участников рекомендуют Процесс Хоффмана своим '
              'родным, друзьям, коллегам',
              textAlign: TextAlign.center,
              style: textTheme.labelLarge?.copyWith(height: 20 / 14),
            ),
          ),
        ],
      ),
    );
  }
}
