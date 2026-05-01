# LOIT — Design System Specification

*Split bills, not friendships.*

**Version:** 1.0.0
**Status:** Canonical
**Companion documents:** `LOIT_Product_Blueprint.md`, `LOIT_UX_Design_Requirements.md`
**Target runtime:** Flutter 3.24+ / Dart 3.8+ on iOS 15+ and Android 8+

---

## 0. About This Document

This is the **canonical design system reference** for LOIT. It specifies every primitive, token, and component that compose the app's interface. Anything rendered in LOIT must be assembled from what is defined here — no ad-hoc values, no one-off components.

The document is layered following the standard design-system taxonomy:

```
Principles     →   why
    ↓
Foundations    →   the grid, the language, the rules
    ↓
Tokens         →   the atomic values (colors, type, space, motion)
    ↓
Components     →   the parts (buttons, inputs, cards)
    ↓
Patterns       →   the compositions (forms, lists, paywalls)
    ↓
Platforms      →   iOS / Android adaptations
    ↓
Governance     →   how this document evolves
```

Use the layer you need. Designers typically live in **Foundations → Components**. Engineers live in **Tokens → Components → Flutter Implementation**. Product managers live in **Principles → Patterns**.

---

## 1. System Principles

Five rules govern the design system itself (distinct from the product UX principles):

1. **Tokens are the source of truth.** No hex values, pixel values, or duration numbers appear in component specs or Flutter code. They reference tokens.
2. **Components are closed, not clever.** A component exposes a finite set of variants and states. If a new need doesn't fit, a new component is proposed — not a new "extra" prop.
3. **One way to do a thing.** If there are two ways to show a confirmation, we pick one and retire the other. Choice inside the system is a bug.
4. **Consistency > novelty.** A component added for one screen is reusable for twenty. If it can't be reused, it doesn't belong in the system.
5. **Accessibility is a token, not a toggle.** Contrast, tap size, and focus are baked into tokens and components — you cannot assemble an inaccessible LOIT screen from these parts.

---

## 2. Token Architecture

LOIT uses a **three-tier token model** — the same pattern used by Material 3, GitHub Primer, and Atlassian Design System. This makes theming, platform adaptation, and dark mode trivial.

```
┌─────────────────────────────────────────────────┐
│  Tier 1 — PRIMITIVE                             │
│  Raw values. Never referenced by components.    │
│  Example: color.teal.700 = #0F6E5C              │
└─────────────────────────────────────────────────┘
                       ↓
┌─────────────────────────────────────────────────┐
│  Tier 2 — SEMANTIC                              │
│  Intent-based. Referenced by most components.   │
│  Example: color.action.primary.default          │
└─────────────────────────────────────────────────┘
                       ↓
┌─────────────────────────────────────────────────┐
│  Tier 3 — COMPONENT                             │
│  Scoped to a specific component.                │
│  Example: button.primary.bg                     │
└─────────────────────────────────────────────────┘
```

**Rules:**
- Components reference **Tier 2 or Tier 3** tokens — never Tier 1.
- Theming (light ↔ dark) only changes **Tier 2** token mappings. Tier 1 values are immutable.
- Adding a new primitive is a system-level change. Adding a new semantic token is a feature-level change.

---

## 3. Color System

### 3.1 Primitive Scales (Tier 1)

Each color has a 10-step scale (50 → 900). Tokens are named `color.{hue}.{step}`.

#### Neutral — warm gray, the backbone of the app

| Step | Hex | Approx use |
|---|---|---|
| `neutral.50` | `#FAFAF7` | Canvas background (light) |
| `neutral.100` | `#F3F2ED` | Muted surface |
| `neutral.200` | `#EAEAE4` | Subtle border |
| `neutral.300` | `#D4D4CE` | Separator |
| `neutral.400` | `#B0B2AC` | Disabled text, icon |
| `neutral.500` | `#9AA09E` | Tertiary text |
| `neutral.600` | `#74787A` | Secondary text |
| `neutral.700` | `#5A6160` | Body secondary |
| `neutral.800` | `#2E3230` | Dark surface |
| `neutral.900` | `#111613` | Primary text, max ink |

#### Teal — brand primary (Minahasan deep teal)

| Step | Hex |
|---|---|
| `teal.50` | `#E6F4F0` |
| `teal.100` | `#C4E4DB` |
| `teal.200` | `#96CDBE` |
| `teal.300` | `#67B5A0` |
| `teal.400` | `#3E9C82` |
| `teal.500` | `#188268` |
| `teal.600` | `#0F6E5C` ← **brand** |
| `teal.700` | `#0A5A4B` |
| `teal.800` | `#06463B` |
| `teal.900` | `#033229` |

#### Ochre — accent (warm sunset)

| Step | Hex |
|---|---|
| `ochre.50` | `#FDF5EA` |
| `ochre.100` | `#FBE7C9` |
| `ochre.200` | `#F8D29A` |
| `ochre.300` | `#F5BC6D` |
| `ochre.400` | `#F2A85C` ← **accent** |
| `ochre.500` | `#E8922F` |
| `ochre.600` | `#C77A1E` |
| `ochre.700` | `#9E5F14` |
| `ochre.800` | `#76460D` |
| `ochre.900` | `#4E2D06` |

#### Green — success (distinct from brand teal)

| Step | Hex |
|---|---|
| `green.50` | `#E8F5EC` |
| `green.400` | `#4FA678` |
| `green.500` | `#2F8F5E` ← **success** |
| `green.600` | `#227549` |
| `green.700` | `#195B38` |

#### Amber — warning

| Step | Hex |
|---|---|
| `amber.50` | `#FDF4E0` |
| `amber.400` | `#E0A93A` |
| `amber.500` | `#D49A2B` ← **warning** |
| `amber.600` | `#A87820` |
| `amber.700` | `#7D5916` |

#### Red — danger

| Step | Hex |
|---|---|
| `red.50` | `#FBEAE9` |
| `red.400` | `#D15C55` |
| `red.500` | `#C5443E` ← **danger** |
| `red.600` | `#9D332E` |
| `red.700` | `#762622` |

#### Blue — info

| Step | Hex |
|---|---|
| `blue.50` | `#E6EEF8` |
| `blue.400` | `#5A8FCE` |
| `blue.500` | `#3E7AC5` ← **info** |
| `blue.600` | `#2F5E99` |
| `blue.700` | `#22456F` |

#### Room accent palette (assigned on room creation)

Each room gets one of 8 accents for subtle identity. Never collide with semantic colors.

