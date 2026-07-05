import 'package:intl/intl.dart';

import '../../shared/utils/amount_input.dart';

class NotesBreakdownItem {
  const NotesBreakdownItem({
    required this.name,
    this.qty,
    this.unitPrice,
    this.totalPrice,
  });

  final String name;
  final double? qty;
  final double? unitPrice;
  final double? totalPrice;
}

class NotesBreakdown {
  const NotesBreakdown({
    required this.merchant,
    required this.items,
    this.total,
    this.currency,
    this.note,
  });

  final String merchant;
  final List<NotesBreakdownItem> items;
  final double? total;

  /// The user's free-text remark (Catatan) — ADR-0024. Rides the canonical
  /// notes text as a trailing `Catatan:` line, distinct from merchant/items.
  final String? note;

  /// ISO-4217 code for prices in this breakdown. When set, `formatBreakdown`
  /// prefixes price tokens with the currency symbol (e.g. `Rp`, `$`). Qty
  /// stays unprefixed. Null preserves legacy plain-number formatting.
  final String? currency;
}

final NumberFormat _kThousand = NumberFormat('#,##0.##', 'id_ID');

String _fmtNum(double v) => _kThousand.format(v);

String _fmtMoney(double v, String? currency) {
  final n = _fmtNum(v);
  if (currency == null || currency.isEmpty) return n;
  return '${currencySymbol(currency)} $n';
}

