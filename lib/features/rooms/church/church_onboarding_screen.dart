import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/analytics_service.dart';
import '../../../core/services/reachability_service.dart'
    show OnlineOnlyActionException;
import '../../../core/theme/loit_colors.dart';
import '../../../core/theme/loit_motion.dart';
import '../../../core/theme/loit_radius.dart';
import '../../../core/theme/loit_spacing.dart';
import '../../../core/theme/loit_typography.dart';
import '../../../shared/providers/room_providers.dart';
import '../../../shared/providers/user_categories_provider.dart';
import '../../../shared/widgets/loit_button.dart';
import '../../../shared/widgets/loit_input.dart';
import '../../../shared/widgets/room_error_state.dart';
import 'church_presets.dart';

/// Denomination-aware church room creation (ADR 0019). Four steps in one
/// screen; the room is persisted at the end of step 3 (categories), then a
/// confirmation step lands on the room dashboard. name = jemaat_name,
/// currency = IDR, colour auto-derived from the room id (RoomColors.forId).
///
// ponytail: copy hardcoded Indonesian — church domain is Indonesian-only.
// ponytail: category reorder skipped; checklist + add covers v1, add reorder
// if treasurers ask.
class ChurchOnboardingScreen extends ConsumerStatefulWidget {
  const ChurchOnboardingScreen({super.key});

  @override
  ConsumerState<ChurchOnboardingScreen> createState() =>
      _ChurchOnboardingScreenState();
}

