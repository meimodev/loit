import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/loit_colors.dart';
import '../../core/theme/loit_radius.dart';
import '../../core/theme/loit_typography.dart';
import '../../l10n/l10n_x.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key, this.email = ''});

  final String email;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  static const _len = 6;
  final List<TextEditingController> _ctrls =
      List.generate(_len, (_) => TextEditingController());
  final List<FocusNode> _focus = List.generate(_len, (_) => FocusNode());
  Timer? _timer;
  int _seconds = 42;

  @override
  void initState() {
    super.initState();
    _focus[0].requestFocus();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_seconds > 0) setState(() => _seconds--);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _ctrls) {
      c.dispose();
    }
    for (final f in _focus) {
      f.dispose();
    }
    super.dispose();
  }

  void _onChange(int i, String v) {
    if (v.isNotEmpty && i < _len - 1) _focus[i + 1].requestFocus();
    if (v.isEmpty && i > 0) _focus[i - 1].requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    final l10n = context.l10n;
    final email = widget.email.isEmpty ? 'your email' : widget.email;
    return Scaffold(
      backgroundColor: c.canvas,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.authOtpTitle,
                style: LoitTypography.titleL.copyWith(
                  color: c.contentPrimary,
                  fontWeight: FontWeight.w600,
                )),
            const SizedBox(height: 6),
            Text(
              l10n.authOtpBody(email),
              style: LoitTypography.bodyM
                  .copyWith(color: c.contentSecondary, height: 1.4),
            ),
            const SizedBox(height: 28),
            Row(
              children: List.generate(_len, (i) {
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: i < _len - 1 ? 8 : 0),
                    child: TextField(
                      controller: _ctrls[i],
                      focusNode: _focus[i],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 1,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly
                      ],
                      style: LoitTypography.titleL.copyWith(
                        color: c.contentPrimary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        filled: true,
                        fillColor: c.surface,
                        contentPadding: const EdgeInsets.symmetric(vertical: 16),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: LoitRadius.brM,
                          borderSide: BorderSide(color: c.borderDefault),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: LoitRadius.brM,
                          borderSide: BorderSide(color: c.borderFocus, width: 2),
                        ),
                      ),
                      onChanged: (v) => _onChange(i, v),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text.rich(
                TextSpan(
                  style: LoitTypography.bodyS
                      .copyWith(color: c.contentSecondary),
                  children: [
                    const TextSpan(text: "Didn't get it? "),
                    TextSpan(
                      text: _seconds > 0
                          ? 'Resend in 0:${_seconds.toString().padLeft(2, '0')}'
                          : l10n.authOtpResend,
                      style: TextStyle(
                          color: c.brand, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