| Token | Hex | Name |
|---|---|---|
| `room.accent.1` | `#0F6E5C` | Teal |
| `room.accent.2` | `#F2A85C` | Ochre |
| `room.accent.3` | `#7A4FBF` | Violet |
| `room.accent.4` | `#C5443E` | Red |
| `room.accent.5` | `#3E7AC5` | Blue |
| `room.accent.6` | `#2F8F5E` | Green |
| `room.accent.7` | `#D47A9B` | Rose |
| `room.accent.8` | `#5A6160` | Graphite |

### 3.2 Semantic Tokens (Tier 2)

These are what components reference. Each resolves to a different primitive in light vs dark theme.

#### Surface & Background

| Token | Light | Dark |
|---|---|---|
| `surface.canvas` | `neutral.50` | `#101311` |
| `surface.default` | `#FFFFFF` | `#181B19` |
| `surface.raised` | `#FFFFFF` | `#1F2321` |
| `surface.overlay` | `#FFFFFF` | `#262A28` |
| `surface.muted` | `neutral.100` | `#22262483` |
| `surface.inverse` | `neutral.900` | `neutral.50` |
| `scrim` | `rgba(0,0,0,0.40)` | `rgba(0,0,0,0.60)` |

#### Content (text & iconography)

| Token | Light | Dark |
|---|---|---|
| `content.primary` | `neutral.900` | `#F2F2EC` |
| `content.secondary` | `neutral.700` | `#B8BCB6` |
| `content.tertiary` | `neutral.500` | `#8A8E88` |
| `content.disabled` | `neutral.400` | `#5A5E58` |
| `content.inverse` | `#FFFFFF` | `neutral.900` |
| `content.brand` | `teal.600` | `teal.300` |
| `content.accent` | `ochre.500` | `ochre.300` |

#### Border

| Token | Light | Dark |
|---|---|---|
| `border.subtle` | `neutral.200` | `#2E3230` |
| `border.default` | `neutral.300` | `#3A3E3C` |
| `border.strong` | `neutral.400` | `#525652` |
| `border.focus` | `teal.500` | `teal.300` |
| `border.danger` | `red.500` | `red.400` |

#### Action (interactive intent)

| Token | Light | Dark |
|---|---|---|
| `action.primary.default` | `teal.600` | `teal.500` |
| `action.primary.hover` | `teal.700` | `teal.400` |
| `action.primary.pressed` | `teal.800` | `teal.300` |
| `action.primary.disabled` | `neutral.300` | `#3A3E3C` |
| `action.secondary.default` | `surface.default` | `surface.raised` |
| `action.secondary.hover` | `neutral.100` | `#22262483` |
| `action.secondary.pressed` | `neutral.200` | `#2E3230` |
| `action.danger.default` | `red.500` | `red.400` |
| `action.danger.hover` | `red.600` | `red.500` |

#### Status

| Token | Light | Dark |
|---|---|---|
| `status.success.content` | `green.600` | `green.400` |
| `status.success.surface` | `green.50` | `#1A2E22` |
| `status.warning.content` | `amber.600` | `amber.400` |
| `status.warning.surface` | `amber.50` | `#2E2414` |
| `status.danger.content` | `red.600` | `red.400` |
| `status.danger.surface` | `red.50` | `#2E1A18` |
| `status.info.content` | `blue.600` | `blue.400` |
| `status.info.surface` | `blue.50` | `#18242E` |

### 3.3 Color Usage Rules

1. **Money amounts are always `content.primary`.** They become semantic colors (success/danger) only in budget delta and over-budget contexts.
2. **Color alone never conveys meaning.** Always pair with icon, label, or pattern (see Accessibility §10).
3. **Brand primary is a CTA color**, not a decorative color. Use it on one primary action per screen, active nav states, and brand marks. Not on random emphasis.
4. **Room accents override brand primary** inside a specific room's screens — they are that room's identity.
5. **Dark mode parity is required.** No screen ships until it is visually verified in both themes against the token mappings above.

### 3.4 Contrast Requirements

| Content type | Minimum ratio |
|---|---|
| Body text on any surface | 4.5:1 |
| Large text (≥18pt) and icons | 3:1 |
| Non-text UI (borders, focus ring) | 3:1 |
| Disabled content | No minimum (exempt) |

All Tier 2 mappings above are pre-verified to meet these on their intended surfaces.

---

## 4. Typography System

### 4.1 Typeface

**Primary typeface:** Inter (variable font, weights 400–700)
**Monospace (for code / IDs):** JetBrains Mono — used only in developer-facing surfaces (rare in product)
**Fallback stack:** `Inter, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, system-ui, sans-serif`

Inter is bundled as an app asset on both platforms. It provides excellent Bahasa Indonesia diacritic coverage, tabular numerals via `cv11`/`tnum`, and a neutral, trustworthy feel.

### 4.2 Type Scale

| Token | Size | Line-height | Weight | Tracking | Use |
|---|---|---|---|---|---|
| `type.display.l` | 48 | 52 | 600 | -0.5 | Paywall hero, first-run moments |
| `type.display.m` | 40 | 44 | 600 | -0.4 | Dashboard total amount |
| `type.display.s` | 32 | 36 | 600 | -0.3 | Secondary hero, onboarding headers |
| `type.title.l` | 24 | 30 | 600 | -0.2 | Screen titles |
| `type.title.m` | 20 | 26 | 600 | -0.15 | Section titles |
| `type.title.s` | 17 | 22 | 600 | -0.1 | Card titles, list group headers |
| `type.body.l` | 16 | 24 | 400 | 0 | Default body, button label default |
| `type.body.m` | 14 | 20 | 400 | 0 | Secondary body, metadata |
| `type.body.s` | 12 | 16 | 500 | 0.1 | Captions, chip label, tag |
| `type.label.l` | 14 | 18 | 600 | 0.2 | Form field labels |
| `type.label.m` | 12 | 16 | 600 | 0.3 | Chip filled, overline |
| `type.label.s` | 11 | 14 | 600 | 0.4 | Badge, micro-tag |

### 4.3 Numeric Typography

A dedicated treatment for amounts — the most-rendered content type in LOIT.

| Token | Size | Weight | Features |
|---|---|---|---|
| `type.amount.hero` | 40 | 600 | `tnum`, `cv11` (open digits) |
| `type.amount.large` | 24 | 600 | `tnum` |
| `type.amount.default` | 16 | 600 | `tnum` |
| `type.amount.small` | 14 | 500 | `tnum` |

