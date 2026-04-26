import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InviteSheet extends StatefulWidget {
  const InviteSheet({
    super.key,
    required this.roomId,
    required this.roomName,
    required this.inviteToken,
    required this.isCreator,
  });

  final String roomId;
  final String roomName;
  final String inviteToken;
  final bool isCreator;

  @override
  State<InviteSheet> createState() => _InviteSheetState();
}

class _InviteSheetState extends State<InviteSheet> {
  late String _token = widget.inviteToken;
  bool _regenerating = false;
  String? _error;

  String get _inviteUrl => 'https://loit.app/invite/$_token';

  Future<void> _regenerateLink() async {
    setState(() {
      _regenerating = true;
      _error = null;
    });
    try {
      final newToken = await Supabase.instance.client.rpc(
        'regenerate_room_invite_token',
        params: {'p_room_id': widget.roomId},
      ) as String;
      if (mounted) setState(() => _token = newToken);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _regenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Invite to ${widget.roomName}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            QrImageView(data: _inviteUrl, size: 220),
            const SizedBox(height: 16),
            SelectableText(
              _inviteUrl,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              icon: const Icon(Icons.share),
              label: const Text('Share link'),
              onPressed: () => Share.share(
                'Join ${widget.roomName} on LOIT: $_inviteUrl',
              ),
            ),
            if (widget.isCreator) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: _regenerating ? null : _regenerateLink,
                child: Text(
                  _regenerating
                      ? 'Regenerating…'
                      : 'Regenerate link (invalidates old)',
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
