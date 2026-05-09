import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Auto-inserts thousand separators while typing. Locale-aware via
/// [localeTag] (defaults to system locale).
class ThousandsInputFormatter extends TextInputFormatter {
  ThousandsInputFormatter({this.localeTag});

  final String? localeTag;

  NumberFormat get _intFmt => localeTag != null
      ? NumberFormat('#,##0', localeTag)
      : NumberFormat('#,##0');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.isEmpty) return newValue;

    final clean = text.replaceAll(RegExp(r'[^\d.,]'), '');
    String intStr;
    String? decStr;
    final commaIdx = clean.lastIndexOf(',');
    if (commaIdx >= 0) {
      intStr = clean.substring(0, commaIdx).replaceAll(RegExp(r'[.,]'), '');
      decStr = clean.substring(commaIdx + 1).replaceAll(RegExp(r'[.,]'), '');
    } else {
      intStr = clean.replaceAll('.', '');
    }

    if (intStr.isEmpty && (decStr == null || decStr.isEmpty)) {
      return const TextEditingValue();
    }

    final intNum = int.tryParse(intStr.isEmpty ? '0' : intStr) ?? 0;
    final intFormatted = _intFmt.format(intNum);
    final out = decStr != null ? '$intFormatted,$decStr' : intFormatted;
    return TextEditingValue(
      text: out,
      selection: TextSelection.collapsed(offset: out.length),
    );
  }
}

/// Parse user-entered amount (id_ID or loose). Returns null when empty/invalid.
double? parseAmountInput(String s) {
  if (s.trim().isEmpty) return null;
  final cleaned = s.trim().replaceAll(RegExp(r'[^\d.,-]'), '');
  if (cleaned.isEmpty) return null;
  final lastSep = cleaned.lastIndexOf(RegExp(r'[.,]'));
  if (lastSep == -1) return double.tryParse(cleaned);
  final tail = cleaned.substring(lastSep + 1);
  if (tail.isNotEmpty &&
      tail.length <= 2 &&
      !tail.contains(RegExp(r'[.,]'))) {
    final intPart =
        cleaned.substring(0, lastSep).replaceAll(RegExp(r'[.,]'), '');
    return double.tryParse('${intPart.isEmpty ? '0' : intPart}.$tail');
  }
  return double.tryParse(cleaned.replaceAll(RegExp(r'[.,]'), ''));
}

/// Decimal digits to render for a given currency code in display contexts.
/// IDR uses 0 (whole rupiah); other currencies use 2.
int currencyDecimals(String? code) => code == 'IDR' ? 0 : 2;

/// Format a numeric value into input text (locale-aware thousand sep, no symbol).
String formatAmountInput(double v, {String? localeTag}) {
  final l = localeTag;
  if (v == v.truncateToDouble()) {
    return l != null
        ? NumberFormat('#,##0', l).format(v)
        : NumberFormat('#,##0').format(v);
  }
  return l != null
      ? NumberFormat('#,##0.##', l).format(v)
      : NumberFormat('#,##0.##').format(v);
}

/// Locale-aware money formatter shared across the app. IDR gets 0 decimals,
/// everything else 2. Pass [showSign] to render +/- prefix.
/// Provide [localeTag] (e.g. 'en_US' or 'id_ID') for explicit locale control.
String formatMoney(double amount, String currency,
    {bool showSign = false, String? localeTag}) {
  final fmt = localeTag != null
      ? NumberFormat.simpleCurrency(
          name: currency, decimalDigits: currencyDecimals(currency), locale: localeTag)
      : NumberFormat.simpleCurrency(
          name: currency, decimalDigits: currencyDecimals(currency));
  final formatted = fmt.format(amount.abs());
  if (!showSign) return formatted;
  return amount < 0 ? '-$formatted' : '+$formatted';
}

/// Currency symbol for [currency] under the current locale.
String currencySymbol(String currency) =>
    NumberFormat.simpleCurrency(name: currency).currencySymbol;
