import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Legacy entry point for room budgets. The room detail Budget tab is now
/// the primary management surface, so this screen redirects there to keep
/// a single budget UX path (create/edit/delete via [RoomBudgetFormScreen]).
class RoomBudgetsScreen extends ConsumerStatefulWidget {
  const RoomBudgetsScreen({super.key, required this.roomId});
  final String roomId;

  @override
  ConsumerState<RoomBudgetsScreen> createState() => _RoomBudgetsScreenState();
}

class _RoomBudgetsScreenState extends ConsumerState<RoomBudgetsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.go('/rooms/${widget.roomId}?tab=1');
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
