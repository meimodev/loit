import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/services/log_service.dart';
import '../../core/theme/loit_colors.dart';
import '../../core/theme/loit_typography.dart';
import '../../l10n/l10n_x.dart';
import '../../shared/providers/messaging_link_provider.dart';
import '../../shared/widgets/loit_button.dart';
import '_widgets.dart';

const _kBotUsername = 'LoitAppBot';

class TelegramConnectScreen extends ConsumerStatefulWidget {
  const TelegramConnectScreen({super.key});

  @override
  ConsumerState<TelegramConnectScreen> createState() =>
      _TelegramConnectScreenState();
}

class _TelegramConnectScreenState extends ConsumerState<TelegramConnectScreen>
    with WidgetsBindingObserver {
  bool _disclosureAccepted = false;
  bool _busy = false;
  Timer? _poll;
  Timer? _visibleRefresh;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Catch `/end` sent from the Telegram side while this screen is open.
    _visibleRefresh = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) ref.invalidate(telegramLinkStatusProvider);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _poll?.cancel();
    _visibleRefresh?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(telegramLinkStatusProvider);
    }
  }

  Future<void> _startConnect() async {
    final l = context.l10n;
    setState(() => _busy = true);
    try {
      final svc = ref.read(messagingLinkServiceProvider);
      final code = await svc.generateTelegramLinkCode();
      final uri = Uri.parse('https://t.me/$_kBotUsername?start=$code');
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.telegramOpenFailed)),
        );
      }
      _poll?.cancel();
      _poll = Timer.periodic(const Duration(seconds: 3), (_) {
        ref.invalidate(telegramLinkStatusProvider);
      });
      // Stop polling after 5 minutes to avoid wasted RPCs.
      Timer(const Duration(minutes: 5), () => _poll?.cancel());
    } catch (e, st) {
      Log.e('TelegramConnect', 'generate code failed', error: e, stack: st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.telegramGenerateFailed)),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _disconnect() async {
    final l = context.l10n;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.telegramDisconnectTitle),
        content: Text(l.telegramDisconnectBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l.telegramDisconnectConfirm),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _busy = true);
    try {
      await ref.read(messagingLinkServiceProvider).disconnectTelegram();
      ref.invalidate(telegramLinkStatusProvider);
    } catch (e, st) {
      Log.e('TelegramConnect', 'disconnect failed', error: e, stack: st);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    final l = context.l10n;
    final status = ref.watch(telegramLinkStatusProvider);

    return Scaffold(
      backgroundColor: c.canvas,
      appBar: AppBar(
        title: Text(l.telegramTitle),
        backgroundColor: c.canvas,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: status.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (s) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Text(l.telegramIntro, style: LoitTypography.bodyM),
            const SizedBox(height: 16),
            if (s.linked) ...[
              SettingsGroup(label: l.telegramConnectedSectionLabel, children: [
                SettingsRow(
                  label: l.telegramConnectedChat,
                  value: s.externalChatId ?? '',
                  showChevron: false,
                ),
              ]),
              const SizedBox(height: 24),
              LoitButton.destructive(
                label: l.telegramDisconnect,
                onPressed: _busy ? null : _disconnect,
                fullWidth: true,
              ),
            ] else ...[
              SettingsGroup(label: l.telegramDisclosureLabel, children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Text(
                    l.telegramDisclosureBody,
                    style: LoitTypography.bodyS
                        .copyWith(color: c.contentSecondary),
                  ),
                ),
                CheckboxListTile(
                  value: _disclosureAccepted,
                  onChanged: (v) =>
                      setState(() => _disclosureAccepted = v ?? false),
                  title: Text(l.telegramDisclosureAccept),
                ),
              ]),
              const SizedBox(height: 24),
              LoitButton.primary(
                label: _busy ? l.telegramConnecting : l.telegramConnect,
                onPressed: !_disclosureAccepted || _busy ? null : _startConnect,
                fullWidth: true,
                loading: _busy,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
