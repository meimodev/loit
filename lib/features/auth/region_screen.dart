import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/loit_colors.dart';
import '../../core/theme/loit_radius.dart';
import '../../core/theme/loit_typography.dart';
import '../../shared/widgets/loit_input.dart';

class RegionScreen extends StatefulWidget {
  const RegionScreen({super.key});

  @override
  State<RegionScreen> createState() => _RegionScreenState();
}

class _RegionScreenState extends State<RegionScreen> {
  String _country = '🇮🇩 Indonesia';
  String _currency = 'Rupiah · Rp · IDR';
  String _language = 'Bahasa Indonesia';

  Future<void> _pick(String title, List<String> opts, ValueChanged<String> onPick) async {
    final c = context.loitColors;
    final v = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: c.borderStrong,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(title,
                    style: LoitTypography.titleM.copyWith(
                      color: c.contentPrimary,
                      fontWeight: FontWeight.w600,
                    )),
              ),
            ),
            const SizedBox(height: 8),
            ...opts.map((o) => ListTile(
                  title: Text(o),
                  onTap: () => Navigator.pop(context, o),
                )),
          ],
        ),
      ),
    );
    if (v != null) onPick(v);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    return Scaffold(
      backgroundColor: c.canvas,
      appBar: AppBar(
        title: const Text('Your setup'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(20),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text('Step 1 of 2',
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
                Text('Where are you based?',
                    style: LoitTypography.titleL.copyWith(
                      color: c.contentPrimary,
                      fontWeight: FontWeight.w600,
                    )),
                const SizedBox(height: 6),
                Text('Sets default currency, date format, and language.',
                    style: LoitTypography.bodyM
                        .copyWith(color: c.contentSecondary)),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () => _pick(
                      'Country',
                      ['🇮🇩 Indonesia', '🇸🇬 Singapore', '🇲🇾 Malaysia', '🇺🇸 United States'],
                      (v) => setState(() => _country = v)),
                  child: AbsorbPointer(
                    child: LoitInput(
                      label: 'Country',
                      controller: TextEditingController(text: _country),
                      trailing: const Icon(Icons.chevron_right, size: 18),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: () => _pick(
                      'Home currency',
                      [
                        'Rupiah · Rp · IDR',
                        'US Dollar · \$ · USD',
                        'Singapore Dollar · S\$ · SGD',
                      ],
                      (v) => setState(() => _currency = v)),
                  child: AbsorbPointer(
                    child: LoitInput(
                      label: 'Home currency',
                      controller: TextEditingController(text: _currency),
                      trailing: const Icon(Icons.chevron_right, size: 18),
                      helper: 'You can track in multiple currencies later.',
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: () => _pick(
                      'Language',
                      ['Bahasa Indonesia', 'English', 'Bahasa Melayu'],
                      (v) => setState(() => _language = v)),
                  child: AbsorbPointer(
                    child: LoitInput(
                      label: 'Language',
                      controller: TextEditingController(text: _language),
                      trailing: const Icon(Icons.chevron_right, size: 18),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: LoitPalette.teal50,
                    borderRadius: LoitRadius.brM,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, size: 18, color: c.brand),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                            'We detected these settings. You can change any later in Settings.',
                            style: LoitTypography.bodyS.copyWith(
                                color: LoitPalette.teal800, height: 1.4)),
                      ),
                    ],
                  ),
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
                  onPressed: () => context.go('/permissions'),
                  child: const Text('Continue'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
