import 'package:flutter/material.dart';
import 'package:hoffman/core/theme/index.dart';
import 'package:hoffman/core/widgets/index.dart';
import 'package:hoffman/features/home/presentation/home_text.dart';

// Building blocks of the home screen (Figma 612:7209): the promo cover that
// opens every section, the featured item under it and the diary progress
// panel.

/// A content cover loaded from [url], or the bundled [fallback] image when
/// there is no URL or it cannot be loaded (e.g. offline).
class HomeCoverImage extends StatelessWidget {
  const HomeCoverImage({required this.url, required this.fallback, super.key});

  final Uri? url;

  /// Asset path of the section's stock image.
  final String fallback;

  @override
  Widget build(BuildContext context) {
    final asset = Image.asset(fallback, fit: BoxFit.cover);
    final url = this.url;
    if (url == null) return asset;

    return Image.network(
      url.toString(),
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => asset,
    );
  }
}

/// Section promo cover, e.g. `Медитации` (612:7219): a 350px image with the
/// section title, the `все` badge leading to the full list, and a subtitle.
///
/// The image is the cover of the section's featured item ([imageUrl]),
/// falling back to the stock [image]. With [onTap] the cover opens that
/// item; the `все` badge keeps leading to the list. The section's own list
/// screen heads with it too, without the badge ([onSeeAll] `null`).
class HomeSectionCover extends StatelessWidget {
  const HomeSectionCover({
    required this.image,
    required this.title,
    required this.subtitle,
    required this.onSeeAll,
    super.key,
    this.imageUrl,
    this.onTap,
    this.tapLabel,
    this.coverKey,
    this.seeAllKey,
    this.foreground = AppColors.background,
    this.shaded = false,
  });

  static const double height = 350;

  /// Figma `Text/Display` has -4% tracking on the covers.
  static const double _titleTracking = -1.28;

  /// Subtitle `Secondary` style: 14px Medium on a 20px line.
  static const double _subtitleLineHeight = 20 / 14;

  /// Top of the 30% black gradient behind white text (612:7219).
  static const Color _shade = Color(0x4D000000);

  /// Asset path of the stock image.
  final String image;
  final Uri? imageUrl;
  final String title;
  final String subtitle;

  /// Leads to the full list; `null` hides the `все` badge.
  final VoidCallback? onSeeAll;

  /// Opens the featured item; `null` leaves the cover inert.
  final VoidCallback? onTap;

  /// Screen reader label of [onTap], e.g. the featured item's title.
  final String? tapLabel;
  final Key? coverKey;
  final Key? seeAllKey;

  /// Title and subtitle color: white on the dark covers, black on the light
  /// `Инструменты` one.
  final Color foreground;

  /// Adds the top gradient that keeps white text readable on a light image.
  final bool shaded;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final onTap = this.onTap;

