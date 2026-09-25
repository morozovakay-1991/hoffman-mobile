import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoffman/core/router/app_routes.dart';
import 'package:hoffman/core/theme/index.dart';
import 'package:hoffman/core/widgets/index.dart';
import 'package:hoffman/features/onboarding/data/onboarding_repository.dart';

/// One onboarding slide and the colors its controls use over the photo.
@immutable
class OnboardingSlide {
  const OnboardingSlide({
    required this.image,
    required this.imageAlignment,
    required this.title,
    required this.subtitle,
    required this.textColor,
    required this.skipColor,
    required this.nextVariant,
    this.imageWidthFactor,
  });

  final String image;

  /// Crop of the photo, taken from the mockup's image offsets.
  final Alignment imageAlignment;

  /// Figma `bg-size` width relative to the 393px frame, for slides whose
  /// photo is scaled past `cover`; null means `cover`.
  final double? imageWidthFactor;
  final String title;
  final String subtitle;
  final Color textColor;
  final Color skipColor;
  final AppButtonVariant nextVariant;
}

/// Onboarding, 4 slides — Figma 131:2735 (Медитации), 131:2755
/// (Инструменты), 131:2695 (Дневник), 131:2715 (Статьи). Shown once: the
/// flag is stored via [OnboardingRepository].
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  static const Key skipKey = ValueKey('onboarding-skip');
  static const Key nextKey = ValueKey('onboarding-next');

  static const List<OnboardingSlide> slides = [
    OnboardingSlide(
      image: 'assets/images/onboarding/onboarding_meditations.png',
      // Figma: 179% wide, shifted −55.8% → 70.6% of the overflow.
      imageAlignment: Alignment(0.41, 0),
      title: 'Медитации',
      subtitle: 'Практики для осознания,\nпроживания и восстановления',
      textColor: AppColors.basicBlack,
      skipColor: AppColors.background,
      nextVariant: AppButtonVariant.secondary,
    ),
    OnboardingSlide(
      image: 'assets/images/onboarding/onboarding_tools.png',
      imageAlignment: Alignment.topLeft,
      // Figma: bg-size 653×928 at top-left.
      imageWidthFactor: 653 / 393,
      title: 'Инструменты',
      subtitle: 'Упражнения для рефлексии,\nподдержки и изменений',
      textColor: AppColors.basicBlack,
      skipColor: AppColors.basicBlack,
      nextVariant: AppButtonVariant.primary,
    ),
    OnboardingSlide(
      image: 'assets/images/onboarding/onboarding_diary.png',
      imageAlignment: Alignment.topLeft,
      // Figma: bg-size 571×856.5 at top-left.
      imageWidthFactor: 571 / 393,
      title: 'Дневник',
      subtitle: 'Задания для фиксации,\nнаблюдения и отслеживания',
      textColor: AppColors.basicBlack,
      skipColor: AppColors.background,
      nextVariant: AppButtonVariant.primary,
    ),
    OnboardingSlide(
      image: 'assets/images/onboarding/onboarding_articles.png',
      // Figma: 162.6% wide, shifted −48.1% → 76.8% of the overflow.
      imageAlignment: Alignment(0.54, 0),
      title: 'Статьи',
      subtitle: 'Анонсы, новости\nи авторские тексты',
      textColor: AppColors.background,
      skipColor: AppColors.background,
      nextVariant: AppButtonVariant.secondary,
    ),
  ];

  static const Duration pageTransition = Duration(milliseconds: 300);

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool get _isLast => _page == OnboardingScreen.slides.length - 1;

  Future<void> _finish() async {
    await ref.read(onboardingRepositoryProvider).markSeen();
    ref.invalidate(onboardingSeenProvider);
    if (mounted) context.go(AppRoutes.login);
  }

  Future<void> _next() async {
    if (_isLast) {
      await _finish();
      return;
    }
    await _pageController.nextPage(
      duration: OnboardingScreen.pageTransition,
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final slide = OnboardingScreen.slides[_page];
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: OnboardingScreen.slides.length,
            onPageChanged: (page) => setState(() => _page = page),
            itemBuilder: (context, index) =>
                _SlideView(slide: OnboardingScreen.slides[index]),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'hoffman',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 57),
                  _ProgressIndicator(
                    count: OnboardingScreen.slides.length,
                    current: _page,
                  ),
                  const Spacer(),
                  _Controls(slide: slide, onSkip: _finish, onNext: _next),
                  const SizedBox(height: 56),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide});

  final OnboardingSlide slide;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (slide.imageWidthFactor case final factor?)
          ClipRect(
            child: LayoutBuilder(
              builder: (context, constraints) => OverflowBox(
                alignment: slide.imageAlignment,
                maxWidth: constraints.maxWidth * factor,
                maxHeight: double.infinity,
                child: Image.asset(
                  slide.image,
                  width: constraints.maxWidth * factor,
                  fit: BoxFit.fitWidth,
                ),
              ),
            ),
          )
        else
          Image.asset(
            slide.image,
            fit: BoxFit.cover,
            alignment: slide.imageAlignment,
          ),
        SafeArea(
          child: Align(
            // Figma: the title block sits slightly above the space between
            // the progress bar and the buttons.
            alignment: const Alignment(0, -0.1),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  slide.title,
                  textAlign: TextAlign.center,
                  style: textTheme.headlineLarge?.copyWith(
                    color: slide.textColor,
                    letterSpacing: -1.3,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  slide.subtitle,
                  textAlign: TextAlign.center,
                  style: textTheme.titleLarge?.copyWith(
                    color: slide.textColor,
                    height: 28 / 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Four 4px bars, 4px apart; the current one is black, the rest white.
class _ProgressIndicator extends StatelessWidget {
  const _ProgressIndicator({required this.count, required this.current});

  static const double height = 4;
  static const BorderRadius radius = BorderRadius.all(Radius.circular(5));

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Шаг ${current + 1} из $count',
      child: Row(
        children: [
          for (var i = 0; i < count; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: AnimatedContainer(
                duration: OnboardingScreen.pageTransition,
                height: height,
                decoration: BoxDecoration(
                  color: i == current
                      ? AppColors.basicBlack
                      : AppColors.background,
                  borderRadius: radius,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// "Пропустить" (left, centered in a 130px column) and "Далее" (130×28).
class _Controls extends StatelessWidget {
  const _Controls({
    required this.slide,
    required this.onSkip,
    required this.onNext,
  });

  static const double _width = 130;
  static const double _buttonHeight = 28;

  final OnboardingSlide slide;
  final VoidCallback onSkip;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SizedBox(
          width: _width,
          child: Center(
            child: GestureDetector(
              key: OnboardingScreen.skipKey,
              behavior: HitTestBehavior.opaque,
              onTap: onSkip,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Text(
                  'Пропустить',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: slide.skipColor),
                ),
              ),
            ),
          ),
        ),
        SizedBox(
          width: _width,
          height: _buttonHeight,
          child: AppButton(
            key: OnboardingScreen.nextKey,
            label: 'Далее',
            variant: slide.nextVariant,
            onPressed: onNext,
          ),
        ),
      ],
    );
  }
}
