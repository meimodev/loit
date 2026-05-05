import 'package:flutter/material.dart';

/// Category visual style resolved from user_categories or defaults.
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

  static const defaultOther = LoitCategoryStyle(
    tint: Color(0xFF9AA09E),
    icon: Icons.more_horiz,
    label: 'Other',
  );

  static final Map<String, IconData> _nameToIcon = {
    'restaurant_outlined': Icons.restaurant_outlined,
    'local_grocery_store_outlined': Icons.local_grocery_store_outlined,
    'shopping_basket_outlined': Icons.shopping_basket_outlined,
    'shopping_bag_outlined': Icons.shopping_bag_outlined,
    'shopping_cart_outlined': Icons.shopping_cart_outlined,
    'directions_car_outlined': Icons.directions_car_outlined,
    'directions_bus_outlined': Icons.directions_bus_outlined,
    'flight_outlined': Icons.flight_outlined,
    'local_activity_outlined': Icons.local_activity_outlined,
    'movie_outlined': Icons.movie_outlined,
    'sports_esports_outlined': Icons.sports_esports_outlined,
    'power_outlined': Icons.power_outlined,
    'bolt_outlined': Icons.bolt_outlined,
    'water_drop_outlined': Icons.water_drop_outlined,
    'medical_services_outlined': Icons.medical_services_outlined,
    'favorite_border': Icons.favorite_border,
    'local_hospital_outlined': Icons.local_hospital_outlined,
    'more_horiz': Icons.more_horiz,
    'category_outlined': Icons.category_outlined,
    'receipt_long_outlined': Icons.receipt_long_outlined,
    'work_outline': Icons.work_outline,
    'card_giftcard': Icons.card_giftcard,
    'handyman_outlined': Icons.handyman_outlined,
    'trending_up': Icons.trending_up,
    'redeem': Icons.redeem,
    'savings_outlined': Icons.savings_outlined,
    'assignment_return_outlined': Icons.assignment_return_outlined,
    'school_outlined': Icons.school_outlined,
    'pets_outlined': Icons.pets_outlined,
    'home_outlined': Icons.home_outlined,
    'child_care_outlined': Icons.child_care_outlined,
    'fitness_center_outlined': Icons.fitness_center_outlined,
    'phone_android_outlined': Icons.phone_android_outlined,
    'devices_outlined': Icons.devices_outlined,
    'coffee_outlined': Icons.coffee_outlined,
    'emoji_events_outlined': Icons.emoji_events_outlined,
    'volunteer_activism_outlined': Icons.volunteer_activism_outlined,
    'support_outlined': Icons.support_outlined,
    'attach_money_outlined': Icons.attach_money_outlined,
    'account_balance_outlined': Icons.account_balance_outlined,
    'request_quote_outlined': Icons.request_quote_outlined,
    'currency_exchange_outlined': Icons.currency_exchange_outlined,
  };

  static IconData? iconFromName(String? name) {
    if (name == null) return null;
    return _nameToIcon[name] ?? Icons.category_outlined;
  }

  static const List<String> commonIconNames = [
    'restaurant_outlined',
    'local_grocery_store_outlined',
    'shopping_basket_outlined',
    'shopping_bag_outlined',
    'shopping_cart_outlined',
    'directions_car_outlined',
    'directions_bus_outlined',
    'flight_outlined',
    'local_activity_outlined',
    'movie_outlined',
    'sports_esports_outlined',
    'power_outlined',
    'bolt_outlined',
    'water_drop_outlined',
    'medical_services_outlined',
    'favorite_border',
    'local_hospital_outlined',
    'more_horiz',
    'category_outlined',
    'receipt_long_outlined',
    'work_outline',
    'card_giftcard',
    'handyman_outlined',
    'trending_up',
    'redeem',
    'savings_outlined',
    'assignment_return_outlined',
    'school_outlined',
    'pets_outlined',
    'home_outlined',
    'child_care_outlined',
    'fitness_center_outlined',
    'phone_android_outlined',
    'devices_outlined',
    'coffee_outlined',
    'emoji_events_outlined',
    'volunteer_activism_outlined',
    'support_outlined',
    'attach_money_outlined',
    'account_balance_outlined',
    'request_quote_outlined',
    'currency_exchange_outlined',
  ];
}
