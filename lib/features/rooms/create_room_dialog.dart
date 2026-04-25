import 'package:flutter/material.dart';

import '../../core/services/interaction_log_service.dart';
import '../../core/services/room_service.dart';

class CreateRoomDialog extends StatefulWidget {
  const CreateRoomDialog({super.key, required this.onCreated});
  final void Function(Map<String, dynamic> room) onCreated;

  @override
  State<CreateRoomDialog> createState() => _CreateRoomDialogState();
}

class _CreateRoomDialogState extends State<CreateRoomDialog> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _currency = 'IDR';
  bool _busy = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;

    setState(() => _busy = true);
    try {
      final room = await RoomService().createRoom(
        name: name,
        description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        baseCurrency: _currency,
      );
      InteractionLog.success(
        action: 'room_created',
        screen: 'create_room',
        message: name,
        metadata: {'currency': _currency},
      );
      if (mounted) {
        Navigator.of(context).pop();
        widget.onCreated(room);
      }
    } catch (e) {
      InteractionLog.error(
        action: 'room_create',
        screen: 'create_room',
        message: '$e',
        metadata: {'name': name, 'currency': _currency},
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Room'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameCtrl,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Room name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descCtrl,
            decoration: const InputDecoration(
              labelText: 'Description (optional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _currency,
            decoration: const InputDecoration(
              labelText: 'Base currency',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'IDR', child: Text('IDR')),
              DropdownMenuItem(value: 'USD', child: Text('USD')),
              DropdownMenuItem(value: 'EUR', child: Text('EUR')),
              DropdownMenuItem(value: 'SGD', child: Text('SGD')),
              DropdownMenuItem(value: 'MYR', child: Text('MYR')),
              DropdownMenuItem(value: 'JPY', child: Text('JPY')),
            ],
            onChanged: (v) => setState(() => _currency = v ?? 'IDR'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _busy ? null : _create,
          child: _busy
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create'),
        ),
      ],
    );
  }
}