    final cover = SizedBox(
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          HomeCoverImage(url: imageUrl, fallback: image),
          if (onTap != null)
            // The gesture is on the whole cover (below); this node only
            // exposes it to screen readers apart from the title and badge.
            Semantics(
              button: true,
              label: tapLabel,
              onTap: onTap,
              child: const SizedBox.expand(),
            ),
          if (shaded)
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [_shade, Color(0x00000000)],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.xl,
              AppSpacing.md,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: Text(
                          title,
                          style: textTheme.headlineLarge?.copyWith(
                            color: foreground,
                            letterSpacing: _titleTracking,
                          ),
                        ),
                      ),
                    ),
                    if (onSeeAll case final onSeeAll?) ...[
                      const SizedBox(width: AppSpacing.md),
                      Semantics(
                        button: true,
                        label:
                            '${HomeText.seeAll}: '
                            '${title.replaceAll('\n', ' ')}',
                        excludeSemantics: true,
                        child: AppBadge(
                          key: seeAllKey,
                          label: HomeText.seeAll,
                          onTap: onSeeAll,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  subtitle,
                  style: textTheme.labelLarge?.copyWith(
                    color: foreground,
                    height: _subtitleLineHeight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return cover;

    // Outside the badge, whose own tap wins inside it.
    return GestureDetector(
      key: coverKey,
      behavior: HitTestBehavior.opaque,
      excludeFromSemantics: true,
      onTap: onTap,
      child: cover,
    );
  }
}

/// The featured item of a section, e.g. `Утренняя медитация`
/// (612:7228) or `Распознавание паттернов` (612:7751): a tinted panel with
/// the title, the description next to a [trailing] detail (duration, date,
/// stage badge) and a 130px action button.
class HomeFeaturedItem extends StatelessWidget {
  const HomeFeaturedItem({
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.onTap,
    super.key,
    this.subtitle,
    this.trailing,
    this.actionIcon = Icons.arrow_forward_rounded,
    this.color = AppColors.background,
    this.actionVariant = AppButtonVariant.primary,
    this.isLocked = false,
  });

  static const double buttonHeight = 28;
  static const int _descriptionMaxLines = 7;

  final String title;
  final String? subtitle;
  final String description;
  final Widget? trailing;
  final String actionLabel;
  final IconData actionIcon;
  final Color color;
  final AppButtonVariant actionVariant;
  final bool isLocked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final subtitle = this.subtitle;
    final trailing = this.trailing;

    return Material(
      color: color,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: Text(title, style: textTheme.titleLarge)),
                  if (isLocked) ...[
                    const SizedBox(width: AppSpacing.sm),
                    const LockedMark(),
                  ],
                ],
              ),
              if (subtitle != null && subtitle.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(subtitle, style: textTheme.bodySmall),
              ],
              const SizedBox(height: AppSpacing.lg),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      description,
                      maxLines: _descriptionMaxLines,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.softBlack,
                      ),
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: AppSpacing.md),
                    trailing,
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: AppButton.minWidth,
                height: buttonHeight,
                child: AppButton(
                  label: actionLabel,
                  variant: actionVariant,
                  trailingIcon: actionIcon,
                  onPressed: onTap,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Icon + text" detail next to a featured description: `25 минут`,
/// `Март, 2025`.
class HomeMetaLabel extends StatelessWidget {
  const HomeMetaLabel({required this.icon, required this.text, super.key});

  static const double iconSize = 16;

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: iconSize, color: AppColors.basicBlack),
        const SizedBox(width: AppSpacing.xs),
        Text(text, style: Theme.of(context).textTheme.labelMedium),
      ],
    );
  }
}

/// Full-width 0.5px divider between the cards of a section (`Line 9`).
class HomeDivider extends StatelessWidget {
  const HomeDivider({super.key});

  static const double thickness = 0.5;

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: thickness,
      thickness: thickness,
      color: AppColors.basicBlack,
    );
  }
}

/// A section that came back without items.
class HomeSectionEmpty extends StatelessWidget {
  const HomeSectionEmpty({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xl,
      ),
      child: Text(
        HomeText.sectionEmpty,
        style: Theme.of(context).textTheme.bodySmall
            ?.copyWith(color: AppColors.softBlack),
      ),
    );
  }
}

/// Progress of the current diary day (612:7386): `День 25`, `из 100` and
/// an 8px bar filled to [value].
class DiaryProgressBar extends StatelessWidget {
  const DiaryProgressBar({
    required this.day,
    required this.totalDays,
    required this.value,
    super.key,
  });

  static const double barHeight = 8;
  static const double borderWidth = 0.5;
  static const BorderRadius _radius = BorderRadius.all(Radius.circular(5));

  final int day;
  final int totalDays;

  /// 0–1.
  final double value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      label: '${HomeText.day(day)} ${HomeText.ofTotal(totalDays)}',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(HomeText.day(day), style: textTheme.titleLarge),
          const SizedBox(height: AppSpacing.lg),
          Text(HomeText.ofTotal(totalDays), style: textTheme.labelMedium),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: barHeight,
            child: Stack(
              fit: StackFit.expand,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    border: Border.all(width: borderWidth),
                    borderRadius: _radius,
                  ),
                ),
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: value.clamp(0, 1),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.basicBlack,
                      border: Border.all(width: borderWidth),
                      borderRadius: _radius,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
