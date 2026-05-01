import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/loit_colors.dart';
import '../../core/theme/loit_radius.dart';
import '../../core/theme/loit_spacing.dart';
import '../../core/theme/loit_typography.dart';
import '../../shared/providers/auth_providers.dart';
import '../../shared/widgets/loit_button.dart';

/// Hero amount + custom numeric keypad. "Continue" pre-fills full form.
///
/// Design source: `screens-scan-add.jsx` AddExpense (amount hero) — keypad
/// rendered explicitly so the user never leaves the screen between digits.
class QuickAddScreen extends ConsumerStatefulWidget {
  const QuickAddScreen({super.key});

  @override
  ConsumerState<QuickAddScreen> createState() => _QuickAddScreenState();
}

class _QuickAddScreenState extends ConsumerState<QuickAddScreen> {
  String _raw = '';

  void _press(String key) {
    HapticFeedback.selectionClick();
    setState(() {
      if (key == 'back') {
        if (_raw.isNotEmpty) _raw = _raw.substring(0, _raw.length - 1);
      } else if (key == '.') {
        if (!_raw.contains('.')) _raw = _raw.isEmpty ? '0.' : '$_raw.';
      } else {
        if (_raw == '0') {
          _raw = key;
        } else {
          _raw += key;
        }
      }
    });
  }

  double get _value => _raw.isEmpty ? 0 : double.tryParse(_raw) ?? 0;

  String _formatted(String currency) {
    if (_raw.isEmpty) return '0';
    final parts = _raw.split('.');
    final intPart = parts[0];
    final groups = <String>[];
    for (var i = intPart.length; i > 0; i -= 3) {
      groups.insert(0, intPart.substring(i - 3 < 0 ? 0 : i - 3, i));
    }
    final formatted = groups.join('.');
    return parts.length > 1 ? '$formatted.${parts[1]}' : formatted;
  }

  void _continue() {
    if (_value <= 0) return;
    HapticFeedback.lightImpact();
    context.pushReplacement('/transactions/new', extra: {
      'amount': _value,
      '_quick_add': true,
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    final profile = ref.watch(userProfileProvider).value;
    final currency = profile?.homeCurrency ?? 'IDR';
    final symbol = currency == 'IDR' ? 'Rp' : currency;
    final hasValue = _value > 0;

    return Scaffold(
      backgroundColor: c.canvas,
      appBar: AppBar(
        title: const Text('Add expense'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: LoitSpacing.s5),
            Text(
              'AMOUNT',
              style: LoitTypography.labelS.copyWith(
                color: c.contentSecondary,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: LoitSpacing.s2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  symbol,
                  style: LoitTypography.titleL.copyWith(
                    color: c.contentSecondary,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  _formatted(currency),
                  style: LoitTypography.amountHero.copyWith(
                    color: hasValue ? c.contentPrimary : c.contentTertiary,
                    fontSize: 48,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            const SizedBox(height: LoitSpacing.s3),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: LoitSpacing.s3,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: c.muted,
                borderRadius: LoitRadius.brFull,
              ),
              child: Text(
                '$currency · ID',
                style: LoitTypography.labelS.copyWith(
                  color: c.contentSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Spacer(),
            _Keypad(onKey: _press),
            const SizedBox(height: LoitSpacing.s3),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                LoitSpacing.s4,
                0,
                LoitSpacing.s4,
                LoitSpacing.s4,
              ),
              child: LoitButton.primary(
                label: 'Continue',
                size: LoitButtonSize.l,
                onPressed: hasValue ? _continue : null,
                fullWidth: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Keypad extends StatelessWidget {
  const _Keypad({required this.onKey});
  final void Function(String) onKey;

  static const _keys = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
    ['.', '0', 'back'],
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: LoitSpacing.s4),
      child: Column(
        children: [
          for (final row in _keys)
            Row(
              children: [
                for (final k in row)
                  Expanded(child: _KeyButton(label: k, onTap: () => onKey(k))),
              ],
            ),
        ],
      ),
    );
  }
}

class _KeyButton extends StatefulWidget {
  const _KeyButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  State<_KeyButton> createState() => _KeyButtonState();
}

class _KeyButtonState extends State<_KeyButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    final isBack = widget.label == 'back';
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        height: 64,
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: _pressed ? c.muted : Colors.transparent,
          borderRadius: LoitRadius.brM,
        ),
        child: Center(
          child: isBack
              ? Icon(Icons.backspace_outlined, size: 22, color: c.contentPrimary)
              : Text(
                  widget.label,
                  style: LoitTypography.titleL.copyWith(
                    color: c.contentPrimary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
        ),
      ),
    );
  }
}