class _ChurchOnboardingScreenState
    extends ConsumerState<ChurchOnboardingScreen> {
  int _step = 0;
  // Drives the step-transition slide direction (right-in advancing, left-in
  // going back). Confetti only fires once, gated by this.
  bool _forward = true;

  // Step 1
  String? _denomination; // a denominationOrder entry, or null
  final _denomOther = TextEditingController();

  // Step 2
  final _jemaat = TextEditingController();
  final _kota = TextEditingController();
  final _phone = TextEditingController();

  // Step 3 — editable category lists (checked = included)
  List<_Cat> _penerimaan = [];
  List<_Cat> _pengeluaran = [];

  bool _busy = false;

  @override
  void dispose() {
    _denomOther.dispose();
    _jemaat.dispose();
    _kota.dispose();
    _phone.dispose();
    super.dispose();
  }

  /// Resolved denomination string stored in org_config: the free text for
  /// "Lainnya", otherwise the picked entry.
  String get _resolvedDenomination =>
      _denomination == kDenominationOther
          ? _denomOther.text.trim()
          : (_denomination ?? '');

  /// Named denominations only; the "Lainnya" escape hatch renders separately.
  List<String> get _namedDenominations =>
      [for (final d in denominationOrder) if (d != kDenominationOther) d];

  void _seedCategoriesFromPreset() {
    final preset = presetFor(_denomination ?? kDenominationOther);
    _penerimaan = [for (final n in preset.penerimaan) _Cat(n)];
    _pengeluaran = [for (final n in preset.pengeluaran) _Cat(n)];
  }

  /// Profile step (1) errors surface only after a submit attempt (tap Lanjut).
  bool _profileSubmitted = false;

  String? get _jemaatError =>
      _profileSubmitted && _jemaat.text.trim().isEmpty
          ? 'Nama jemaat wajib diisi'
          : null;
  String? get _kotaError =>
      _profileSubmitted && _kota.text.trim().isEmpty
          ? 'Kota/kabupaten wajib diisi'
          : null;
  /// Strict Indonesian mobile (ADR 0019): 08xx / +62xx, 10–13 digits.
  String? get _phoneError =>
      _profileSubmitted && normalizeIndoMobile(_phone.text) == null
          ? 'Nomor HP tidak valid — contoh 0812 3456 7890'
          : null;

  /// Gates step 0 (denomination). Step 1 validates on submit; steps 2/3 use
  /// their own CTAs.
  bool get _canAdvance => _denomination != null &&
      (_denomination != kDenominationOther ||
          _denomOther.text.trim().isNotEmpty);

  void _next() {
    if (_step == 1) {
      setState(() => _profileSubmitted = true);
      if (_jemaat.text.trim().isEmpty ||
          _kota.text.trim().isEmpty ||
          normalizeIndoMobile(_phone.text) == null) {
        return;
      }
    }
    if (_step == 0) _seedCategoriesFromPreset();
    setState(() {
      _forward = true;
      _step++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return Scaffold(
      backgroundColor: c.canvas,
      appBar: AppBar(
        title: Text(_titleFor(_step)),
        leading: IconButton(
          icon: Icon(_step == 0 || _step == 3
              ? Icons.close
              : Icons.arrow_back),
          onPressed: _busy
              ? null
              : () {
                  if (_step == 0 || _step == 3) {
                    context.pop();
                  } else {
                    setState(() {
                      _forward = false;
                      _step--;
                    });
                  }
                },
        ),
        // Animated 4-segment progress: each segment fills as its step is
        // reached, clarifying position in the wizard.
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: Row(
            children: [
              for (var i = 0; i < 4; i++)
                Expanded(
                  child: AnimatedContainer(
                    duration: reduce ? Duration.zero : LoitMotion.base,
                    curve: LoitMotion.easeOut,
                    height: 3,
                    margin: EdgeInsets.only(right: i < 3 ? 2 : 0),
                    color: i <= _step ? c.brand : c.borderSubtle,
                  ),
                ),
            ],
          ),
        ),
      ),
      body: AnimatedSwitcher(
        duration: reduce ? Duration.zero : LoitMotion.emphasized,
        switchInCurve: LoitMotion.easeOutQuart,
        switchOutCurve: LoitMotion.easeOut,
        // StackFit.expand gives each step tight constraints so the inner
        // Column/Expanded layout survives the cross-fade.
        layoutBuilder: (currentChild, previousChildren) => Stack(
          fit: StackFit.expand,
          alignment: Alignment.center,
          children: [
            ...previousChildren,
            if (currentChild != null) currentChild,
          ],
        ),
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: Offset(_forward ? 0.06 : -0.06, 0),
              end: Offset.zero,
            ).animate(anim),
            child: child,
          ),
        ),
        child: KeyedSubtree(
          key: ValueKey(_step),
          child: switch (_step) {
            0 => _stepDenomination(),
            1 => _stepProfile(),
            2 => _stepCategories(),
            _ => _stepConfirm(),
          },
        ),
      ),
    );
  }

  String _titleFor(int step) => switch (step) {
        0 => 'Jenis Gereja',
        1 => 'Profil Jemaat',
        2 => 'Kategori Keuangan',
        _ => 'Selesai',
      };

  Widget _bottomCta(String label, VoidCallback? onPressed) {
    final c = context.loitColors;
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(LoitSpacing.s4),
        decoration: BoxDecoration(
          color: c.surface,
          border: Border(top: BorderSide(color: c.borderSubtle)),
        ),
        child: LoitButton.primary(
          size: LoitButtonSize.l,
          fullWidth: true,
          loading: _busy,
          label: label,
          onPressed: onPressed,
        ),
      ),
    );
  }

  // ---- Step 1: Denominasi ----
  Widget _stepDenomination() {
    final c = context.loitColors;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(LoitSpacing.s5, LoitSpacing.s5,
                LoitSpacing.s5, LoitSpacing.s7),
            children: [
              _Stagger(children: [
                Text('Denominasi menentukan kategori keuangan awal room ini',
                    style: LoitTypography.bodyM
                        .copyWith(color: c.contentSecondary)),
                const SizedBox(height: LoitSpacing.s5),
                // Named denominations as one scannable group.
                _GroupBox(
                  child: Column(
                    children: [
                      for (var i = 0; i < _namedDenominations.length; i++) ...[
                        if (i > 0) const _RowDivider(),
                        _RadioRow(
                          grouped: true,
                          label: _namedDenominations[i],
                          selected: _denomination == _namedDenominations[i],
                          onTap: () => setState(
                              () => _denomination = _namedDenominations[i]),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: LoitSpacing.s5),
                // Escape hatch — set apart from the named list.
                _GroupBox(
                  child: _RadioRow(
                    grouped: true,
                    label: 'Lainnya',
                    selected: _denomination == kDenominationOther,
                    onTap: () =>
                        setState(() => _denomination = kDenominationOther),
                  ),
                ),
                if (_denomination == kDenominationOther) ...[
                  const SizedBox(height: LoitSpacing.s4),
                  LoitInput(
                    label: 'Nama Denominasi',
                    controller: _denomOther,
                    onChanged: (_) => setState(() {}),
                  ),
                ],
              ]),
            ],
          ),
        ),
        _bottomCta('Lanjut', _canAdvance ? _next : null),
      ],
    );
  }

  // ---- Step 2: Profil Jemaat ----
  Widget _stepProfile() {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(LoitSpacing.s5, LoitSpacing.s5,
                LoitSpacing.s5, LoitSpacing.s7),
            children: [
              _Stagger(children: [
                LoitInput(
                  label: 'Nama Jemaat *',
                  controller: _jemaat,
                  placeholder: 'mis. GMIM Sion Malalayang',
                  error: _jemaatError,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: LoitSpacing.s5),
                LoitInput(
                  label: 'Kota/Kabupaten *',
                  controller: _kota,
                  placeholder: 'mis. Manado',
                  error: _kotaError,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: LoitSpacing.s5),
                LoitInput(
                  label: 'Kontak Pemilik Room *',
                  controller: _phone,
                  placeholder: 'mis. 0812 3456 7890',
                  keyboardType: TextInputType.phone,
                  inputFormatters: [_PhoneFormatter()],
                  error: _phoneError,
                  onChanged: (_) => setState(() {}),
                ),
              ]),
            ],
          ),
        ),
        _bottomCta('Lanjut', _busy ? null : _next),
      ],
    );
  }

  // ---- Step 3: Pratinjau & edit kategori ----
  Widget _stepCategories() {
    final c = context.loitColors;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(LoitSpacing.s5, LoitSpacing.s5,
                LoitSpacing.s5, LoitSpacing.s7),
            children: [
              _Stagger(children: [
                Text(
                  'Disesuaikan dengan ${_resolvedDenomination.isEmpty ? 'gereja' : _resolvedDenomination}. Kamu bisa edit kapan saja.',
                  style:
                      LoitTypography.bodyM.copyWith(color: c.contentSecondary),
                ),
                const SizedBox(height: LoitSpacing.s6),
                _CatColumn(
                  title: 'PENERIMAAN',
                  items: _penerimaan,
                  onToggle: (i) => setState(
                      () => _penerimaan[i].checked = !_penerimaan[i].checked),
                  onAdd: () => _addCategory(_penerimaan),
                ),
                const SizedBox(height: LoitSpacing.s6),
                _CatColumn(
                  title: 'PENGELUARAN',
                  items: _pengeluaran,
                  onToggle: (i) => setState(
                      () => _pengeluaran[i].checked = !_pengeluaran[i].checked),
                  onAdd: () => _addCategory(_pengeluaran),
                ),
              ]),
            ],
          ),
        ),
        _bottomCta('Buat Room', _busy ? null : _create),
      ],
    );
  }

  Future<void> _addCategory(List<_Cat> into) async {
    final ctrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (dctx) => AlertDialog(
        title: const Text('Tambah Kategori'),
        content: LoitInput(label: 'Nama kategori', controller: ctrl),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dctx), child: const Text('Batal')),
          FilledButton(
              onPressed: () => Navigator.pop(dctx, ctrl.text.trim()),
              child: const Text('Tambah')),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      setState(() => into.add(_Cat(name)));
    }
  }

  // ---- Step 4: Konfirmasi ----
  Widget _stepConfirm() {
    final c = context.loitColors;
    final active = _penerimaan.where((e) => e.checked).length +
        _pengeluaran.where((e) => e.checked).length;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(LoitSpacing.s5, LoitSpacing.s7,
                LoitSpacing.s5, LoitSpacing.s7),
            children: [
              _Stagger(children: [
                const SizedBox(height: LoitSpacing.s5),
                Center(child: _SuccessFlourish(color: c.brand)),
                const SizedBox(height: LoitSpacing.s4),
                Text('Room berhasil dibuat',
                    textAlign: TextAlign.center,
                    style: LoitTypography.titleL
                        .copyWith(color: c.contentPrimary)),
                const SizedBox(height: LoitSpacing.s8),
                _GroupBox(
                  child: Column(
                    children: [
                      _confirmRow('Jemaat', _jemaat.text.trim()),
                      const _RowDivider(inset: false),
                      _confirmRow('Denominasi', _resolvedDenomination),
                      const _RowDivider(inset: false),
                      _confirmRow('Kategori', '$active kategori aktif'),
                    ],
                  ),
                ),
              ]),
            ],
          ),
        ),
        _bottomCta('Mulai Catat Keuangan', () {
          if (_createdRoomId != null) {
            context.pushReplacement('/rooms/$_createdRoomId');
          }
        }),
      ],
    );
  }

  Widget _confirmRow(String label, String value) {
    final c = context.loitColors;
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: LoitSpacing.s5, vertical: LoitSpacing.s4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 104,
            child: Text(label,
                style: LoitTypography.bodyM
                    .copyWith(color: c.contentSecondary)),
          ),
          Expanded(
            child: Text(value,
                style: LoitTypography.bodyM.copyWith(
                    color: c.contentPrimary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  String? _createdRoomId;

  Future<void> _create() async {
    setState(() => _busy = true);
    final svc = ref.read(roomServiceProvider);
    try {
      final orgConfig = <String, dynamic>{
        'denomination': _resolvedDenomination,
        'jemaat_name': _jemaat.text.trim(),
        'kota_kabupaten': _kota.text.trim(),
        // Raw national digits (ADR 0019); validated at step 1, so non-null here.
        'phone_number': normalizeIndoMobile(_phone.text) ?? '',
      };
      final room = await svc.createRoom(
        name: _jemaat.text.trim(),
        baseCurrency: 'IDR',
        orgType: 'church',
        orgConfig: orgConfig,
      );
      _createdRoomId = room['id'] as String;

      // Best effort (ADR 0019): a failed batch leaves the room with only the
      // catch-all — still usable. Land on the room anyway with a soft warning.
      try {
        await svc.seedChurchCategories(
          roomId: _createdRoomId!,
          penerimaan: [
            for (final c in _penerimaan)
              if (c.checked) c.name
          ],
          pengeluaran: [
            for (final c in _pengeluaran)
              if (c.checked) c.name
          ],
        );
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Kategori gagal dimuat — tambah manual di room.'),
          ));
        }
      }

      Analytics.roomCreated();
      ref.invalidate(myRoomsProvider);
      ref.invalidate(userCategoriesProvider);
      if (mounted) {
        setState(() {
          _forward = true;
          _step = 3;
        });
      }
    } on OnlineOnlyActionException {
      if (mounted) showRoomOnlineOnlySnack(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal membuat room: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

/// Normalize an Indonesian mobile number to national raw digits (`08xxxxxxxx`),
/// or null if invalid (ADR 0019). Accepts `+62…` / `62…` / `08…` with any
/// spaces or dashes; must resolve to `08` + 8–11 digits (10–13 total).
String? normalizeIndoMobile(String raw) {
  var d = raw.replaceAll(RegExp(r'[^\d]'), '');
  if (d.startsWith('62')) d = '0${d.substring(2)}';
  if (!d.startsWith('08')) return null;
  if (d.length < 10 || d.length > 13) return null;
  return d;
}

/// Group digits in blocks of 4 with a space: `0812 3456 7890`.
String groupDigits4(String digits) {
  final b = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && i % 4 == 0) b.write(' ');
    b.write(digits[i]);
  }
  return b.toString();
}

/// Live phone formatter: strips to digits, folds a `+62`/`62` country code to
/// the national `0`, then regroups every 4. Cursor parks at end.
// ponytail: cursor-at-end + the +62→0 fold makes the prefix transition jump
// once while typing intl form; the 08xx placeholder steers the common path and
// the value still converges. Per-keystroke cursor mapping if users complain.
class _PhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    var d = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (d.startsWith('62')) d = '0${d.substring(2)}';
    final text = groupDigits4(d);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class _Cat {
  _Cat(this.name);
  final String name;
  bool checked = true;
}

/// Fades + lifts its children into view in sequence on first build. Because each
/// step is keyed under the screen's [AnimatedSwitcher], a fresh stagger plays
/// every time a step is entered. Honours reduced-motion by snapping to the end.
class _Stagger extends StatefulWidget {
  const _Stagger({required this.children});
  final List<Widget> children;

  @override
  State<_Stagger> createState() => _StaggerState();
}

class _StaggerState extends State<_Stagger>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: LoitMotion.entrance);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
        _c.value = 1;
      } else {
        _c.forward();
      }
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.children.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < n; i++)
          AnimatedBuilder(
            animation: _c,
            // Each child opens over a half-window, shifted by index — capped so
            // long lists still finish inside the controller's run.
            builder: (_, child) {
              final start = (i * 0.1).clamp(0.0, 0.5).toDouble();
              final v = Interval(start, (start + 0.5).clamp(0.0, 1.0),
                      curve: LoitMotion.easeOutQuart)
                  .transform(_c.value);
              return Opacity(
                opacity: v,
                child: Transform.translate(
                    offset: Offset(0, (1 - v) * 12), child: child),
              );
            },
            child: widget.children[i],
          ),
      ],
    );
  }
}

