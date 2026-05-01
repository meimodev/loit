import 'package:flutter/material.dart';

import '../../core/theme/loit_colors.dart';
import '../../core/theme/loit_radius.dart';
import '../../core/theme/loit_typography.dart';

class UpdateRequiredScreen extends StatelessWidget {
  const UpdateRequiredScreen({super.key, this.onUpdate});

  final VoidCallback? onUpdate;

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    return Scaffold(
      backgroundColor: c.canvas,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Center(
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: c.infoSurface,
                    borderRadius: LoitRadius.brXl,
                  ),
                  child: Icon(Icons.system_update_alt, size: 48, color: c.info),
                ),
              ),
              const SizedBox(height: 24),
              Text('Update required',
                  textAlign: TextAlign.center,
                  style: LoitTypography.titleL.copyWith(
                    color: c.contentPrimary,
                    fontWeight: FontWeight.w600,
                  )),
              const SizedBox(height: 8),
              Text(
                "We've shipped important fixes. Update LOIT to keep going.",
                textAlign: TextAlign.center,
                style: LoitTypography.bodyM
                    .copyWith(color: c.contentSecondary, height: 1.4),
              ),
              const Spacer(),
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: onUpdate,
                  child: const Text('Update now'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