**Rules:**
- All amounts use `tnum` (tabular numerals) so columns align.
- Currency symbols sit tight-adjacent to the number when symbol-style is default (`Rp85,000`, `$4.99`), and locale-formatted otherwise.
- Negative amounts: minus sign is part of the number (`-Rp12,000`), not wrapped in parentheses.
- Decimal precision: IDR default 0 decimals, USD default 2. Other currencies follow ISO 4217 minor units.

### 4.4 Typographic Rules

1. **Maximum 3 type sizes per screen.** More than that signals a hierarchy problem.
2. **Line length caps at 60 characters** for body prose (onboarding, paywall).
3. **Never use weight alone for emphasis.** Pair with color or size.
4. **Truncate with ellipsis, never wrap beyond 2 lines** in list rows. Titles ellipsize mid-word; amounts never truncate — they shrink the content beside them first.
5. **Respect OS text scaling up to 150%.** Use `MediaQuery.textScaler` in Flutter; design mocks are authored at 100%, but components are tested at 150%.

---

## 5. Space, Size, and Grid

### 5.1 Spacing Scale

Base unit: **4pt**. Every margin, padding, and gap is a multiple of the base.

| Token | Value | Typical use |
|---|---|---|
| `space.0` | 0 | Flush |
| `space.1` | 2 | Hairline adjustments |
| `space.2` | 4 | Icon-label gap, chip internal |
| `space.3` | 8 | Small stack gap, compact padding |
| `space.4` | 12 | Tight card padding, input padding vertical |
| `space.5` | 16 | **Default screen horizontal padding**, card padding |
| `space.6` | 20 | Medium section gap |
| `space.7` | 24 | Section spacing |
| `space.8` | 32 | Major section break |
| `space.9` | 40 | Hero breathing |
| `space.10` | 48 | Empty-state vertical center offset |
| `space.11` | 64 | Onboarding vertical rhythm |

### 5.2 Sizing Scale (icons, avatars, controls)

| Token | Value | Use |
|---|---|---|
| `size.icon.xs` | 14 | Inline with body.s text |
| `size.icon.s` | 16 | Inline with body.m text |
| `size.icon.m` | 20 | List row leading, inline with body.l |
| `size.icon.l` | 24 | Nav, app bar, default action icons |
| `size.icon.xl` | 32 | Illustrated accents |
| `size.avatar.xs` | 20 | Dense stacks |
| `size.avatar.s` | 28 | Presence row |
| `size.avatar.m` | 40 | List rows |
| `size.avatar.l` | 56 | Profile header |
| `size.avatar.xl` | 96 | Settings profile screen |
| `size.control.s` | 36 | Dense inputs, chip row |
| `size.control.m` | 44 | **Default control height** (meets hit-target) |
| `size.control.l` | 52 | Primary button, hero input |
| `size.hit.min` | 44 | **Minimum tappable size anywhere** |

### 5.3 Layout Grid

LOIT uses a **fluid single-column mobile layout**. No multi-column responsive grid on phone sizes.

| Breakpoint | Width | Columns | Horizontal padding |
|---|---|---|---|
| Compact phone | 320–359 | 1 | `space.4` (12) |
| Default phone | 360–479 | 1 | `space.5` (16) |
| Large phone | 480–599 | 1 | `space.5` (16) |
| Small tablet | 600–839 | 1, max content width 560 | `space.7` (24) |
| Tablet+ | 840+ | Centered 560 content | auto |

- **Safe areas:** always respected via `SafeArea`. Bottom content maintains `space.5` clearance above the home indicator or nav bar.
- **Edge-to-edge:** cards can extend to the edges on compact phones; reserve centered-content for tablet.

---

## 6. Radius & Shape

LOIT uses **soft rounded shapes** — generous but not playful.

| Token | Value | Use |
|---|---|---|
| `radius.none` | 0 | Dividers, full-bleed images |
| `radius.xs` | 4 | Tags, micro-chips |
| `radius.s` | 8 | Chips, small tags, input prefix |
| `radius.m` | 12 | Inputs, buttons |
| `radius.l` | 16 | Cards, list items |
| `radius.xl` | 24 | Bottom sheets, modals (top edges only) |
| `radius.2xl` | 32 | Large hero cards (rare) |
| `radius.full` | 999 | Avatars, circular FAB, budget bar fill |

**Corner-smoothing (squircle):** where the Flutter runtime supports it (`ContinuousRectangleBorder`), prefer continuous corners over standard round-rect for surfaces 16pt+ in radius. This matches Apple's ecosystem feel.

---

## 7. Elevation & Shadow

LOIT uses low, soft shadows — not Material's heavy spread. Most surface separation is **border-based**, not shadow-based.

| Token | Shadow | Use |
|---|---|---|
| `elevation.0` | `0 0 0` + `1px solid border.subtle` | Default cards, list rows |
| `elevation.1` | `0 1px 2px rgba(17,22,19,0.04)` | Raised cards, tab bar |
| `elevation.2` | `0 4px 12px rgba(17,22,19,0.08)` | FAB, toast |
| `elevation.3` | `0 12px 32px rgba(17,22,19,0.12)` | Bottom sheet, modal |
| `elevation.4` | `0 24px 64px rgba(17,22,19,0.16)` | Full-screen overlay |

**Dark theme** shadows are softened and tinted neutral (rgba(0,0,0) base at reduced opacity) and paired with a subtle 1px top highlight border to recreate depth without harshness.

---

## 8. Motion System

### 8.1 Duration Tokens

| Token | Duration | Curve (Flutter `Curves.*`) | Use |
|---|---|---|---|
| `motion.instant` | 80ms | `easeOut` | Press feedback, hover |
| `motion.short` | 180ms | `easeOut` | Chip toggle, small state |
| `motion.base` | 240ms | `easeInOut` | Default transition |
| `motion.emphasized` | 320ms | Custom cubic `(0.2, 0, 0, 1)` | Sheet rise, page transition |
| `motion.long` | 480ms | `easeInOut` | Celebratory (budget save, first scan) |
| `motion.loading` | Looping | `linear` | Skeleton shimmer, spinner |

### 8.2 Easing Tokens

| Token | Cubic | Use |
|---|---|---|
| `easing.standard` | `(0.4, 0, 0.2, 1)` | Default |
| `easing.emphasized` | `(0.2, 0, 0, 1)` | Emphasized enter |
| `easing.decelerate` | `(0, 0, 0.2, 1)` | Enter |
| `easing.accelerate` | `(0.4, 0, 1, 1)` | Exit |
| `easing.spring.soft` | Spring, damping 22, stiffness 180 | FAB bounce, success moments |

### 8.3 Motion Patterns

