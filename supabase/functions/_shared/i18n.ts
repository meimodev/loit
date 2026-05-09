export type Locale = 'en' | 'id';

const dict: Record<string, Record<string, string>> = {
  en: {
    incomeRecorded: 'Income recorded',
    newExpense: 'New expense',
    roomTransaction: '{amount} {currency}',
  },
  id: {
    incomeRecorded: 'Pemasukan dicatat',
    newExpense: 'Pengeluaran baru',
    roomTransaction: '{amount} {currency}',
  },
};

export function t(locale: Locale, key: string, params?: Record<string, string>): string {
  const val = dict[locale]?.[key] ?? dict['en'][key] ?? key;
  if (!params) return val;
  return val.replace(/\{(\w+)\}/g, (_, name) => params[name] ?? `{${name}}`);
}

export function resolveLocale(language: string | null | undefined): Locale {
  if (language === 'id') return 'id';
  return 'en';
}
