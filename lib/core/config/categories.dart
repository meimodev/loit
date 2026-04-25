import 'package:flutter/material.dart';

/// Built-in transaction categories (Free tier). Custom categories are a Pro feature.
class Categories {
  const Categories._();

  static const List<String> all = [
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
      default:
        return Icons.receipt_long;
    }
  }
}

/// Common currencies surfaced in pickers (Free tier: 10 currencies).
const kCommonCurrencies = [
  'IDR', 'USD', 'EUR', 'GBP', 'JPY', 'SGD', 'MYR', 'AUD', 'CNY', 'THB',
];
