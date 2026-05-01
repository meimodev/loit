import 'package:flutter/material.dart';

/// Built-in transaction categories (Free tier). Custom categories are a Pro feature.
class Categories {
  const Categories._();

  static const List<String> expense = [
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

  static const List<String> income = [
    'income_salary',
    'income_bonus',
    'income_freelance',
    'income_investment',
    'income_gift',
    'income_refund',
    'income_other',
  ];

  /// Legacy alias kept for callers still referencing the original expense list.
  static const List<String> all = expense;

  /// All category keys (expense + income) for full lookups.
  static List<String> get every => [...expense, ...income];

  static List<String> forKind({required bool isIncome}) =>
      isIncome ? income : expense;

  static bool isIncomeKey(String? key) =>
      key != null && key.startsWith('income_');

  static IconData iconFor(String? category) {
    switch (category) {
      case 'dining':
        return Icons.restaurant;
      case 'groceries':
        return Icons.local_grocery_store;
      case 'transport':
        return Icons.directions_car;
      case 'shopping':
        return Icons.shopping_bag;
      case 'entertainment':
        return Icons.movie;
      case 'utilities':
        return Icons.bolt;
      case 'health':
        return Icons.medical_services;
      case 'travel':
        return Icons.flight;
      case 'income_salary':
        return Icons.work_outline;
      case 'income_bonus':
        return Icons.card_giftcard;
      case 'income_freelance':
        return Icons.handyman_outlined;
      case 'income_investment':
        return Icons.trending_up;
      case 'income_gift':
        return Icons.redeem;
      case 'income_refund':
        return Icons.assignment_return_outlined;
      case 'income_other':
        return Icons.savings_outlined;
      default:
        return Icons.receipt_long;
    }
  }
}

/// Common currencies surfaced in pickers (Free tier: 10 currencies).
const kCommonCurrencies = [
  'IDR', 'USD', 'EUR', 'GBP', 'JPY', 'SGD', 'MYR', 'AUD', 'CNY', 'THB',
];