| Pattern | Definition |
|---|---|
| **Page push** | Slide-from-right + 40ms fade, `motion.emphasized` |
| **Sheet rise** | Translate-Y from `+100%`, `motion.emphasized` + scrim fade |
| **Modal present** | Scale from 0.92 + fade, `motion.emphasized` |
| **List insert** | Slide-down + fade, `motion.base` |
| **List remove** | Fade + collapse height, `motion.short` |
| **Number tween** | `TweenAnimationBuilder`, `motion.base`, `easing.decelerate` |
| **Budget bar fill** | Animate width, `motion.emphasized`, with optional overshoot |
| **Skeleton shimmer** | 1400ms linear loop, gradient sweep at 30% width |
| **Press feedback** | Scale 0.97 + opacity 0.92, `motion.instant`, reverse on release |
| **Success moment** | Spring scale 0.8→1.05→1.0 on check icon, `easing.spring.soft` |

### 8.4 Motion Rules

1. **Every motion has a purpose:** orientation, continuity, feedback, or celebration. Nothing is decorative.
2. **Respect `reduce-motion`.** When enabled, all non-essential animation becomes instant transitions (0ms) or cross-fades only.
3. **No motion for content the user hasn't asked for.** Auto-playing animations are forbidden.
4. **Optimistic UI beats spinners.** Animate the result, then reconcile on server response.
5. **Consistent direction:** "forward" always slides left-to-right on pop; sheets always rise from the bottom.

---

## 9. Iconography

### 9.1 Icon Set

**Primary:** Lucide (stroke-based, 1.5px, consistent geometry).
**Category/domain icons:** a small custom set for LOIT-specific concepts (receipt, split, room, QR-invite) drawn to match Lucide's stroke weight.

**Rules:**
- Never mix icon sets. A Lucide arrow and a Material arrow on the same screen is a bug.
- Icons are monochrome and inherit `content.*` tokens.
- Do not tint icons decoratively. Status icons use status tokens; brand icons use brand token; the rest inherit text color.

### 9.2 Icon Sizing

| Context | Size token |
|---|---|
| Inline with body.s | `size.icon.xs` (14) |
| Inline with body.m | `size.icon.s` (16) |
| List row leading | `size.icon.m` (20) |
| App bar, nav, default actions | `size.icon.l` (24) |
| Hero/accent | `size.icon.xl` (32) |

### 9.3 Category Icon Taxonomy

Each transaction category has one assigned icon + tint. Tints are derived from category role, not arbitrary:

| Category | Icon | Tint token |
|---|---|---|
| Dining | `utensils` | `ochre.400` |
| Groceries | `shopping-basket` | `green.500` |
| Transport | `car` | `blue.500` |
| Shopping | `shopping-bag` | `#B15FC0` (purple) |
| Entertainment | `ticket` | `#E06B8A` (rose) |
| Utilities | `plug` | `neutral.700` |
| Health | `heart-pulse` | `red.500` |
| Travel | `plane` | `teal.500` |
| Other | `more-horizontal` | `neutral.500` |

Tints are rendered at **12% opacity on the icon background** and **full saturation on the icon glyph**. This keeps list rows visually ordered without being loud.

---

## 10. Imagery & Illustration

### 10.1 Principles

- **No stock photography.**
- **No 3D renders, no gradients, no faux skeuomorphism.**
- Illustrations are flat, geometric, and use a restricted palette: brand primary + brand accent + one neutral.
- Illustrations are cropped to square or 4:3 and sized at `120×120` (compact empty state) or `200×200` (onboarding).

### 10.2 User Avatars

- Always circular (`radius.full`).
- If photo exists: cover-fit with a 1px `border.subtle`.
- If no photo: generated initial avatar with one of the 8 `room.accent.*` colors assigned deterministically from user ID hash. Initial is `type.label.l` weight 600, `content.inverse`.

### 10.3 Receipt Photos

- Rendered at `radius.l` with a 1px `border.subtle`.
- List thumbnails: 56×56, blur-up placeholder.
- Detail view: aspect-preserved, max-height 60% of viewport, pinch-to-zoom enabled.
- A subtle "Expires [date]" overlay appears at the bottom of the thumbnail when within 30 days of expiry.

---

## 11. Component Library

Each component is specified with: **anatomy**, **variants**, **states**, **props**, **spacing**, **accessibility**, and **do/don't** rules.

### 11.1 Button

**Anatomy:** container • (leading icon) • label • (trailing icon) • (loading spinner replaces content)

**Variants:**

| Variant | Container | Text | Border |
|---|---|---|---|
| `primary` | `action.primary.default` | `content.inverse` | none |
| `secondary` | `surface.default` | `content.brand` | 1.5px `border.strong` |
| `tertiary` | transparent | `content.brand` | none |
| `destructive` | `status.danger.surface` | `status.danger.content` | none |
| `destructive.solid` | `action.danger.default` | `content.inverse` | none |
| `ghost` | transparent | `content.primary` | none |

**Sizes:**

| Size | Height | Padding-H | Type | Icon |
|---|---|---|---|---|
| `s` | 36 | 12 | `body.m` 600 | `size.icon.s` |
| `m` | 44 | 16 | `body.l` 600 | `size.icon.m` |
| `l` | 52 | 20 | `body.l` 600 | `size.icon.l` |

**States:** default • hover (desktop only) • pressed (scale 0.97 + bg shift) • disabled (40% opacity) • loading (spinner, width locked)

**Accessibility:** `Semantics(button: true, label: ...)`. Disabled buttons have `enabled: false`. Loading buttons announce "Loading".

**Rules:**
- **One `primary` per screen.** Ever.
- Full-width default on form screens; content-width on inline actions.
- Destructive solid is reserved for irreversible confirmations inside a confirm sheet.

---

### 11.2 Icon Button

**Anatomy:** 44×44 hit area • icon centered • optional circular bg on pressed.

**Variants:** `default` (transparent) • `tonal` (`action.secondary.default` bg) • `filled` (`action.primary.default` bg, icon inverse)

**States:** default • pressed (8% overlay at full-circle) • disabled.

**Accessibility:** requires `tooltip` and `semanticLabel`. Never icon-only without a label.

---

### 11.3 Text Input

**Anatomy:** label (above) • field container • leading/trailing icons • value • hint • clear button • helper/error text (below)

**States:** default • focused (`border.focus`, 2px) • filled • disabled • error (`border.danger` + error text) • read-only

**Sizes:**

| Size | Height | Use |
|---|---|---|
| `s` | 36 | Inline with chips |
| `m` | 44 | Default |
| `l` | 52 | Onboarding, hero inputs |

