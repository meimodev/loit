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
}
