import 'package:flutter/material.dart';
import 'package:hoffman/core/theme/index.dart';
import 'package:hoffman/core/widgets/app_badge.dart';

// Content cards from the Figma `Components` section (node 1:2). Icons are the
// closest Material Icons until the exact SVG assets are exported.

/// The square cover of [MeditationCard], [ArticleListCard] and
/// [ThemeListCard] is this many [AppGrid] columns wide.
const int _coverColumns = 3;

/// Next to a cover on its left, the details column starts at
/// [AppGrid.boundary] of this many columns and takes the rest of the card
/// ([AppGrid.span] of the same count). Without a cover on its left (the
/// article and tool cards), the details and the action link row end there.
const int _detailsColumns = 4;
const double _iconSize = 16;

/// Space between the title (the header of a theme card) and the content
/// block under it.
const double _titleGap = AppSpacing.lg;

/// Space between two elements of the content block: the date or duration,
/// the description and the action link.
const double _contentGap = AppSpacing.md;

/// Meditation card, Figma node 132:5273 (`meditation card`).
///
/// Title on top; below it the square [cover] with a play icon (left) and the
/// details column (right): duration, description and the action link. The
/// whole card handles [onTap]. No lock mark even for a locked meditation:
/// the meditation screen itself shows `MeditationLockedView`.
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

  static const int coverColumns = _coverColumns;
  static const int detailsColumns = _detailsColumns;
  static const double playIconSize = 24;

  final String title;

  /// Cover image, clipped to a square [coverColumns] wide.
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
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardTitle(title),
          const SizedBox(height: _titleGap),
          _CoverRow(
            cover: Stack(
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
            details: [
              _MetaRow(icon: Icons.watch_later, text: duration),
              _Description(description),
              _ActionLink(actionLabel),
            ],
          ),
        ],
      ),
    );
  }
}

/// Article list card, Figma node 132:5127 (`article list card`).
///
/// Title; below it the details column (date,
/// description, action link) on the left and the [cover] on the right. The
/// whole card handles [onTap]. [badge] adds an [AppBadge]
/// ([AppBadgeVariant.tinted]) after the date. No lock mark: articles are
/// open to everyone.
class ArticleListCard extends StatelessWidget {
  const ArticleListCard({
    required this.title,
    required this.cover,
    required this.date,
    required this.description,
    required this.actionLabel,
    super.key,
    this.badge,
    this.onTap,
  });

  static const int coverColumns = _coverColumns;
  static const int detailsColumns = _detailsColumns;

  final String title;

  /// Cover image, clipped to a square [coverColumns] wide.
  final Widget cover;

  /// Date text next to the calendar icon, e.g. `Март, 2025`.
  final String date;
  final String description;
  final String actionLabel;

  /// E.g. `новое` for an article marked new in the admin; `null` hides it.
  final String? badge;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final meta = _MetaRow(icon: Icons.calendar_month, text: date);

    return _Tappable(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardTitle(title),
          const SizedBox(height: _titleGap),
          _CoverRow(
            coverOnLeft: false,
            cover: ClipRect(child: cover),
            details: [
              if (badge case final badge?)
                // TODO(figma): no `новое` badge in the mockups (article list
                // card 946:1583); the existing tinted variant stands in, at
                // the right end of the date row (under the link's arrow).
                Row(
                  children: [
                    Expanded(child: meta),
                    const SizedBox(width: AppSpacing.sm),
                    AppBadge(label: badge, variant: AppBadgeVariant.tinted),
                  ],
                )
              else
                meta,
              _Description(description),
              _ActionLink(actionLabel),
            ],
          ),
        ],
      ),
    );
  }
}

/// Tool list card, Figma node 132:5143 (`tool list card`).
///
/// Title, then the description with a [tag] [AppBadge]
/// ([AppBadgeVariant.tinted]) on its right, then the action link. No cover:
/// the mockup has no slot for one. The whole card handles [onTap]. Tools
/// are open to everyone, so it has no lock mark.
class ToolListCard extends StatelessWidget {
  const ToolListCard({
    required this.title,
    required this.description,
    required this.tag,
    required this.actionLabel,
    super.key,
    this.onTap,
  });

  static const int actionColumns = _detailsColumns;

  final String title;
  final String description;

  /// `null` hides the badge (e.g. a tool without a stage).
  final String? tag;
  final String actionLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return _Tappable(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardTitle(title),
          const SizedBox(height: _titleGap),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _Description(description)),
              if (tag case final tag?) ...[
                // TODO(figma): the mockup gives the text a fixed 231px width;
                // the minimum gap before the badge is not defined.
                const SizedBox(width: AppSpacing.md),
                AppBadge(label: tag, variant: AppBadgeVariant.tinted),
              ],
            ],
          ),
          const SizedBox(height: _contentGap),
          LayoutBuilder(
            builder: (context, constraints) => SizedBox(
              width: AppGrid.boundary(constraints.maxWidth, actionColumns),
              child: _ActionLink(actionLabel),
            ),
          ),
        ],
      ),
    );
  }
}

