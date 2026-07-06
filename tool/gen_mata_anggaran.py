#!/usr/bin/env python3
"""Generate mata_anggaran.dart from docs/gmim_mata_anggaran.md.

Depth is the &nbsp; indent count / 3 (top bold group = 0). Name is stripped of
nbsp + ** bold markers. Two sections: Pendapatan -> income, Pengeluaran -> expense.
"""
import re, sys

SRC = "/Users/edotanod/IdeaProjects/loit/docs/gmim_mata_anggaran.md"
OUT = "/Users/edotanod/IdeaProjects/loit/lib/features/rooms/church/mata_anggaran.dart"

def parse(lines):
    rows = []
    for ln in lines:
        m = re.match(r"^\|\s*\d+\s*\|\s*([0-9.]+)\s*\|(.*)\|\s*$", ln)
        if not m:
            continue
        kode = m.group(1).strip()
        raw = m.group(2)
        depth = raw.count("&nbsp;") // 3
        name = raw.replace("&nbsp;", "").replace("**", "").strip()
        rows.append((kode, name, depth))
    return rows

def esc(s):
    return s.replace("\\", "\\\\").replace("'", "\\'")

def main():
    text = open(SRC, encoding="utf-8").read()
    # split on the two section headers
    inc_split = text.split("## Pendapatan (Income)")[1]
    inc_part, exp_part = inc_split.split("## Pengeluaran (Expense)")
    income = parse(inc_part.splitlines())
    expense = parse(exp_part.splitlines())

    def emit(rows):
        out = []
        for kode, name, depth in rows:
            out.append(f"  MataAnggaran('{kode}', '{esc(name)}', {depth}),")
        return "\n".join(out)

    dart = f"""// GENERATED from docs/gmim_mata_anggaran.md — do not edit by hand.
// Regenerate: python3 tool/gen_mata_anggaran.py (see that script).
//
// GMIM's fixed chart of budget-line codes (Mata Anggaran). A report-time
// projection target only — NOT a room's working categories (ADR 0026). A
// Church room keeps its universal chart (church_presets.dart) for entry;
// `Laporan Realisasi Mata Anggaran` re-maps its transactions onto these codes.
//
// [depth] is the outline indent (0 = top group `X.0.00.00`), used both to
// render the tree and to roll subtotals up to parent lines. Income and expense
// are separate trees; a transaction maps only within its own `kind`.

class MataAnggaran {{
  final String kode;
  final String name;
  final int depth;
  const MataAnggaran(this.kode, this.name, this.depth);
}}

/// Pendapatan / Penerimaan tree — {len(income)} codes.
const List<MataAnggaran> gmimIncome = [
{emit(income)}
];

/// Pengeluaran tree — {len(expense)} codes.
const List<MataAnggaran> gmimExpense = [
{emit(expense)}
];
"""
    open(OUT, "w", encoding="utf-8").write(dart)
    print(f"wrote {OUT}: {len(income)} income, {len(expense)} expense")

if __name__ == "__main__":
    main()
