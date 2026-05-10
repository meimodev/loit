import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/loit_colors.dart';
import '../../core/theme/loit_radius.dart';
import '../../core/theme/loit_spacing.dart';
import '../../core/theme/loit_typography.dart';
import '../../l10n/l10n_x.dart';

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  bool _camera = true;
  bool _notifs = false;

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: c.canvas,
      appBar: AppBar(
        title: Text(l10n.authPermissionsTitle),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(20),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(l10n.permissionsStep,
                style: LoitTypography.bodyS
                    .copyWith(color: c.contentSecondary)),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(l10n.authPermissionsBody,
                    style: LoitTypography.titleL.copyWith(
                      color: c.contentPrimary,
                      fontWeight: FontWeight.w600,
                    )),
                const SizedBox(height: 6),
                Text("We'll ask each when you need it — you can skip now.",
                    style: LoitTypography.bodyM
                        .copyWith(color: c.contentSecondary)),
                const SizedBox(height: LoitSpacing.s4),
                _row(
                  context,
                  icon: Icons.camera_alt_outlined,
                  name: l10n.authPermissionsCamera,
                  why: l10n.authPermissionsCameraDesc,
                  value: _camera,
                  onChanged: (v) => setState(() => _camera = v),
                ),
                const SizedBox(height: 16),
                _row(
                  context,
                  icon: Icons.notifications_active_outlined,
                  name: l10n.authPermissionsNotifications,
                  why: l10n.authPermissionsNotificationsDesc,
                  value: _notifs,
                  onChanged: (v) => setState(() => _notifs = v),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: c.surface,
              border: Border(top: BorderSide(color: c.borderSubtle)),
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: () => context.go('/'),
                  child: Text(l10n.authPermissionsContinue),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(
    BuildContext context, {
    required IconData icon,
    required String name,
    required String why,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final c = context.loitColors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.borderSubtle),
        borderRadius: LoitRadius.brM,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: LoitPalette.teal50,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: c.brand),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: LoitTypography.bodyL.copyWith(
                      color: c.contentPrimary,
                      fontWeight: FontWeight.w600,
                    )),
                const SizedBox(height: 3),
                Text(why,
                    style: LoitTypography.bodyS
                        .copyWith(color: c.contentSecondary, height: 1.4)),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
