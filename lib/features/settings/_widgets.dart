import 'package:flutter/material.dart';

import '../../core/theme/loit_colors.dart';
import '../../core/theme/loit_typography.dart';

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
        ...children,
      ],
    );
  }
}

class SettingsRow extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final c = context.loitColors;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: c.surface,
          border: Border(bottom: BorderSide(color: c.borderSubtle, width: 1)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: LoitTypography.bodyM.copyWith(
                  color: destructive ? c.danger : c.contentPrimary,
                  fontWeight: destructive ? FontWeight.w500 : FontWeight.w400,
                ),
              ),
            ),
            if (value != null)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  value!,
                  style: LoitTypography.bodyS.copyWith(
                    color: c.contentSecondary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            if (trailing != null) trailing!,
            if (trailing == null && showChevron && !destructive)
              Icon(Icons.chevron_right, size: 18, color: c.contentTertiary),
          ],
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: c.surface,
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
                  Text(helper!,
                      style: LoitTypography.bodyS
                          .copyWith(color: c.contentSecondary)),
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
  });

  final String initials;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: size * 0.4,
        ),
      ),
    );
  }
}

class SettingsTierChip extends StatelessWidget {
  const SettingsTierChip({super.key, required this.tier});

  final String tier; // free|pro|team

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    final upper = tier.toUpperCase();
    final isPaid = tier == 'pro' || tier == 'team';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isPaid ? const Color(0xFFE6F4F0) : c.muted,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isPaid ? '$upper · ACTIVE' : upper,
        style: LoitTypography.labelS.copyWith(
          color: isPaid ? c.brand : c.contentSecondary,
          fontWeight: FontWeight.w600,
          fontSize: 10,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
