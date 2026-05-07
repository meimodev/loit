import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// id_ID-style formatter: `.` as thousand separator, `,` as decimal.
/// Auto-inserts thousand separators while typing.
class ThousandsInputFormatter extends TextInputFormatter {
  static final NumberFormat _intFmt = NumberFormat('#,##0', 'id_ID');

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

/// Format a numeric value into the input text (id_ID thousand sep, no symbol).
String formatAmountInput(double v) {
  if (v == v.truncateToDouble()) {
    return NumberFormat('#,##0', 'id_ID').format(v);
  }
  return NumberFormat('#,##0.##', 'id_ID').format(v);
}
