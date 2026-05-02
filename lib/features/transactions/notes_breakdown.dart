import 'package:intl/intl.dart';

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
  });

  final String merchant;
  final List<NotesBreakdownItem> items;
  final double? total;
}

final NumberFormat _kThousand = NumberFormat('#,##0.##', 'id_ID');

String _fmtNum(double v) => _kThousand.format(v);

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

String formatBreakdown(NotesBreakdown b) {
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
      right.add('${_fmtNum(it.qty!)} × ${_fmtNum(it.unitPrice!)}');
    } else if (hasQty) {
      right.add('${_fmtNum(it.qty!)} ×');
    } else if (hasUnit) {
      right.add('× ${_fmtNum(it.unitPrice!)}');
    }
    if (hasTotal) {
      right.add('= ${_fmtNum(it.totalPrice!)}');
    }
    if (right.isNotEmpty) {
      buf.write(name.isEmpty ? '' : ' : ');
      buf.write(right.join(' '));
    }
    lines.add(buf.toString());
  }
  if (b.total != null) lines.add('Total: ${_fmtNum(b.total!)}');
  return lines.join('\n');
}

final RegExp _kBulletItem = RegExp(r'^\s*[-•*]\s+(.*)$');
final RegExp _kTotalLine = RegExp(r'^\s*Total\s*:\s*(.+)$', caseSensitive: false);
final RegExp _kSubtotalLine =
    RegExp(r'^\s*Subtotal\s*:\s*(.+)$', caseSensitive: false);

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
  // First line cannot itself be a bullet/total.
  if (_kBulletItem.hasMatch(allLines[i]) ||
      _kTotalLine.hasMatch(allLines[i]) ||
      _kSubtotalLine.hasMatch(allLines[i])) {
    return null;
  }
  i++;

  final items = <NotesBreakdownItem>[];
  double? total;
  for (; i < allLines.length; i++) {
    final ln = allLines[i];
    if (ln.trim().isEmpty) continue;
    final totalMatch = _kTotalLine.firstMatch(ln);
    if (totalMatch != null) {
      total = _parseLooseNumber(totalMatch.group(1)!);
      continue;
    }
    final m = _kBulletItem.firstMatch(ln);
    if (m == null) {
      // Non-bullet, non-total line breaks the breakdown.
      return null;
    }
    final parsed = _parseItemLine(m.group(1)!);
    if (parsed == null) return null;
    items.add(parsed);
  }
  if (items.isEmpty) return null;
  return NotesBreakdown(merchant: merchant, items: items, total: total);
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
