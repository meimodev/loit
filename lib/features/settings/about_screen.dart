import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/loit_colors.dart';
import '../../core/theme/loit_typography.dart';
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
    return Scaffold(
      backgroundColor: c.canvas,
      appBar: AppBar(
        title: const Text('About'),
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
                Text('LOIT',
                    style: LoitTypography.titleL.copyWith(
                      color: c.contentPrimary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    )),
                const SizedBox(height: 4),
                Text(
                  'Personal & shared finance, calm by design.',
                  textAlign: TextAlign.center,
                  style: LoitTypography.bodyS
                      .copyWith(color: c.contentSecondary),
                ),
              ],
            ),
          ),
          SettingsGroup(label: 'Help', children: [
            SettingsRow(
              label: 'Help center',
              onTap: () => _open('https://loit.app/help'),
            ),
            SettingsRow(
              label: 'Contact support',
              onTap: () => _open('mailto:support@loit.app'),
            ),
            SettingsRow(
              label: 'Send feedback',
              onTap: () => _open('mailto:feedback@loit.app'),
            ),
          ]),
          SettingsGroup(label: 'Legal', children: [
            SettingsRow(
              label: 'Terms of service',
              onTap: () => _open('https://loit.app/terms'),
            ),
            SettingsRow(
              label: 'Privacy policy',
              onTap: () => _open('https://loit.app/privacy'),
            ),
            SettingsRow(
              label: 'Open source licenses',
              onTap: () => showLicensePage(
                context: context,
                applicationName: 'LOIT',
                applicationVersion: _appVersion,
              ),
            ),
          ]),
          SettingsGroup(label: 'Build', children: [
            const SettingsRow(
                label: 'Version',
                value: '$_appVersion ($_build)',
                showChevron: false),
          ]),
        ],
      ),
    );
  }
}
