import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/loit_colors.dart';
import '../../core/theme/loit_radius.dart';
import '../../core/theme/loit_typography.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.next = '/welcome'});

  final String next;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 800), () {
      if (mounted) context.go(widget.next);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LoitPalette.teal700,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: LoitPalette.ochre400,
                borderRadius: LoitRadius.brL,
              ),
              alignment: Alignment.center,
              child: Text('L',
                  style: LoitTypography.displayM.copyWith(
                    color: LoitPalette.teal800,
                    fontSize: 42,
                    fontWeight: FontWeight.w700,
                  )),
            ),
            const SizedBox(height: 20),
            Text('LOIT',
                style: LoitTypography.displayM.copyWith(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -1,
                )),
            const SizedBox(height: 8),
            Text('Split bills, not friendships.',
                style: LoitTypography.bodyS
                    .copyWith(color: LoitPalette.teal100, letterSpacing: 0.3)),
          ],
        ),
      ),
    );
  }
}
