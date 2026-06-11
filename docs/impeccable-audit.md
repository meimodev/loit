# Impeccable Audit — LOIT (product register)

_Code-level technical audit. Scope: `lib/core/theme/`, `lib/shared/widgets/`, `lib/features/`. No PRODUCT.md/DESIGN.md present; run `/impeccable teach` for sharper context._

## Audit Health Score

| # | Dimension | Score | Key Finding |
|---|-----------|-------|-------------|
| 1 | Accessibility | 2/4 | `Semantics` in only 2 files; 41 files use raw `GestureDetector`/`InkWell`; `LoitButton.s` = 36px touch target |
| 2 | Performance | 3/4 | Clean. Instant-duration animations, tabular nums, no layout-property animation or thrash |
| 3 | Responsive Design | 3/4 | Overflow handled (ellipsis/softWrap); no text-scale clamp; size.s buttons sub-44px |
| 4 | Theming | 3/4 | Strong `ThemeExtension` token system + full dark mode; ~9 files re-type palette hex |
| 5 | Anti-Patterns | 3/4 | No glass/gradient-text/bounce. One side-stripe ban match in `LoitTxRow` |
| **Total** | | **14/20** | **Good — address weak dimensions** |

## Anti-Patterns Verdict

**PASS — does not look AI-generated.** Distinctive teal/ochre palette, tinted neutrals (no pure `#000`/`#fff`), proper ease-out curves, real component state machines. No glassmorphism, no gradient text (`ShaderMask` count = 0), no bounce/elastic, no hero-metric template, no identical card grids. Gradients exist only in paywall/scanner success moments (legitimate). One ban tell:

- **Side-stripe** — `LoitTxRow.accentStripeColor` paints a 3px vertical bar on the leading edge (loit_tx_row.dart:173-188). Matches the absolute ban. It also duplicates the existing `roomBadge` signal.

## Executive Summary

- Health Score: **14/20 (Good)**
- Issues: P0 ×0 · P1 ×1 · P2 ×3 · P3 ×2
- Top issues:
  1. [P1] Touch targets below 44px (`LoitButton.s`)
  2. [P2] Custom tappables lack `Semantics` labels (systemic)
  3. [P2] Side-stripe accent in `LoitTxRow` (ban + redundant with room badge)
  4. [P2] Palette hex re-typed outside theme layer (~9 files)
  5. [P3] No `textScaler` clamp on dense rows

## Detailed Findings by Severity

### [P1] Sub-44px touch targets
- **Location**: `lib/shared/widgets/loit_button.dart:96-100` (`LoitButtonSize.s` = 36px height)
- **Category**: Accessibility / Responsive
- **Impact**: 36px tap targets miss users with motor impairment; mis-taps on small/dense buttons.
- **Standard**: WCAG 2.5.5 (AAA 44px), Material min 48px.
- **Recommendation**: Wrap interactive content in 44px min hit area (transparent padding) while keeping 36px visual height, or raise size.s to 40 + expand hit test.
- **Command**: `/impeccable adapt`

### [P2] Custom tappables without Semantics
- **Location**: 41 files use `GestureDetector`/`InkWell`; only 2 files contain `Semantics(`. `LoitButton` is correctly wrapped; most ad-hoc tap rows are not.
- **Category**: Accessibility
- **Impact**: TalkBack announces unlabeled/role-less controls; some tap zones invisible to screen readers.
- **Recommendation**: Audit raw `GestureDetector` taps; add `Semantics(button:true, label:...)` or prefer `LoitIconButton`/`LoitButton`. `LoitTxRow`'s `InkWell` gives a tap role but no consolidated label.
- **Command**: `/impeccable harden`

### [P2] Side-stripe accent (ban) in LoitTxRow
- **Location**: `lib/shared/widgets/loit_tx_row.dart:173-188`
- **Category**: Anti-Pattern
- **Impact**: 3px colored edge stripe is the banned side-stripe; redundant with `roomBadge` already shown in the row.
- **Recommendation**: Drop the stripe; rely on `roomBadge`, or replace with a tinted avatar ring / leading icon if a second cue is needed.
- **Command**: `/impeccable distill`

### [P2] Palette hex re-typed outside theme
- **Location**: e.g. `reports_screen.dart:511,825` (`0xFFD49A2B`=amber500, `0xFFE6F4F0`=teal50), `transaction_form_screen.dart:1220` (`0xFF2F8F5E`=green500), `notifications_screen.dart:199` (`0xFF7A4FBF`=room3), `settings/_widgets.dart:326`. ~9 feature files.
- **Category**: Theming
- **Impact**: Hard-coded literals bypass `LoitColors`/`LoitPalette`; break in dark mode (e.g. fixed teal50 surface stays light) and drift from tokens.
- **Recommendation**: Replace literals with `context.loitColors.*` or `LoitPalette.*`. The hex values already exist as named tokens.
- **Command**: `/impeccable normalize`

### [P3] No text-scale clamp on dense content
- **Location**: row/amount styles use fixed `height` ratios; no `MediaQuery.textScaler` handling found.
- **Category**: Responsive / A11y
- **Impact**: At 1.5–2× system font, `LoitTxRow` amount column and 36px buttons risk clipping.
- **Recommendation**: Verify at max font scale; allow amount to wrap or cap scale on fixed-height controls.
- **Command**: `/impeccable adapt`

### [P3] Decorative gradients
- **Location**: `pro_success_screen.dart:27,47`, `scanner_screen.dart:1078`, paywall.
- **Category**: Anti-Pattern (borderline)
- **Impact**: None — these are success/celebration moments where Committed color is allowed. Keep contained to these surfaces; do not spread to task screens.

## Patterns & Systemic Issues

- **A11y is the weak axis**: semantics coverage is thin relative to custom-tap usage (2 vs 41 files). Systemic, not one-off.
- **Token discipline ~90%**: theme layer is exemplary, but a handful of feature screens re-type palette hex instead of importing tokens. Tighten lint to flag `Color(0x` outside `core/theme/`.

## Positive Findings

- Excellent `ThemeExtension` semantic token system with full light + dark + `lerp` (`loit_colors.dart`).
- Tinted neutrals, no pure black/white — passes color hygiene.
- `LoitButton` is a complete state machine: default/pressed/disabled/loading + `Semantics`.
- Motion tokens are correct ease-out cubics (quart/quint/expo); no banned easing.
- Tabular figures on all amounts; consistent 8pt spacing scale.

## Recommended Actions (priority order)

1. **[P1] `/impeccable adapt`** — raise size.s hit area to 44px; verify max text-scale.
2. **[P2] `/impeccable harden`** — add `Semantics` to raw `GestureDetector` tappables.
3. **[P2] `/impeccable distill`** — remove `LoitTxRow` side-stripe (redundant with room badge).
4. **[P2] `/impeccable normalize`** — replace re-typed palette hex with tokens in ~9 files.
5. **[P3] `/impeccable polish`** — final pass after fixes.
