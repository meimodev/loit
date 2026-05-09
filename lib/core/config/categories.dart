import 'package:flutter/widgets.dart';

import '../../l10n/l10n_x.dart';

/// Default category seeds. User-defined categories are in user_categories table.
/// These keys match the migration seed so existing historical data resolves.
class CategoryDefaults {
  CategoryDefaults._();

  static const List<String> expenseKeys = [
    'dining', 'groceries', 'transport', 'shopping',
    'entertainment', 'utilities', 'health', 'travel', 'other',
  ];

  static const List<String> incomeKeys = [
    'income_salary', 'income_bonus', 'income_freelance',
    'income_investment', 'income_gift', 'income_refund', 'income_other',
  ];

  static List<String> get allKeys => [...expenseKeys, ...incomeKeys];

  static bool isDefault(String key) => allKeys.contains(key);

  static String localizeCategory(BuildContext context, String key) {
    final l = context.l10n;
    return switch (key) {
      'dining' => l.category_dining,
      'groceries' => l.category_groceries,
      'transport' => l.category_transport,
      'shopping' => l.category_shopping,
      'entertainment' => l.category_entertainment,
      'utilities' => l.category_utilities,
      'health' => l.category_health,
      'travel' => l.category_travel,
      'other' => l.category_other,
      'income_salary' => l.category_income_salary,
      'income_bonus' => l.category_income_bonus,
      'income_freelance' => l.category_income_freelance,
      'income_investment' => l.category_income_investment,
      'income_gift' => l.category_income_gift,
      'income_refund' => l.category_income_refund,
      'income_other' => l.category_income_other,
      _ => key,
    };
  }
}