double? _parseLooseNumber(String s) {
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

/// Fills missing unit_price ↔ total_price ↔ qty using the other two when
/// possible. Treats `<= 0` as missing (AI sometimes emits 0 for unknown).
/// Returns a new list; original instances are not mutated.
List<NotesBreakdownItem> inferMissingItemMath(List<NotesBreakdownItem> items) {
  bool valid(double? v) => v != null && v > 0;
  return [
    for (final it in items)
      () {
        var qty = valid(it.qty) ? it.qty : null;
        var unit = valid(it.unitPrice) ? it.unitPrice : null;
        var total = valid(it.totalPrice) ? it.totalPrice : null;
        if (total == null && qty != null && unit != null) {
          total = qty * unit;
        } else if (unit == null && total != null && qty != null) {
          unit = total / qty;
        } else if (qty == null && total != null && unit != null) {
          qty = total / unit;
        }
        return NotesBreakdownItem(
          name: it.name,
          qty: qty,
          unitPrice: unit,
          totalPrice: total,
        );
      }(),
  ];
}

String formatBreakdown(NotesBreakdown b) {
  final cur = b.currency;
  final lines = <String>[];
  if (b.merchant.trim().isNotEmpty) lines.add(b.merchant.trim());
  for (final it in b.items) {
    final name = it.name.trim();
    final hasQty = it.qty != null;
    final hasUnit = it.unitPrice != null;
    final hasTotal = it.totalPrice != null;
    if (name.isEmpty && !hasQty && !hasUnit && !hasTotal) continue;
    final buf = StringBuffer('- ');
    buf.write(name);
    final right = <String>[];
    if (hasQty && hasUnit) {
      right.add('${_fmtNum(it.qty!)} × ${_fmtMoney(it.unitPrice!, cur)}');
    } else if (hasQty) {
      right.add('${_fmtNum(it.qty!)} ×');
    } else if (hasUnit) {
      right.add('× ${_fmtMoney(it.unitPrice!, cur)}');
    }
    if (hasTotal) {
      right.add('= ${_fmtMoney(it.totalPrice!, cur)}');
    }
    if (right.isNotEmpty) {
      buf.write(name.isEmpty ? '' : ' : ');
      buf.write(right.join(' '));
    }
    lines.add(buf.toString());
  }
  if (b.total != null) lines.add('Total: ${_fmtMoney(b.total!, cur)}');
  final note = b.note?.replaceAll('\n', ' ').trim() ?? '';
  if (note.isNotEmpty) lines.add('Catatan: $note');
  return lines.join('\n');
}

final RegExp _kBulletItem = RegExp(r'^\s*[-•*]\s+(.*)$');
final RegExp _kTotalLine = RegExp(r'^\s*Total\s*:\s*(.+)$', caseSensitive: false);
final RegExp _kSubtotalLine =
    RegExp(r'^\s*Subtotal\s*:\s*(.+)$', caseSensitive: false);
// Writer emits `Catatan:`; parser also accepts `Note:`/`Notes:` (ADR-0024).
final RegExp _kNoteLine =
    RegExp(r'^\s*(?:Catatan|Notes?)\s*:\s*(.+)$', caseSensitive: false);

NotesBreakdownItem? _parseItemLine(String body) {
  // Body shape: "<name> : <rest>" or "<name>" only.
  String name;
  String rest;
  final colon = body.indexOf(':');
  if (colon == -1) {
    name = body.trim();
    rest = '';
  } else {
    name = body.substring(0, colon).trim();
    rest = body.substring(colon + 1).trim();
  }

  double? qty, unit, total;
  if (rest.isNotEmpty) {
    String left = rest;
    final eqIdx = rest.lastIndexOf('=');
    if (eqIdx != -1) {
      total = _parseLooseNumber(rest.substring(eqIdx + 1));
      left = rest.substring(0, eqIdx).trim();
    }
    // Strip currency letters/symbols so `Rp 1.000 × Rp 2.000` reduces to
    // `1.000 × 2.000` before the qty/unit regex runs.
    left = left.replaceAll(RegExp(r'[^\d.,xX×\s-]'), ' ').trim();
    if (left.isNotEmpty) {
      // qty × unit, qty x unit, or single number.
      final m =
          RegExp(r'^\s*([\d.,]+)\s*[x×X]\s*([\d.,]+)\s*$').firstMatch(left);
      if (m != null) {
        qty = _parseLooseNumber(m.group(1)!);
        unit = _parseLooseNumber(m.group(2)!);
      } else {
        // qty ×  (open)
        final m2 = RegExp(r'^\s*([\d.,]+)\s*[x×X]\s*$').firstMatch(left);
        if (m2 != null) {
          qty = _parseLooseNumber(m2.group(1)!);
        } else {
          // × unit
          final m3 = RegExp(r'^\s*[x×X]\s*([\d.,]+)\s*$').firstMatch(left);
          if (m3 != null) {
            unit = _parseLooseNumber(m3.group(1)!);
          } else {
            // single number → treat as unit
            final n = _parseLooseNumber(left);
            if (n != null) unit = n;
          }
        }
      }
    }
  }

  if (name.isEmpty && qty == null && unit == null && total == null) {
    return null;
  }
  return NotesBreakdownItem(
    name: name,
    qty: qty,
    unitPrice: unit,
    totalPrice: total,
  );
}

NotesBreakdown? parseBreakdown(String? text) {
  if (text == null) return null;
  final raw = text.trimRight();
  if (raw.trim().isEmpty) return null;
  final allLines = raw.split('\n');
  // Find first non-empty line as merchant.
  var i = 0;
  while (i < allLines.length && allLines[i].trim().isEmpty) {
    i++;
  }
  if (i >= allLines.length) return null;
  final merchant = allLines[i].trim();
  // First line cannot itself be a bullet/total/note.
  if (_kBulletItem.hasMatch(allLines[i]) ||
      _kTotalLine.hasMatch(allLines[i]) ||
      _kSubtotalLine.hasMatch(allLines[i]) ||
      _kNoteLine.hasMatch(allLines[i])) {
    return null;
  }
  i++;

  final items = <NotesBreakdownItem>[];
  double? total;
  String? note;
  for (; i < allLines.length; i++) {
    final ln = allLines[i];
    if (ln.trim().isEmpty) continue;
    final noteMatch = _kNoteLine.firstMatch(ln);
    if (noteMatch != null) {
      note = noteMatch.group(1)!.trim();
      continue;
    }
    final totalMatch = _kTotalLine.firstMatch(ln);
    if (totalMatch != null) {
      total = _parseLooseNumber(totalMatch.group(1)!);
      continue;
    }
    final m = _kBulletItem.firstMatch(ln);
    if (m == null) {
      // Non-bullet, non-total, non-note line breaks the breakdown.
      return null;
    }
    final parsed = _parseItemLine(m.group(1)!);
    if (parsed == null) return null;
    items.add(parsed);
  }
  // Canonical whenever items OR a note exist (ADR-0024) — a lone
  // `merchant\nCatatan: …` is a recognizable structure.
  if (items.isEmpty && (note == null || note.isEmpty)) return null;
  return NotesBreakdown(
    merchant: merchant,
    items: items,
    total: total,
    note: note,
  );
}

bool looksLikeBreakdown(String? text) {
  if (text == null || text.trim().isEmpty) return false;
  if (parseBreakdown(text) != null) return false;
  final lines = text.split('\n');
  var bulletCount = 0;
  for (final ln in lines) {
    if (_kBulletItem.hasMatch(ln)) bulletCount++;
    if (_kTotalLine.hasMatch(ln) || _kSubtotalLine.hasMatch(ln)) return true;
  }
  if (bulletCount >= 2) return true;
  // Loose: number × number on a line, or "= number".
  for (final ln in lines) {
    if (RegExp(r'[\d.,]+\s*[x×X]\s*[\d.,]+').hasMatch(ln)) return true;
    if (RegExp(r'=\s*[\d.,]+').hasMatch(ln)) return true;
  }
  return false;
}

String breakdownTitle(String? notes) {
  if (notes == null) return '';
  final parsed = parseBreakdown(notes);
  if (parsed != null) return parsed.merchant;
  return notes.trim().split('\n').first;
}