**Rules:**
- Label lives above the field — no floating labels (reduces scannability and collides with locale length).
- Leading currency symbol in amount inputs is a static prefix, not part of the value.
- Error text is announced on appearance (`LiveRegion`).
- Autofill hints set appropriately (`AutofillHints.email`, `.name`, etc.).

---

### 11.4 Amount Input (specialized)

Built on Text Input with amount-specific behaviors.

- Triggers numeric keypad (`TextInputType.numberWithOptions(decimal: true)`).
- Formats on blur using locale-aware grouping (`Rp85,000` / `$85.00`).
- Currency selector as trailing dropdown-chip — tap opens currency picker sheet.
- Negative amounts disallowed in expense context — sign is implicit.

---

### 11.5 Selection Controls

| Component | Size | Spec |
|---|---|---|
| Checkbox | 20×20 | `radius.xs`, 1.5px border, `action.primary.default` fill when checked, white check |
| Radio | 20×20 | `radius.full`, 1.5px border, 10×10 inner dot when selected |
| Toggle (switch) | 48×28 | `radius.full`, track + 24×24 thumb, `action.primary.default` bg when on |
| Checkbox (disabled) | — | `content.disabled` |

All have a 44×44 invisible tap area regardless of visual size.

---

### 11.6 Chip

**Anatomy:** optional leading icon • label • optional trailing icon/dismiss

**Variants:**

| Variant | Bg | Text | Border |
|---|---|---|---|
| `default` | `surface.muted` | `content.primary` | none |
| `selected` | `action.primary.default` | `content.inverse` | none |
| `outline` | transparent | `content.primary` | 1px `border.default` |
| `input` (dismissible) | `surface.muted` | `content.primary` | none, with × icon |

**Spec:** height 32, `radius.full`, horizontal padding `space.4` (12), gap `space.2` (4) between icon and label, type `label.m`.

**Use:** filter chips, category tags, currency tags, room member pills.

---

### 11.7 Card

**Anatomy:** container • optional header (title + action) • content • optional footer

**Variants:**

| Variant | Spec |
|---|---|
| `default` | `surface.default`, `radius.l`, padding `space.5` (16), `elevation.0` (border) |
| `raised` | `elevation.1` |
| `interactive` | press feedback (scale 0.98), full-card tap target |
| `status` | leading 4px accent bar in a status color |

**Rules:**
- Maximum 1 primary action inside a card.
- Dense cards (list row variant) use `space.4` (12) padding instead of `space.5`.

---

### 11.8 List Row (Transaction Row — Canonical)

**The most-rendered component in LOIT.**

**Anatomy:**
```
┌──────────────────────────────────────────────────────────┐
│  ┌────┐                                                   │
│  │icon│  Merchant name (body.l 500)                       │
│  │    │  Category · Date (body.m content.secondary)       │
│  └────┘                                  Rp 85,000 🧾     │
│                                         (amount.default)  │
└──────────────────────────────────────────────────────────┘
```

**Spec:**
- Row height: min 64, auto-grow for wrapped content (max 2 lines on title).
- Leading icon: 40×40 circle, `radius.full`, category tint at 12% bg, full tint on glyph.
- Padding: `space.5` horizontal, `space.4` vertical.
- Trailing: amount + optional chips (receipt, room badge, AI-scanned).
- Divider: 1px `border.subtle` between rows, no divider before first row or after last.

**Interactions:**
- Tap → detail screen
- Long-press → quick menu (recategorize, edit, delete)
- Swipe-left → destructive + edit actions
- Swipe-right → (reserved, none in v1)

**States:** default • pressed (surface shift) • selected (multi-select mode: `teal.50` bg + check)

---

### 11.9 Avatar & Avatar Stack

- Single avatar: see §10.2.
- Stack: max 4 visible, remaining count as `+N` pill matching `size.avatar.s`. Spacing: -8pt overlap, 2px `surface.default` ring.

---

### 11.10 Badge & Tag

| Component | Spec | Use |
|---|---|---|
| Badge (dot) | 8×8 circle, status color | Unread indicator, presence |
| Badge (count) | min 18×18, `radius.full`, `type.label.s`, status color bg, `content.inverse` | Notification count |
| Tag | height 20, `radius.xs`, `type.label.s`, padding `space.2` horizontal | Inline metadata (AI-scanned, Pro, Archived) |

---

### 11.11 Navigation Components

#### Bottom Tab Bar

- Height 56 + bottom safe area.
- `surface.default` bg, top border `border.subtle`, `elevation.1`.
- 4 tabs: Home, Scan (center, lifted +8pt as circular FAB-style, 56×56, `action.primary.default` bg), Rooms, Settings.
- Active tab: `content.brand` icon + label. Inactive: `content.tertiary`.
- Label always visible, `type.label.s`.

#### App Bar

- Height 56 + top safe area.
- `surface.default` bg, no shadow until scrolled (then `elevation.1`).
- Leading: back or menu icon button (44×44).
- Center or leading: title `type.title.m`.
- Trailing: max 2 icon buttons.
- Large variant: 96pt height with `type.title.l` title, collapses on scroll.

#### Segmented Control

- Track: `surface.muted` bg, `radius.m`, padding `space.1` (2).
- Segments: `radius.m - 2`, equal width, `type.label.l`, selected is `surface.default` + `elevation.1`, unselected is transparent with `content.secondary` text.
- Height 36.

---

### 11.12 Sheets & Modals

#### Bottom Sheet

- `surface.overlay` bg, `radius.xl` top corners.
- Handle bar (grabber): 36×4, `border.strong`, 8pt top.
- Safe area bottom padding added.
- Scrim: `scrim` token.
- Snap points: peek (30%) and full (85%). Default opens at peek if content fits.
- Max height: `100% - 64pt` of viewport to preserve status bar visibility.
- Motion: `motion.emphasized` rise.

#### Modal (center dialog)

Reserved for **high-friction confirmations only** (delete account, sign out from all devices). All else uses bottom sheets.

- Max width 320, centered.
- `surface.overlay` bg, `radius.l`.
- Padding `space.6` (20).
- Icon optional at top (status color).
- Title `type.title.m`, body `type.body.m`.
- Actions: destructive or primary on the right, cancel on the left.

---

### 11.13 Feedback Components

#### Toast

- Position: top, below status bar, horizontal padding `space.5`.
- Max width 480.
- `surface.inverse` bg, `content.inverse` text, `radius.m`, `elevation.2`.
- Auto-dismiss: 3s. Single toast at a time.
- Motion: slide-down + fade, `motion.base`.

