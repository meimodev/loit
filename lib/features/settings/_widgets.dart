import 'package:flutter/material.dart';

import '../../core/theme/loit_colors.dart';
import '../../core/theme/loit_motion.dart';
import '../../core/theme/loit_typography.dart';
import '../../l10n/l10n_x.dart';
import '../../shared/widgets/loit_animations.dart';

class SettingsGroup extends StatelessWidget {
  const SettingsGroup({super.key, required this.label, required this.children});

  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 16, 8),
          child: Text(
            label.toUpperCase(),
            style: LoitTypography.labelS.copyWith(
              color: c.contentSecondary,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        for (var i = 0; i < children.length; i++)
          LoitFadeSlideIn(
            delay: LoitMotion.staggerStep * i,
            duration: LoitMotion.entrance,
            offset: 8,
            child: children[i],
          ),
      ],
    );
  }
}

class SettingsRow extends StatefulWidget {
  const SettingsRow({
    super.key,
    required this.label,
    this.value,
    this.trailing,
    this.onTap,
    this.destructive = false,
    this.showChevron = true,
  });

  final String label;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool destructive;
  final bool showChevron;

  @override
  State<SettingsRow> createState() => _SettingsRowState();
}

class _SettingsRowState extends State<SettingsRow> {
  bool _hovering = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    final reduce = MediaQuery.of(context).disableAnimations;
    final highlight = _hovering || _pressed;
    final chevronShift = _pressed ? 3.0 : (_hovering ? 2.0 : 0.0);

    final content = AnimatedContainer(
      duration: LoitMotion.short,
      curve: LoitMotion.easeOutQuart,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: highlight && widget.onTap != null
            ? Color.alphaBlend(c.brand.withValues(alpha: 0.04), c.surface)
            : c.surface,
        border: Border(bottom: BorderSide(color: c.borderSubtle, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: AnimatedDefaultTextStyle(
              duration: LoitMotion.short,
              curve: LoitMotion.easeOutQuart,
              style: LoitTypography.bodyM.copyWith(
                color: widget.destructive ? c.danger : c.contentPrimary,
                fontWeight:
                    widget.destructive ? FontWeight.w500 : FontWeight.w400,
              ),
              child: Text(widget.label),
            ),
          ),
          if (widget.value != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: AnimatedSwitcher(
                duration: LoitMotion.base,
                switchInCurve: LoitMotion.easeOutQuart,
                switchOutCurve: LoitMotion.easeOutQuart,
                transitionBuilder: (child, anim) {
                  final slide = Tween<Offset>(
                    begin: const Offset(0, 0.25),
                    end: Offset.zero,
                  ).animate(anim);
                  return FadeTransition(
                    opacity: anim,
                    child: SlideTransition(position: slide, child: child),
                  );
                },
                child: Text(
                  widget.value!,
                  key: ValueKey(widget.value),
                  style: LoitTypography.bodyS.copyWith(
                    color: c.contentSecondary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
          if (widget.trailing != null) widget.trailing!,
          if (widget.trailing == null &&
              widget.showChevron &&
              !widget.destructive)
            AnimatedSlide(
              offset: reduce ? Offset.zero : Offset(chevronShift / 18, 0),
              duration: LoitMotion.short,
              curve: LoitMotion.easeOutQuart,
              child: AnimatedOpacity(
                duration: LoitMotion.short,
                opacity: highlight ? 1.0 : 0.7,
                child: Icon(Icons.chevron_right,
                    size: 18, color: c.contentTertiary),
              ),
            ),
        ],
      ),
    );

    if (widget.onTap == null) return content;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: LoitTapScale(
        scale: 0.985,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: (_) => setState(() => _pressed = false),
          child: InkWell(
            onTap: widget.onTap,
            child: content,
          ),
        ),
      ),
    );
  }
}

class SettingsToggleRow extends StatelessWidget {
  const SettingsToggleRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.helper,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? helper;

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    return AnimatedContainer(
      duration: LoitMotion.short,
      curve: LoitMotion.easeOutQuart,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: value
            ? Color.alphaBlend(c.brand.withValues(alpha: 0.05), c.surface)
            : c.surface,
        border: Border(bottom: BorderSide(color: c.borderSubtle, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label,
                    style: LoitTypography.bodyM
                        .copyWith(color: c.contentPrimary)),
                if (helper != null) ...[
                  const SizedBox(height: 2),
                  AnimatedDefaultTextStyle(
                    duration: LoitMotion.short,
                    curve: LoitMotion.easeOutQuart,
                    style: LoitTypography.bodyS.copyWith(
                      color: value ? c.brand : c.contentSecondary,
                    ),
                    child: Text(helper!),
                  ),
                ],
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: c.brand,
          ),
        ],
      ),
    );
  }
}

/// Initials avatar matching design (`Avatar` from screen-helpers).
class SettingsAvatar extends StatelessWidget {
  const SettingsAvatar({
    super.key,
    required this.initials,
    required this.color,
    this.size = 48,
    this.imageUrl,
  });

  final String initials;
  final Color color;
  final double size;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.of(context).disableAnimations;
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;
    final avatar = AnimatedContainer(
      duration: LoitMotion.base,
      curve: LoitMotion.easeOutQuart,
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        image: hasImage
            ? DecorationImage(
                image: NetworkImage(imageUrl!),
                fit: BoxFit.cover,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 16,
            spreadRadius: -2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: hasImage
          ? null
          : AnimatedSwitcher(
              duration: LoitMotion.base,
              switchInCurve: LoitMotion.easeOutQuart,
              transitionBuilder: (child, anim) => ScaleTransition(
                scale: anim,
                child: FadeTransition(opacity: anim, child: child),
              ),
              child: Text(
                initials,
                key: ValueKey(initials),
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: size * 0.4,
                ),
              ),
            ),
    );

    if (reduce) return avatar;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: LoitMotion.entrance,
      curve: LoitMotion.easeOutExpo,
      builder: (_, t, child) {
        return Transform.scale(
          scale: 0.6 + 0.4 * t,
          child: Opacity(opacity: t, child: child),
        );
      },
      child: avatar,
    );
  }
}

class SettingsTierChip extends StatelessWidget {
  const SettingsTierChip({super.key, required this.tier});

  final String tier; // free|pro|team

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    final l = context.l10n;
    final upper = tier.toUpperCase();
    final isPaid = tier == 'pro' || tier == 'team';
    final reduce = MediaQuery.of(context).disableAnimations;

    final chip = AnimatedContainer(
      duration: LoitMotion.emphasized,
      curve: LoitMotion.easeOutQuart,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isPaid ? const Color(0xFFE6F4F0) : c.muted,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isPaid) ...[
            SizedBox(
              width: 10,
              height: 10,
              child: Center(
                child: LoitPulseDot(color: c.brand, size: 5, maxRing: 10),
              ),
            ),
            const SizedBox(width: 4),
          ],
          AnimatedSwitcher(
            duration: LoitMotion.base,
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: ScaleTransition(scale: anim, child: child),
            ),
            child: Text(
              isPaid ? '$upper · ${l.tierActive}' : upper,
              key: ValueKey('$upper-${isPaid ? 'p' : 'f'}'),
              style: LoitTypography.labelS.copyWith(
                color: isPaid ? c.brand : c.contentSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 10,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ],
      ),
    );

    if (reduce) return chip;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: LoitMotion.entrance,
      curve: LoitMotion.easeOutExpo,
      builder: (_, t, child) => Opacity(
        opacity: t,
        child: Transform.scale(scale: 0.85 + 0.15 * t, child: child),
      ),
      child: chip,
    );
  }
}