/// Theme list card, Figma nodes 132:5174 (`theme list card folded`) and
/// 132:5157 (`theme list card unfolded`).
///
/// Folded: title with a `+` icon and the
/// [subtitle]. Expanded: a `–` icon instead of `+`, then the [cover] next to
/// the multi-paragraph [body] and the action link. The whole card handles
/// [onTap]; the owner toggles [isExpanded]. With [onActionTap] set, the
/// action link handles its own taps (e.g. opens the topic while [onTap]
/// folds the card). Topics are open to everyone, so it has no lock mark.
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
    this.onActionTap,
  });

  static const int coverColumns = _coverColumns;
  static const int detailsColumns = _detailsColumns;

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

  /// Cover image, clipped to a square [coverColumns] wide. Shown when
  /// expanded.
  final Widget cover;

  /// Long text shown when expanded; separate paragraphs with `\n`.
  final String body;
  final String actionLabel;
  final bool isExpanded;
  final VoidCallback? onTap;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    return _Tappable(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
          Text(
            bindShortWords(subtitle),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (isExpanded) ...[
            const SizedBox(height: _titleGap),
            _CoverRow(
              cover: ClipRect(child: cover),
              details: [
                _Description(body),
                _Tappable(onTap: onActionTap, child: _ActionLink(actionLabel)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Divider between the cards of a list, Figma `Line 9`: a full-width
/// 0.5px `basicBlack` line.
class ContentDivider extends StatelessWidget {
  const ContentDivider({super.key});

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

/// A list of content cards ([MeditationCard], [ArticleListCard],
/// [ToolListCard], [ThemeListCard]) laid out edge to edge.
///
/// A [ContentDivider] runs the full width only between two cards — none
/// above the first or below the last — with [gap] on both of its sides.
/// The cards get the [AppGrid.margin] sides; the list itself adds [top]
/// and [bottom] (by default `spacing/xl` between the featured item or the
/// cover above and the next section below). Without [children] it takes
/// no space at all.
class ContentCardList extends StatelessWidget {
  const ContentCardList({
    required this.children,
    super.key,
    this.top = AppSpacing.xl,
    this.bottom = AppSpacing.xl,
  });

  /// Space between a divider and the card above or below it.
  static const double gap = AppSpacing.md;

  final List<Widget> children;
  final double top;
  final double bottom;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(top: top, bottom: bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, card) in children.indexed) ...[
            if (i > 0) ...[
              const SizedBox(height: gap),
              const ContentDivider(),
              const SizedBox(height: gap),
            ],
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppGrid.margin),
              child: card,
            ),
          ],
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

/// Lock icon of the diary: the only closed-state mark of the app (locked
/// days, the locked diary block of the home screen). Content cards never
/// carry it — a locked meditation shows its lock on its own screen.
// TODO(figma): the icon matches the one in LockedOverlay.
class LockedMark extends StatelessWidget {
  const LockedMark({super.key, this.color = AppColors.basicBlack});

  static const double size = 16;
  static const String semanticLabel = 'Недоступно';

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.lock,
      size: size,
      color: color,
      semanticLabel: semanticLabel,
    );
  }
}

/// The square [_coverColumns] [cover] and the details column on the
/// [AppGrid], [_contentGap] between the [details].
///
/// [coverOnLeft]: the cover is at the left edge and the details column
/// starts at [AppGrid.boundary] of [_detailsColumns] (a one-column gap after
/// the cover), running to the right edge. Otherwise the details column
/// starts at the left edge and ends at that boundary; the cover is at the
/// right edge. The tops line up, and the taller of the two sets the bottom.
class _CoverRow extends StatelessWidget {
  const _CoverRow({
    required this.cover,
    required this.details,
    this.coverOnLeft = true,
  });

  final Widget cover;
  final List<Widget> details;
  final bool coverOnLeft;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final coverBox = SizedBox.square(
          dimension: AppGrid.span(width, _coverColumns),
          child: cover,
        );
        final detailsBox = SizedBox(
          width: coverOnLeft
              ? AppGrid.span(width, _detailsColumns)
              : AppGrid.boundary(width, _detailsColumns),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < details.length; i++) ...[
                if (i > 0) const SizedBox(height: _contentGap),
                details[i],
              ],
            ],
          ),
        );

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: coverOnLeft
              ? [coverBox, detailsBox]
              : [detailsBox, coverBox],
        );
      },
    );
  }
}

class _Description extends StatelessWidget {
  const _Description(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      bindShortWords(text),
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
/// (Figma nodes 2:121 / 2:130), as wide as its parent: the arrow sits at
/// the parent's right edge.
class _ActionLink extends StatelessWidget {
  const _ActionLink(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
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
    );
  }
}