/// Success moment for the confirmation step: the check scales in, a ring pulses
/// outward, and a radial particle burst fans out once. A medium haptic fires on
/// reveal. Reduced-motion shows the final check with no motion.
class _SuccessFlourish extends StatefulWidget {
  const _SuccessFlourish({required this.color});
  final Color color;

  @override
  State<_SuccessFlourish> createState() => _SuccessFlourishState();
}

class _SuccessFlourishState extends State<_SuccessFlourish>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
        _c.value = 1;
      } else {
        _c.forward();
      }
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 120,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = _c.value;
          final appear = const Interval(0.0, 0.5, curve: LoitMotion.easeOutExpo)
              .transform(t);
          final ring =
              const Interval(0.1, 1.0, curve: LoitMotion.easeOut).transform(t);
          return CustomPaint(
            painter: _BurstPainter(
                progress: t, ring: ring, color: widget.color),
            child: Center(
              child: Opacity(
                opacity: appear,
                child: Transform.scale(
                  scale: 0.6 + 0.4 * appear,
                  child: Icon(Icons.check_circle,
                      size: 56, color: widget.color),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Paints the expanding ring + outward particle dots for [_SuccessFlourish].
class _BurstPainter extends CustomPainter {
  _BurstPainter(
      {required this.progress, required this.ring, required this.color});
  final double progress;
  final double ring;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    if (ring > 0 && ring < 1) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = color.withValues(alpha: (1 - ring) * 0.5);
      canvas.drawCircle(center, 30 + ring * 28, paint);
    }
    if (progress < 1) {
      const n = 12;
      final dot = Paint()
        ..color = color.withValues(alpha: (1 - progress).clamp(0.0, 1.0));
      final dist = 26 + progress * 32;
      final radius = (1 - progress) * 2.5 + 0.5;
      for (var i = 0; i < n; i++) {
        final a = (i / n) * 2 * math.pi;
        canvas.drawCircle(
            center + Offset(math.cos(a), math.sin(a)) * dist, radius, dot);
      }
    }
  }

  @override
  bool shouldRepaint(_BurstPainter old) =>
      old.progress != progress || old.ring != ring;
}

/// Bordered surface container that groups related rows under one affordance —
/// the single list idiom shared by every step (denominations, categories,
/// confirmation summary). Clips so row tints honour the corner radius.
class _GroupBox extends StatelessWidget {
  const _GroupBox({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: LoitRadius.brM,
        border: Border.all(color: c.borderSubtle),
      ),
      child: child,
    );
  }
}

/// Hairline between rows inside a [_GroupBox]. Inset by default to start at the
/// row's text column; pass `inset: false` to span full width (e.g. above an
/// action row that has no leading icon to align to).
class _RowDivider extends StatelessWidget {
  const _RowDivider({this.inset = true});
  final bool inset;

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    return Container(
      height: 1,
      margin: EdgeInsets.only(left: inset ? LoitSpacing.s10 : 0),
      color: c.borderSubtle,
    );
  }
}

