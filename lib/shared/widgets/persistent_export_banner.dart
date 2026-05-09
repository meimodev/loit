import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/loit_colors.dart';
import '../../core/theme/loit_elevation.dart';
import '../../core/theme/loit_motion.dart';
import '../../core/theme/loit_radius.dart';
import '../../core/theme/loit_spacing.dart';
import '../../core/theme/loit_typography.dart';
import '../providers/export_task_provider.dart';

/// Slim app-wide banner shown while an export is generating in the
/// background. Mirrors [PersistentConnectivityBanner] positioning so both
/// banners share the same visual slot above the bottom nav.
class PersistentExportBanner extends ConsumerWidget {
  const PersistentExportBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(exportTaskProvider);
    final running = state is ExportTaskRunning;
    final label = running ? state.label : '';
    final fmt = running ? (state.isPdf ? 'PDF' : 'CSV') : '';

    final bottomOffset =
        64 + MediaQuery.of(context).padding.bottom + LoitSpacing.s2;

    return AnimatedPositioned(
      left: LoitSpacing.s4,
      right: LoitSpacing.s4,
      bottom: running ? bottomOffset : -(96 + bottomOffset),
      duration: LoitMotion.base,
      curve: LoitMotion.emphasizedCurve,
      child: IgnorePointer(
        ignoring: !running,
        child: AnimatedOpacity(
          opacity: running ? 1.0 : 0.0,
          duration: LoitMotion.short,
          curve: LoitMotion.emphasizedCurve,
          child: SafeArea(
            top: false,
            child: _ExportCard(label: label, formatLabel: fmt),
          ),
        ),
      ),
    );
  }
}

class _ExportCard extends StatelessWidget {
  const _ExportCard({required this.label, required this.formatLabel});
  final String label;
  final String formatLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: LoitSpacing.s4,
        vertical: LoitSpacing.s3,
      ),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: LoitRadius.brM,
        border: Border.all(color: c.borderSubtle),
        boxShadow: LoitElevation.e2,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(c.brand),
            ),
          ),
          const SizedBox(width: LoitSpacing.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label.isEmpty ? 'Exporting…' : 'Exporting $label…',
                  style: LoitTypography.bodyM.copyWith(
                    color: c.contentPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (formatLabel.isNotEmpty)
                  Text(
                    'Generating $formatLabel — share sheet opens when ready',
                    style: LoitTypography.bodyS
                        .copyWith(color: c.contentSecondary),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
