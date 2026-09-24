import 'package:flutter/material.dart';
import 'package:hoffman/core/theme/index.dart';
import 'package:hoffman/core/widgets/app_badge.dart';

// Content cards from the Figma `Components` section (node 1:2). Icons are the
// closest Material Icons until the exact SVG assets are exported.

/// Width of the details column and of the action link row in every card.
const double _detailsWidth = 184;
const double _iconSize = 16;

/// Meditation card, Figma node 132:5273 (`meditation card`).
///
/// Title on top; below it the square [cover] with a play icon (left) and the
/// details column (right): duration, description and the action link. The
/// whole card handles [onTap].
class MeditationCard extends StatelessWidget {
  const MeditationCard({
    required this.title,
    required this.cover,
    required this.duration,
    required this.description,
    required this.actionLabel,
    super.key,
    this.onTap,
  });

  static const double coverSize = 138;
  static const double playIconSize = 24;

  final String title;

  /// Cover image, clipped to a [coverSize] square.
  final Widget cover;

  /// Duration text next to the clock icon, e.g. `25 минут`.
  final String duration;
  final String description;
  final String actionLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return _Tappable(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardTitle(title),
          const SizedBox(height: AppSpacing.xl),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox.square(
                dimension: coverSize,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRect(child: cover),
                    const Center(
                      child: Icon(
                        Icons.play_arrow_rounded,
                        size: playIconSize,
                        color: AppColors.background,
                      ),
                    ),
                  ],
                ),
              ),
              _DetailsColumn(
                children: [
                  _MetaRow(icon: Icons.watch_later, text: duration),
                  _Description(description),
                  _ActionLink(actionLabel),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Article list card, Figma node 132:5127 (`article list card`).
///
/// Top divider, then the title; below it the details column (date,
/// description, action link) on the left and the [cover] on the right. The
/// whole card handles [onTap].
class ArticleListCard extends StatelessWidget {
  const ArticleListCard({
    required this.title,
    required this.cover,
    required this.date,
    required this.description,
    required this.actionLabel,
    super.key,
    this.onTap,
  });

  static const Size coverSize = Size(138, 110);

  final String title;

  /// Cover image, clipped to [coverSize].
  final Widget cover;

  /// Date text next to the calendar icon, e.g. `Март, 2025`.
  final String date;
  final String description;
  final String actionLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return _ListCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardTitle(title),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DetailsColumn(
                children: [
                  _MetaRow(icon: Icons.calendar_month, text: date),
                  _Description(description),
                  _ActionLink(actionLabel),
                ],
              ),
              SizedBox.fromSize(
                size: coverSize,
                child: ClipRect(child: cover),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Tool list card, Figma node 132:5143 (`tool list card`).
///
/// Top divider, title, then the description with a [tag] [AppBadge]
/// ([AppBadgeVariant.tinted]) on its right, then the action link. The whole
/// card handles [onTap].
class ToolListCard extends StatelessWidget {
  const ToolListCard({
    required this.title,
    required this.description,
    required this.tag,
    required this.actionLabel,
    super.key,
    this.onTap,
  });

  final String title;
  final String description;
  final String tag;
  final String actionLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return _ListCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardTitle(title),
          const SizedBox(height: AppSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _Description(description)),
              // TODO(figma): the mockup gives the text a fixed 231px width;
              // the minimum gap before the badge is not defined.
              const SizedBox(width: AppSpacing.md),
              AppBadge(label: tag, variant: AppBadgeVariant.tinted),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _ActionLink(actionLabel),
        ],
      ),
    );
  }
}

/// Theme list card, Figma nodes 132:5174 (`theme list card folded`) and
/// 132:5157 (`theme list card unfolded`).
///
/// Top divider in both states. Folded: title with a `+` icon and the
/// [subtitle]. Expanded: a `–` icon instead of `+`, then the [cover] next to
/// the multi-paragraph [body] and the action link. The whole card handles
/// [onTap]; the owner toggles [isExpanded].
class ThemeListCard extends StatelessWidget {
  const ThemeListCard({
    required this.title,
    required this.subtitle,
    required this.cover,
    required this.body,
    required this.actionLabel,
    super.key,
    this.isExpanded = false,
    this.onTap,
  });

  static const double coverSize = 130;

  /// `add_2` icon size (folded, node 2:420).
  static const double expandIconSize = 24;

  /// `check_indeterminate_small` icon size (unfolded, node 2:185).
  static const double collapseIconSize = 16;

  /// Figma: the header icon starts 12px below the title top, and the
  /// subtitle starts 36px below it.
  static const double _headerIconTop = 12;
  static const double _headerHeight = 36;

  final String title;
  final String subtitle;

  /// Cover image, clipped to a [coverSize] square. Shown when expanded.
  final Widget cover;

  /// Long text shown when expanded; separate paragraphs with `\n`.
  final String body;
  final String actionLabel;
  final bool isExpanded;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return _ListCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: _headerHeight),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _CardTitle(title)),
                Padding(
                  padding: const EdgeInsets.only(top: _headerIconTop),
                  child: isExpanded
                      ? const Icon(
                          Icons.remove,
                          size: collapseIconSize,
                          color: AppColors.basicBlack,
                        )
                      : const Icon(
                          Icons.add,
                          size: expandIconSize,
                          color: AppColors.basicBlack,
                        ),
                ),
              ],
            ),
          ),
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          if (isExpanded) ...[
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox.square(
                  dimension: coverSize,
                  child: ClipRect(child: cover),
                ),
                _DetailsColumn(
                  children: [_Description(body), _ActionLink(actionLabel)],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// List card body with the Figma top divider (`Line 9`): a 0.5px
/// `basicBlack` line, then `spacing/md` above and below the [child].
class _ListCard extends StatelessWidget {
  const _ListCard({required this.onTap, required this.child});

  static const double dividerThickness = 0.5;

  final VoidCallback? onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return _Tappable(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Divider(
            height: dividerThickness,
            thickness: dividerThickness,
            color: AppColors.basicBlack,
          ),
          const SizedBox(height: AppSpacing.md),
          child,
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}

class _Tappable extends StatelessWidget {
  const _Tappable({required this.onTap, required this.child});

  final VoidCallback? onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (onTap == null) return child;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: child,
    );
  }
}

class _CardTitle extends StatelessWidget {
  const _CardTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: Theme.of(context).textTheme.titleLarge);
  }
}

/// The [_detailsWidth] column next to a cover, with `spacing/md` gaps.
class _DetailsColumn extends StatelessWidget {
  const _DetailsColumn({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: SizedBox(
        width: _detailsWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const SizedBox(height: AppSpacing.md),
              children[i],
            ],
          ],
        ),
      ),
    );
  }
}

class _Description extends StatelessWidget {
  const _Description(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodySmall
          ?.copyWith(color: AppColors.softBlack),
    );
  }
}

/// "Icon + text" metadata entry, e.g. the clock with the duration.
class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: _iconSize, color: AppColors.basicBlack),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Text(text, style: Theme.of(context).textTheme.labelMedium),
        ),
      ],
    );
  }
}

/// "Text + arrow" action row — `meditation link` / `article link`
/// (Figma nodes 2:121 / 2:130).
class _ActionLink extends StatelessWidget {
  const _ActionLink(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _detailsWidth,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(label, style: Theme.of(context).textTheme.labelMedium),
          ),
          const Icon(
            Icons.arrow_forward_rounded,
            size: _iconSize,
            color: AppColors.basicBlack,
          ),
        ],
      ),
    );
  }
}
