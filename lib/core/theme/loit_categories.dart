import 'package:flutter/material.dart';

/// Category → tint + icon mapping per LOIT design system.
///
/// Mirrors `CAT_TINT` / `CAT_ICON` from `primitives.jsx`.
/// Background tint = `tint @ 12% alpha` (light) or `@ 20%` (dark).
class LoitCategoryStyle {
  const LoitCategoryStyle({
    required this.tint,
    required this.icon,
    required this.label,
  });
  final Color tint;
  final IconData icon;
  final String label;
}

class LoitCategories {
  LoitCategories._();

  static const dining = LoitCategoryStyle(
    tint: Color(0xFFF2A85C),
    icon: Icons.restaurant_outlined,
    label: 'Dining',
  );
  static const groceries = LoitCategoryStyle(
    tint: Color(0xFF2F8F5E),
    icon: Icons.shopping_basket_outlined,
    label: 'Groceries',
  );
  static const transport = LoitCategoryStyle(
    tint: Color(0xFF3E7AC5),
    icon: Icons.directions_car_outlined,
    label: 'Transport',
  );
  static const shopping = LoitCategoryStyle(
    tint: Color(0xFFB15FC0),
    icon: Icons.shopping_bag_outlined,
    label: 'Shopping',
  );
  static const entertainment = LoitCategoryStyle(
    tint: Color(0xFFE06B8A),
    icon: Icons.local_activity_outlined,
    label: 'Entertainment',
  );
  static const utilities = LoitCategoryStyle(
    tint: Color(0xFF5A6160),
    icon: Icons.power_outlined,
    label: 'Utilities',
  );
  static const health = LoitCategoryStyle(
    tint: Color(0xFFC5443E),
    icon: Icons.favorite_border,
    label: 'Health',
  );
  static const travel = LoitCategoryStyle(
    tint: Color(0xFF188268),
    icon: Icons.flight_outlined,
    label: 'Travel',
  );
  static const other = LoitCategoryStyle(
    tint: Color(0xFF9AA09E),
    icon: Icons.more_horiz,
    label: 'Other',
  );

  // Income categories — green-family tints to read as positive at a glance.
  static const _incomeTint = Color(0xFF2F8F5E);
  static const incomeSalary = LoitCategoryStyle(
    tint: _incomeTint,
    icon: Icons.work_outline,
    label: 'Salary',
  );
  static const incomeBonus = LoitCategoryStyle(
    tint: Color(0xFF3CA876),
    icon: Icons.card_giftcard,
    label: 'Bonus',
  );
  static const incomeFreelance = LoitCategoryStyle(
    tint: Color(0xFF188268),
    icon: Icons.handyman_outlined,
    label: 'Freelance',
  );
  static const incomeInvestment = LoitCategoryStyle(
    tint: Color(0xFF4FA88B),
    icon: Icons.trending_up,
    label: 'Investment',
  );
  static const incomeGift = LoitCategoryStyle(
    tint: Color(0xFFB7CF8C),
    icon: Icons.redeem,
    label: 'Gift',
  );
  static const incomeRefund = LoitCategoryStyle(
    tint: Color(0xFF6EAA92),
    icon: Icons.assignment_return_outlined,
    label: 'Refund',
  );
  static const incomeOther = LoitCategoryStyle(
    tint: Color(0xFF8FB7A6),
    icon: Icons.savings_outlined,
    label: 'Other income',
  );

  static const Map<String, LoitCategoryStyle> byKey = {
    'dining': dining,
    'groceries': groceries,
    'transport': transport,
    'shopping': shopping,
    'entertainment': entertainment,
    'utilities': utilities,
    'health': health,
    'travel': travel,
    'other': other,
    'income_salary': incomeSalary,
    'income_bonus': incomeBonus,
    'income_freelance': incomeFreelance,
    'income_investment': incomeInvestment,
    'income_gift': incomeGift,
    'income_refund': incomeRefund,
    'income_other': incomeOther,
  };

  static const List<String> expenseKeys = [
    'dining',
    'groceries',
    'transport',
    'shopping',
    'entertainment',
    'utilities',
    'health',
    'travel',
    'other',
  ];

  static const List<String> incomeKeys = [
    'income_salary',
    'income_bonus',
    'income_freelance',
    'income_investment',
    'income_gift',
    'income_refund',
    'income_other',
  ];

  static LoitCategoryStyle resolve(String? key) {
    if (key == null) return other;
    return byKey[key.toLowerCase()] ?? other;
  }
}