#### Snackbar (with action)

- Position: bottom, above tab bar, horizontal padding `space.5`.
- `surface.inverse` bg, `content.inverse` text, optional single action button `content.accent`.
- Auto-dismiss: 5s. Used for undo flows.

#### Banner (persistent)

- Full-width, horizontal padding `space.5`, vertical `space.4`.
- `status.*.surface` bg, `status.*.content` icon + text.
- Optional action as tertiary button.
- Dismissible with × icon button.

#### Alert Dialog

Same as Modal §11.12. Reserved for blocking decisions.

---

### 11.14 Progress & Loading

#### Progress Bar (budget)

- Height 8, `radius.full`.
- Track: `surface.muted`.
- Fill: semantic — `status.success.content` (<70%), `status.warning.content` (70–99%), `status.danger.content` (100%+).
- Overage renders as a darker segment extending beyond the 100% mark.
- Animated fill: `motion.emphasized`, `easing.decelerate`.

#### Circular Progress (indeterminate)

- 48×48 default, 24×24 inline.
- `action.primary.default` stroke, 3px width.
- Used for: scanning in progress, payment processing.

#### Skeleton

- `surface.muted` bg with a shimmer gradient sweeping left-to-right.
- Shapes match target content (rectangles for lines, circles for avatars).
- Used whenever structural load > 300ms.

---

### 11.15 Empty State

**Anatomy:** illustration (120×120) • title (`type.title.m`) • body (`type.body.m`, `content.secondary`) • primary CTA

**Spacing:** illustration to title `space.6`, title to body `space.3`, body to CTA `space.6`. Vertically centered with 20% offset from true center (visual center).

**Rules:**
- Every list and data view has a designed empty state. No blank screens anywhere.
- Empty state CTA is the first action a user would take to make the list non-empty.

---

### 11.16 Amount Display

A structural component for rendering money with correct formatting, sign handling, and optional delta indication.

**Anatomy:**
- Symbol (prefix) • whole number • decimal (if applicable) • currency code (optional suffix)
- Optional: delta arrow + percentage chip
- Optional: "home currency equivalent" subline

**Variants:**
| Variant | Size | Weight |
|---|---|---|
| `hero` | `type.amount.hero` | 600 |
| `large` | `type.amount.large` | 600 |
| `default` | `type.amount.default` | 600 |
| `inline` | `type.amount.small` | 500 |

**Delta chip:** `↑ 12%` or `↓ 12%`, `type.body.s`, colored semantically (up = danger in spending context, success in income; reversed in budget context).

---

## 12. Pattern Library

Patterns are pre-composed combinations of components that solve recurring UX problems.

### 12.1 Form Pattern

**Structure:**
1. App bar with screen title and Close/Back leading.
2. Scroll view of form fields, grouped by logical section with `type.label.m` overline headers.
3. Sticky footer with primary CTA (full-width, `l` size).
4. Inline validation on blur; submit-time validation on CTA tap.
5. Error summary banner if multiple errors exist.

**Keyboard:**
- Auto-advance to next field on Tab / Next.
- Dismiss on outside tap.
- Form scrolls to keep focused field visible above the keyboard + 24pt clearance.

**Dirty state:**
- Back/Close with unsaved changes → confirm sheet: "Discard changes?" with Keep editing (secondary) + Discard (destructive).

### 12.2 List + Filter Pattern

- Sticky header with horizontal-scroll filter chips (category, date, currency).
- Search icon in app bar opens a full-screen search overlay.
- List grouped by day with sticky day headers.
- Infinite scroll with skeleton placeholders.
- Pull-to-refresh.
- Empty state when filters produce no results ("No matches for this filter. Clear filters.")

### 12.3 Detail Pattern

- Large app bar with hero content (amount or title).
- Sections below as cards, each with its own title.
- Sticky footer with Edit (primary) + Delete (destructive) if applicable.
- Tap any field → inline edit or dedicated edit sheet.

### 12.4 Confirmation Pattern

For destructive or financial actions.

**Bottom sheet structure:**
1. Title `type.title.m` — plain-language statement of the action.
2. Body `type.body.m` — what will happen and what won't.
3. If irreversible: a warning banner inline.
4. Actions: Cancel (secondary, left) + Action (destructive solid or primary, right).
5. Destructive default-focuses Cancel — the user must consciously reach for the destructive side.

### 12.5 Paywall Pattern

See §10.11 of the UX Requirements document. Composed of:
- Hero + value prop
- Tier comparison (3-card or table)
- Billing toggle (Monthly / Yearly with discount badge)
- Primary CTA with dynamic price
- Legal footnote
- Dismissible via top-right text link (never an ambiguous ×)

### 12.6 Scan Pattern

Distinctive end-to-end flow — one pattern, one component choreography:

1. **Camera surface** (full-screen) with receipt guide overlay and top counter chip.
2. **Shutter tap** → capture → haptic → "Scanning…" overlay with circular progress.
3. **Review screen** (full-screen form) with pre-filled fields grouped as cards.
4. **Destination selector** (only in room context) at the bottom.
5. **Save** → success toast, return to caller.

On failure, route per decision log #4 / #14 — straight to manual entry, not retry.

### 12.7 Offline Pattern

Cross-cutting:
- Global offline banner at top of app when disconnected (`status.warning.surface`).
- Per-screen offline state for any feature that requires connection (rooms, scanner).
- Optimistic save on personal entries with a "Saved locally" affordance.
- On reconnect: transient banner "Synced. N transactions synced." + success haptic.

---

## 13. Theming

### 13.1 Light Theme

Default. Surfaces are warm white. Content is dark neutral with teal brand. See §3.2 for all mappings.

### 13.2 Dark Theme

First-class, not dimmed. Surfaces are warm dark (slight green undertone to match brand). Content is warm off-white. Shadows are softened and paired with top-highlight 1px strokes.

**Specific considerations:**
- Hero amounts stay `content.primary` (warm off-white) — never pure white.
- Status surfaces (success/warning/danger background tints) are darker and de-saturated.
- Brand teal shifts lighter (`teal.500` in dark vs `teal.600` in light) to maintain perceptual weight.
- Category tint opacity increases from 12% to 20% to remain visible on dark surfaces.

### 13.3 Theme Switching

- Settings: System (default) / Light / Dark.
- Applied instantly without app restart.
- Persisted per device.
- `MediaQuery.platformBrightness` drives System mode.

---

## 14. Accessibility Standards

### 14.1 Baseline

**WCAG 2.2 AA compliance is a ship requirement, not an enhancement.**