class _RadioRow extends StatelessWidget {
  const _RadioRow({
    required this.label,
    required this.selected,
    required this.onTap,
    this.grouped = false,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  /// Inside a [_GroupBox]: drop the per-row border/radius so the group's chrome
  /// carries it; selection reads as a row tint + filled, bolded radio.
  /// Standalone (`false`) keeps its own bordered pill.
  final bool grouped;

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    final row = Row(
      children: [
        AnimatedSwitcher(
          duration: LoitMotion.short,
          transitionBuilder: (ch, a) => ScaleTransition(scale: a, child: ch),
          child: Icon(
            selected ? Icons.radio_button_checked : Icons.radio_button_off,
            key: ValueKey(selected),
            size: 20,
            color: selected ? c.brand : c.contentTertiary,
          ),
        ),
        const SizedBox(width: LoitSpacing.s3),
        Expanded(
          child: Text(label,
              style: LoitTypography.bodyM.copyWith(
                  color: c.contentPrimary,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400)),
        ),
      ],
    );
    return InkWell(
      borderRadius: grouped ? null : LoitRadius.brM,
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: LoitMotion.short,
        curve: LoitMotion.easeOut,
        padding: EdgeInsets.symmetric(
            horizontal: grouped ? LoitSpacing.s5 : LoitSpacing.s4,
            vertical: grouped ? LoitSpacing.s4 : LoitSpacing.s3),
        decoration: grouped
            ? BoxDecoration(
                color: selected
                    ? c.brand.withValues(alpha: 0.06)
                    : Colors.transparent)
            : BoxDecoration(
                color: selected ? c.brand.withValues(alpha: 0.06) : c.surface,
                borderRadius: LoitRadius.brM,
                border: Border.all(
                    color: selected ? c.brand : c.borderSubtle,
                    width: selected ? 2 : 1),
              ),
        child: row,
      ),
    );
  }
}

