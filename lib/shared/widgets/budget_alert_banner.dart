import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/analytics_service.dart';
import '../providers/budgets_provider.dart';

/// Renders the most urgent active budget alert (exceeded > 80%).
/// Fires `budget_alert_shown` analytics exactly once per category+type per session.
class BudgetAlertBanner extends ConsumerStatefulWidget {
  const BudgetAlertBanner({super.key});

  @override
  ConsumerState<BudgetAlertBanner> createState() => _BudgetAlertBannerState();
}

class _BudgetAlertBannerState extends ConsumerState<BudgetAlertBanner> {
  final _seen = <String>{};

  @override
  Widget build(BuildContext context) {
    final statuses = ref.watch(budgetStatusesProvider);
    final alerts = statuses.where((s) => s.isOver || s.isNearLimit).toList();
    if (alerts.isEmpty) return const SizedBox.shrink();

    // Pick the worst: exceeded first, then near limit.
    alerts.sort((a, b) => b.ratio.compareTo(a.ratio));
    final worst = alerts.first;
    final type = worst.isOver ? 'exceeded' : '80_percent';
    final key = '${worst.budget.category}:$type';
    if (!_seen.contains(key)) {
      _seen.add(key);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Analytics.budgetAlertShown(type);
      });
    }

    final color = worst.isOver
        ? Theme.of(context).colorScheme.errorContainer
        : Colors.amber.shade100;
    final onColor = worst.isOver
        ? Theme.of(context).colorScheme.onErrorContainer
        : Colors.amber.shade900;

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(worst.isOver ? Icons.error_outline : Icons.warning_amber,
              color: onColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              worst.isOver
                  ? '${worst.budget.category} is over budget '
                      '(${(worst.ratio * 100).toStringAsFixed(0)}%)'
                  : '${worst.budget.category} is at '
                      '${(worst.ratio * 100).toStringAsFixed(0)}% of budget',
              style: TextStyle(color: onColor, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