### 14.2 Component Requirements

Every component must:
- Expose a semantic role (`Semantics` widget in Flutter).
- Have a programmatic label (custom or derived from visible content).
- Support dynamic type up to 150% scaling without clipping or layout breakage.
- Maintain 44×44pt minimum hit target.
- Pair color with a second signal (icon, label, pattern).
- Support `reduceMotion` — substitute instant transitions for animated ones.
- Provide a visible focus indicator (`border.focus`, 2px outline, 2px offset).

### 14.3 Content Requirements

- Every image has alt text or is marked decorative.
- Every interactive element has an accessible name.
- Form fields have visible and programmatic labels (no placeholder-as-label).
- Errors are announced via `LiveRegion`.
- Amounts are read with currency and magnitude ("85 thousand rupiah" not "R-p-8-5-0-0-0").

### 14.4 Motion & Sensory

- Respect `reduceMotion` OS setting.
- Avoid color-only state signaling (see §3.3).
- Haptic feedback accompanies key state changes but is never the only signal.

---

## 15. Flutter Implementation

### 15.1 Project Structure

```
lib/core/theme/
  ├── tokens/
  │   ├── colors.dart            # Tier 1 primitives
  │   ├── semantic_colors.dart   # Tier 2 semantic
  │   ├── typography.dart        # Type scale
  │   ├── spacing.dart           # Space + size
  │   ├── radius.dart            # Radius tokens
  │   ├── elevation.dart         # Shadow definitions
  │   └── motion.dart            # Duration + curves
  ├── theme_data.dart            # ThemeData composer
  ├── loit_theme.dart            # ThemeExtension for custom tokens
  └── theme_provider.dart        # Riverpod provider for theme mode
lib/shared/widgets/
  ├── buttons/
  ├── inputs/
  ├── cards/
  ├── rows/
  ├── sheets/
  └── feedback/
```

### 15.2 Token Class Pattern

```dart
// tokens/spacing.dart
abstract final class LoitSpacing {
  static const double s0 = 0;
  static const double s1 = 2;
  static const double s2 = 4;
  static const double s3 = 8;
  static const double s4 = 12;
  static const double s5 = 16;
  static const double s6 = 20;
  static const double s7 = 24;
  static const double s8 = 32;
  static const double s9 = 40;
  static const double s10 = 48;
  static const double s11 = 64;
}
```

### 15.3 Semantic Color via ThemeExtension

Because Flutter's `ThemeData` doesn't cover LOIT's full semantic surface, custom tokens live in a `ThemeExtension`:

```dart
@immutable
class LoitColors extends ThemeExtension<LoitColors> {
  final Color surfaceCanvas;
  final Color surfaceDefault;
  final Color surfaceMuted;
  final Color contentPrimary;
  final Color contentSecondary;
  final Color actionPrimaryDefault;
  final Color statusSuccessContent;
  final Color statusDangerContent;
  // ... full token set

  const LoitColors({
    required this.surfaceCanvas,
    // ...
  });

  static const light = LoitColors(
    surfaceCanvas: Color(0xFFFAFAF7),
    // ...
  );

  static const dark = LoitColors(
    surfaceCanvas: Color(0xFF101311),
    // ...
  );

  @override
  LoitColors copyWith({...}) => LoitColors(...);

  @override
  LoitColors lerp(LoitColors? other, double t) { ... }
}

// Usage in any widget:
// final colors = Theme.of(context).extension<LoitColors>()!;
// Container(color: colors.surfaceDefault, ...)
```

### 15.4 Component Contract

Every shared widget follows this contract:

1. **Named constructor per variant** (`LoitButton.primary`, `LoitButton.secondary`) — no `variant` enum exposed.
2. **Tokens-only styling** inside — no hex colors, no raw durations.
3. **Semantic wrapper** at the root (`Semantics(...)`).
4. **Const constructor** wherever possible.
5. **Tested** with at least one golden and one behavior test.

Example:
```dart
class LoitButton extends StatelessWidget {
  const LoitButton.primary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.size = LoitButtonSize.m,
    this.loading = false,
  }) : _variant = _Variant.primary;

  const LoitButton.secondary({...}) : _variant = _Variant.secondary;
  // ... other variants

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final LoitButtonSize size;
  final bool loading;
  final _Variant _variant;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LoitColors>()!;
    // Composition via tokens only
  }
}
```

### 15.5 Motion Implementation

```dart
abstract final class LoitMotion {
  static const instant = Duration(milliseconds: 80);
  static const short = Duration(milliseconds: 180);
  static const base = Duration(milliseconds: 240);
  static const emphasized = Duration(milliseconds: 320);
  static const long = Duration(milliseconds: 480);

  static const standard = Curves.easeInOut;
  static const decelerate = Curves.easeOut;
  static const accelerate = Curves.easeIn;
  static const emphasizedCurve = Cubic(0.2, 0, 0, 1);
}
```

Always wrap animated widgets in a helper that respects `MediaQuery.disableAnimations` (reduce motion):

```dart
Duration respectReduceMotion(BuildContext context, Duration duration) {
  return MediaQuery.of(context).disableAnimations ? Duration.zero : duration;
}
```

### 15.6 Lint Rules

Custom analyzer rules enforce system use:
- No raw `Color(0x...)` outside `tokens/colors.dart`.
- No raw `Duration(milliseconds: ...)` outside `tokens/motion.dart`.
- No raw numeric padding outside `tokens/spacing.dart`.
- All `Text` widgets must specify a text style from the typography scale.

These are checked in CI. Violations fail the build.

---

## 16. Localization (Design-System Level)

### 16.1 Locale-Aware Tokens

Some tokens are locale-sensitive, not just text:

| Token | EN (en_US) | ID (id_ID) |
|---|---|---|
| Decimal separator | `.` | `,` |
| Thousand separator | `,` | `.` |
| Date long format | `Dec 12, 2026` | `12 Des 2026` |
| Date short | `12/12/2026` | `12/12/2026` |
| First day of week | Sunday | Monday |

All driven via `intl` — never hardcoded.

### 16.2 Length Tolerance

Indonesian strings run 15–25% longer than English on average. Components must accommodate:
- Buttons: 1.3× English length without wrapping; else truncation with ellipsis.
- Chips: auto-fit to content, horizontal scroll row.
- App bar titles: ellipsize mid-word if needed.
- Banners and empty states: wrap to up to 3 lines before truncating.

### 16.3 Bidirectional Readiness

