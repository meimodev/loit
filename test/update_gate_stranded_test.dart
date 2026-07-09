import 'package:flutter_test/flutter_test.dart';
import 'package:loit/shared/providers/update_gate_provider.dart';

/// Pure-resolver checks for the Update state machine (ADR-0015, ADR-0030).
/// The Play remedy oracle is the `remedyAvailable` parameter — no Play IPC here.
void main() {
  const gate = UpdateGate(
    minVersion: '1.2.0',
    recommendedVersion: '1.3.0',
    latestVersion: '1.4.0',
    storeUrl: 'https://example.test',
  );

  group('below the floor', () {
    test('remedy available => Blocked', () {
      expect(
        gate.stateFor('1.1.9', remedyAvailable: true),
        UpdateState.blocked,
      );
    });

    test('no remedy => Stranded, not Blocked', () {
      expect(
        gate.stateFor('1.1.9', remedyAvailable: false),
        UpdateState.stranded,
      );
    });
  });

  group('at or above the floor, remedy is irrelevant', () {
    for (final remedy in [true, false]) {
      test('min <= v < recommended => Recommended (remedy=$remedy)', () {
        expect(
          gate.stateFor('1.2.0', remedyAvailable: remedy),
          UpdateState.recommended,
        );
      });

      test('recommended <= v < latest => Optional (remedy=$remedy)', () {
        expect(
          gate.stateFor('1.3.5', remedyAvailable: remedy),
          UpdateState.optional,
        );
      });

      test('v >= latest => Current (remedy=$remedy)', () {
        expect(
          gate.stateFor('1.4.0', remedyAvailable: remedy),
          UpdateState.current,
        );
      });
    }
  });

  test('numeric segment ordering: 1.0.9 < 1.0.10', () {
    const g = UpdateGate(
      minVersion: '1.0.10',
      recommendedVersion: '1.0.10',
      latestVersion: '1.0.10',
      storeUrl: 'https://example.test',
    );
    expect(g.stateFor('1.0.9', remedyAvailable: true), UpdateState.blocked);
    expect(g.stateFor('1.0.10', remedyAvailable: false), UpdateState.current);
  });

  test('build/pre-release suffixes are stripped before comparison', () {
    expect(
      gate.stateFor('1.2.0-breaking+42', remedyAvailable: false),
      UpdateState.recommended,
    );
  });

  test('isBelowFloor is the sole trigger for the Play remedy query', () {
    expect(gate.isBelowFloor('1.1.9'), isTrue);
    expect(gate.isBelowFloor('1.2.0'), isFalse);
  });
}
