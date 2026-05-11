import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/loit_colors.dart';
import '../../core/theme/loit_typography.dart';
import '../../l10n/l10n_x.dart';
import '_widgets.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const _appVersion = '1.0.0';
  static const _build = '1';

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    final l = context.l10n;
    return Scaffold(
      backgroundColor: c.canvas,
      appBar: AppBar(
        title: Text(l.aboutTitle),
        backgroundColor: c.canvas,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
            color: c.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [c.brand, c.accent],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.savings_outlined,
                      size: 32, color: Colors.white),
                ),
                const SizedBox(height: 12),
                Text(l.aboutAppName,
                    style: LoitTypography.titleL.copyWith(
                      color: c.contentPrimary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    )),
                const SizedBox(height: 4),
                Text(
                  l.aboutTagline,
                  textAlign: TextAlign.center,
                  style: LoitTypography.bodyS
                      .copyWith(color: c.contentSecondary),
                ),
              ],
            ),
          ),
          SettingsGroup(label: l.aboutLegal, children: [
            SettingsRow(
              label: l.aboutTermsOfService,
              onTap: () => _open('https://www.activid.id/terms'),
            ),
            SettingsRow(
              label: l.aboutPrivacyPolicy,
              onTap: () => _open('https://www.activid.id/privacy'),
            ),
          ]),
          SettingsGroup(label: l.aboutBuild, children: [
            SettingsRow(
                label: l.settingsVersion,
                value: '$_appVersion ($_build)',
                showChevron: false),
          ]),
        ],
      ),
    );
  }
}