LOIT v1 ships LTR only. However, all components use `EdgeInsetsDirectional` and `AlignmentDirectional` so a future RTL locale (e.g., Arabic Indonesian diaspora market) is a translation task, not a re-build.

---

## 17. Platform Adaptation Matrix

LOIT ships one visual design on both platforms. Only platform-native behavior differs where OS expectation matters.

| Concern | iOS | Android |
|---|---|---|
| Back navigation | Swipe from left edge; leading `<` button | System back; leading `←` button |
| Page transition | Slide from right | Slide from right (matched) |
| Modal presentation | Custom bottom sheet (not iOS action sheet) | Same custom sheet |
| Date picker | Wheel picker in bottom sheet | Material calendar |
| Time picker | Wheel picker | Material clock |
| Haptics | `HapticFeedback.lightImpact` / `selectionClick` / `mediumImpact` | Matched vibration |
| Permission UI | Apple HIG copy | Material copy |
| Share | `UIActivityViewController` | `Intent.ACTION_SEND` |
| Biometric prompt | Face ID / Touch ID | Fingerprint / Face unlock |
| Push permission | Requested explicitly | Android 13+ same |
| Sign-in with Apple | Required, shown | Not shown |
| Google Sign-in | Shown | Shown (primary) |
| Keyboard behavior | Auto-dismiss on outside tap | Same |
| Status bar | Matched to app bar surface | Same |
| Navigation bar (Android) | n/a | Match app bar surface, edge-to-edge when possible |
| App icon | Squircle, iOS template | Adaptive icon (foreground + background) |

Everything not on this list — colors, typography, spacing, component visuals, motion — is identical.

---

## 18. Content & Voice Tokens

Voice is part of the system. These are the content-side tokens.

### 18.1 Voice Principles

- **Warm, direct, competent.** Never cute, never cold.
- **Human numbers.** "Rp85,000" not "85,000.00 IDR".
- **Active verbs.** "Save", not "Click here to save".
- **Second-person you.** "Your spending" not "User spending".

### 18.2 Copy Patterns

| Scenario | Pattern | Example |
|---|---|---|
| Success | One or two words | "Saved." / "Done." / "Welcome to Pro." |
| Inline error | Cause + fix | "Amount must be positive." |
| Destructive confirm | What + irreversibility | "Delete transaction? This can't be undone." |
| Empty state | Invitation + action | "No expenses yet. Snap your first receipt." |
| Offline | Status + reassurance | "You're offline. Personal tracking still works." |
| Paywall | Value-first headline | "Unlimited budgets. Unlimited currencies. Pro." |

### 18.3 Forbidden Copy Patterns

- No "Oops!", "Uh oh!", "Whoops!".
- No exclamation points on destructive or error copy.
- No emoji in error or system messages.
- No "please" in instructions — it implies supplication.
- No question marks on success messages.
- No "Congratulations!" — say what the user achieved instead.

### 18.4 Numeric Copy Rules

- Currency formatting: always locale-aware via `intl`.
- Large numbers (reports only): abbreviate with thin spaces — "Rp1.2jt" (Indonesian) / "$1.2K" (English).
- Percentages: no decimal places unless < 1% ("12%" not "12.0%").
- Time: relative for recent ("2 min ago", "Yesterday", "Mon 12 Dec"), absolute for > 1 week.

---

## 19. Governance

### 19.1 Versioning

The design system follows semantic versioning:

- **Major (x.0.0)** — breaking token or component API changes.
- **Minor (1.x.0)** — new tokens, new components, backward-compatible variant additions.
- **Patch (1.0.x)** — value adjustments, bug fixes.

This document is the source of truth. Code in `lib/core/theme/` must match this document at its declared version.

### 19.2 Change Process

To add or modify a token or component:

1. **Propose** — open a design proposal outlining the need and the proposed addition.
2. **Review** — design + engineering confirm the addition can't be achieved with existing tokens/components.
3. **Document first** — update this specification before writing code.
4. **Implement** — add the token/component in the `lib/core/theme/` or `lib/shared/widgets/` layer.
5. **Migrate** — audit existing components for opportunities to adopt the new primitive.
6. **Release** — bump the version per §19.1.

### 19.3 Contribution Rules

- Components added by feature teams for one-off use are **not part of the system** until they pass the review process.
- Deviations from tokens ("just this once this color") are forbidden. Extend the system instead.
- Deprecations are marked `@Deprecated` in code with a migration note and removed one major version later.

### 19.4 Review Cadence

- Monthly audit for unused tokens and underused components.
- Quarterly accessibility pass.
- Every major release includes a full dark-mode visual QA.

---

## 20. Summary Token Reference

A condensed lookup table of the most-used tokens.

### Colors (semantic, light)
```
surface.canvas        #FAFAF7
surface.default       #FFFFFF
surface.muted         #F3F2ED
content.primary       #111613
content.secondary     #5A6160
content.brand         #0F6E5C
action.primary.*      #0F6E5C → #0A5A4B → #06463B
border.subtle         #EAEAE4
status.success        #2F8F5E
status.warning        #D49A2B
status.danger         #C5443E
```

### Type
```
display.m             40/44  600
title.l               24/30  600
title.m               20/26  600
body.l                16/24  400
body.m                14/20  400
body.s                12/16  500
amount.hero           40     600 tnum
amount.default        16     600 tnum
```

### Space
```
s2 = 4   s3 = 8   s4 = 12   s5 = 16   s6 = 20   s7 = 24   s8 = 32
```

### Radius
```
s = 8   m = 12   l = 16   xl = 24   full = 999
```

### Motion
```
instant    80ms   easeOut
short     180ms   easeOut
base      240ms   easeInOut
emphasized 320ms  cubic(0.2, 0, 0, 1)
```

### Size
```
hit.min         44
icon.l          24
avatar.m        40
control.m       44
control.l       52
```

---

## 21. Acceptance Checklist — "Does this ship with LOIT?"

Before any new screen or component is merged:

- [ ] Uses only tokens from this document (no raw hex, pixel, or duration values)
- [ ] Renders correctly in light and dark themes
- [ ] Renders correctly in English and Bahasa Indonesia at max string length
- [ ] All five states designed: empty, loading, error-recoverable, error-blocking, success
- [ ] Motion spec defined and reduce-motion respected
- [ ] Accessibility: semantic labels, 44pt hit targets, contrast verified
- [ ] Offline behavior defined
- [ ] Haptic feedback assigned where appropriate
- [ ] Reviewed against system principles (§1)
- [ ] Does not introduce a new variant of an existing component without proposal

---

*LOIT Design System — Split bills, not friendships.*
*Canonical spec. Version 1.0.0.*
