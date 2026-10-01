import 'package:flutter/material.dart';
import 'package:hoffman/core/theme/index.dart';
import 'package:hoffman/core/widgets/app_badge.dart';

// Content cards from the Figma `Components` section (node 1:2). Icons are the
// closest Material Icons until the exact SVG assets are exported.

/// Width of the details column and of the action link row in every card.
const double _detailsWidth = 184;
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
/// whole card handles [onTap]. [isLocked] adds a [LockedMark] to the title.
class MeditationCard extends StatelessWidget {
  const MeditationCard({
    required this.title,
    required this.cover,
    required this.duration,
    required this.description,
    required this.actionLabel,
    super.key,
    this.isLocked = false,
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
  final bool isLocked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return _Tappable(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardTitle(title, isLocked: isLocked),
          const SizedBox(height: _titleGap),
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
/// Title; below it the details column (date,
/// description, action link) on the left and the [cover] on the right. The
/// whole card handles [onTap]. [isLocked] adds a [LockedMark] to the title;
/// [badge] adds an [AppBadge] ([AppBadgeVariant.tinted]) after the date.
class ArticleListCard extends StatelessWidget {
  const ArticleListCard({
    required this.title,
    required this.cover,
    required this.date,
    required this.description,
    required this.actionLabel,
    super.key,
    this.badge,
    this.isLocked = false,
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

  /// E.g. `новое` for an article marked new in the admin; `null` hides it.
  final String? badge;
  final bool isLocked;
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
          _CardTitle(title, isLocked: isLocked),
          const SizedBox(height: _titleGap),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DetailsColumn(
                children: [
                  if (badge case final badge?)
                    // TODO(figma): no `новое` badge in the mockups (article
                    // list card 946:1583); the existing tinted variant stands
                    // in, placed after the date until the design has one.
                    Row(
                      children: [
                        Flexible(child: meta),
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
          _ActionLink(actionLabel),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox.square(
                  dimension: coverSize,
                  child: ClipRect(child: cover),
                ),
                _DetailsColumn(
                  children: [
                    _Description(body),
                    _Tappable(
                      onTap: onActionTap,
                      child: _ActionLink(actionLabel),
                    ),
                  ],
                ),
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
  const _CardTitle(this.text, {this.isLocked = false});

  final String text;
  final bool isLocked;

  @override
  Widget build(BuildContext context) {
    final title = Text(text, style: Theme.of(context).textTheme.titleLarge);
    if (!isLocked) return title;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(child: title),
        const SizedBox(width: AppSpacing.sm),
        const Padding(
          // Centers the mark on the first line (20px × 1.15).
          padding: EdgeInsets.only(top: (23 - LockedMark.size) / 2),
          child: LockedMark(),
        ),
      ],
    );
  }
}

/// Lock icon marking content the user's access level does not open — shown
/// next to a card title. The card stays tappable: the content screen itself
/// shows `LockedOverlay` with the way to get access.
// TODO(figma): no locked card in the mockups; the icon matches the one in
// LockedOverlay.
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

/// The [_detailsWidth] column next to a cover, [_contentGap] between its
/// elements. Its top lines up with the cover's top (the rows that hold it
/// align their children to the start), and the taller of the two sets the
/// card's bottom.
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
              if (i > 0) const SizedBox(height: _contentGap),
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
