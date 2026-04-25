import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InviteSheet extends StatefulWidget {
  const InviteSheet({super.key, required this.roomId, required this.roomName});
  final String roomId;
  final String roomName;

  @override
  State<InviteSheet> createState() => _InviteSheetState();
}

class _InviteSheetState extends State<InviteSheet> {
  final _emailCtrl = TextEditingController();
  String? _inviteUrl;
  String? _error;
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _createInvite() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final resp = await Supabase.instance.client.functions.invoke(
        'create-room-invite',
        body: {'room_id': widget.roomId, 'invited_email': email},
      );
      if (resp.status >= 400) {
        setState(
            () => _error = resp.data?.toString() ?? 'Failed to create invite');
        return;
      }
      final data = resp.data as Map<String, dynamic>;
      setState(() => _inviteUrl = data['invite_url'] as String);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_inviteUrl != null) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Invite to ${widget.roomName}',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              QrImageView(data: _inviteUrl!, size: 200),
              const SizedBox(height: 16),
              SelectableText(_inviteUrl!, textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 16),
              FilledButton.icon(
                icon: const Icon(Icons.share),
                label: const Text('Share link'),
                onPressed: () => Share.share(
                  'Join my room "${widget.roomName}" on LOIT: $_inviteUrl',
                ),
              ),
              const SizedBox(height: 8),
              Text('Expires in 7 days',
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      );
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Invite to ${widget.roomName}',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Email address',
                hintText: 'friend@example.com',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _createInvite(),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _loading ? null : _createInvite,
              child: _loading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Generate invite'),
            ),
          ],
        ),
      ),
    );
  }
}
