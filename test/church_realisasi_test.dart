import 'package:flutter_test/flutter_test.dart';
import 'package:loit/features/rooms/church/church_realisasi_service.dart';
import 'package:loit/features/rooms/church/mata_anggaran.dart';

void main() {
  group('subtreeTotals outline rollup', () {
    // group(0)
    //   line(1)
    //     leaf a(2)
    //     leaf b(2)
    //   line2(1)   <- has its own direct amount, no children
    // group2(0)    <- empty
    const tree = [
      MataAnggaran('1.0.00.00', 'GROUP', 0),
      MataAnggaran('1.3.50.00', 'LINE', 1),
      MataAnggaran('1.3.50.01', 'a', 2),
      MataAnggaran('1.3.50.02', 'b', 2),
      MataAnggaran('1.3.51.00', 'LINE2', 1),
      MataAnggaran('2.0.00.00', 'GROUP2', 0),
    ];

    test('parents sum their descendants; a line keeps its own direct amount', () {
      final direct = {
        '1.3.50.01': 100.0,
        '1.3.50.02': 50.0,
        '1.3.51.00': 30.0, // booked directly on a parent line (leaf-unknown)
      };
      final t = subtreeTotals(tree, direct);
      expect(t[0], 180); // group = 100 + 50 + 30
      expect(t[1], 150); // line = 100 + 50
      expect(t[2], 100); // leaf a
      expect(t[3], 50); // leaf b
      expect(t[4], 30); // line2 own direct
      expect(t[5], 0); // empty group
    });

    test('money is conserved: depth-0 subtrees sum to total direct', () {
      // A spread of real GMIM income codes at different depths.
      final direct = {
        '1.3.50.01': 200.0, // leaf under KOINONIA
        '1.3.51.00': 75.0, // a line under KOINONIA
        '2.3.50.01': 40.0, // leaf under MARTURIA
        '5.3.90.00': 10.0, // a line under PENDAPATAN LAINNYA
      };
      final t = subtreeTotals(gmimIncome, direct);
      final rootTotal = [
        for (var i = 0; i < gmimIncome.length; i++)
          if (gmimIncome[i].depth == 0) t[i]
      ].fold<double>(0, (s, v) => s + v);
      final directTotal = direct.values.fold<double>(0, (s, v) => s + v);
      expect(rootTotal, directTotal); // 325, no double-count, no loss
    });
  });
}