class _CatColumn extends StatelessWidget {
  const _CatColumn({
    required this.title,
    required this.items,
    required this.onToggle,
    required this.onAdd,
  });
  final String title;
  final List<_Cat> items;
  final void Function(int index) onToggle;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: LoitSpacing.s2),
          child: Text(title,
              style: LoitTypography.labelS
                  .copyWith(color: c.contentSecondary, letterSpacing: 0.5)),
        ),
        const SizedBox(height: LoitSpacing.s3),
        _GroupBox(
          child: Column(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) const _RowDivider(),
                InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onToggle(i);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: LoitSpacing.s5, vertical: LoitSpacing.s4),
                    child: Row(
                      children: [
                        AnimatedSwitcher(
                          duration: LoitMotion.short,
                          transitionBuilder: (ch, a) =>
                              ScaleTransition(scale: a, child: ch),
                          child: Icon(
                            items[i].checked
                                ? Icons.check_box
                                : Icons.check_box_outline_blank,
                            key: ValueKey(items[i].checked),
                            size: 20,
                            color: items[i].checked
                                ? c.brand
                                : c.contentTertiary,
                          ),
                        ),
                        const SizedBox(width: LoitSpacing.s3),
                        Expanded(
                          child: Text(items[i].name,
                              style: LoitTypography.bodyM
                                  .copyWith(color: c.contentPrimary)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const _RowDivider(inset: false),
              InkWell(
                onTap: onAdd,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: LoitSpacing.s5, vertical: LoitSpacing.s4),
                  child: Row(
                    children: [
                      Icon(Icons.add, size: 20, color: c.brand),
                      const SizedBox(width: LoitSpacing.s3),
                      Text('Tambah Kategori',
                          style: LoitTypography.bodyM
                              .copyWith(color: c.brand)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
