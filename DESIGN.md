---
name: LOIT
description: Indonesian personal-finance app where capture is the hot path. Fresh mint on warm cream, border-first, calm under the warmth.
colors:
  trusted-money-green: "#1FA871"
  mint-bright: "#34E89E"
  mint-dark-brand: "#2BC487"
  ochre-accent: "#E8922F"
  ochre-accent-dark: "#F5BC6D"
  canvas-cream: "#FAFAF7"
  surface-white: "#FFFFFF"
  muted-stone: "#F3F2ED"
  border-stone: "#D4D4CE"
  ink: "#111613"
  ink-secondary: "#5A6160"
  ink-tertiary: "#9AA09E"
  petrol-canvas: "#0D2E33"
  petrol-surface: "#123A40"
  petrol-raised: "#16454C"
  success-green: "#2F8F5E"
  warning-amber: "#D49A2B"
  danger-red: "#C5443E"
  info-blue: "#3E7AC5"
typography:
  display:
    fontFamily: "Inter, system-ui, sans-serif"
    fontSize: "40px"
    fontWeight: 600
    lineHeight: 1.1
    letterSpacing: "-0.5px"
  headline:
    fontFamily: "Inter, system-ui, sans-serif"
    fontSize: "24px"
    fontWeight: 600
    lineHeight: 1.25
    letterSpacing: "-0.2px"
  title:
    fontFamily: "Inter, system-ui, sans-serif"
    fontSize: "20px"
    fontWeight: 600
    lineHeight: 1.3
    letterSpacing: "-0.1px"
  body:
    fontFamily: "Inter, system-ui, sans-serif"
    fontSize: "16px"
    fontWeight: 400
    lineHeight: 1.5
    letterSpacing: "normal"
  label:
    fontFamily: "Inter, system-ui, sans-serif"
    fontSize: "12px"
    fontWeight: 600
    lineHeight: 1.33
    letterSpacing: "0.2px"
  amount:
    fontFamily: "Inter, system-ui, sans-serif"
    fontSize: "40px"
    fontWeight: 600
    lineHeight: 1.2
    letterSpacing: "-0.4px"
    fontFeature: "tnum"
rounded:
  xs: "4px"
  sm: "8px"
  md: "12px"
  lg: "16px"
  xl: "24px"
  full: "999px"
spacing:
  xs: "4px"
  sm: "8px"
  md: "16px"
  lg: "24px"
  xl: "32px"
components:
  button-primary:
    backgroundColor: "{colors.trusted-money-green}"
    textColor: "{colors.surface-white}"
    typography: "{typography.body}"
    rounded: "{rounded.md}"
    padding: "0 12px"
    height: "44px"
  button-secondary:
    backgroundColor: "{colors.surface-white}"
    textColor: "{colors.trusted-money-green}"
    typography: "{typography.body}"
    rounded: "{rounded.md}"
    padding: "0 12px"
    height: "44px"
  button-destructive:
    backgroundColor: "#FBEAE9"
    textColor: "{colors.danger-red}"
    typography: "{typography.body}"
    rounded: "{rounded.md}"
    padding: "0 12px"
    height: "44px"
  input:
    backgroundColor: "{colors.surface-white}"
    textColor: "{colors.ink}"
    typography: "{typography.body}"
    rounded: "{rounded.md}"
    padding: "12px 14px"
    height: "44px"
  chip-default:
    backgroundColor: "{colors.muted-stone}"
    textColor: "{colors.ink}"
    typography: "{typography.label}"
    rounded: "{rounded.full}"
    padding: "0 12px"
    height: "32px"
  chip-selected:
    backgroundColor: "{colors.trusted-money-green}"
    textColor: "{colors.surface-white}"
    typography: "{typography.label}"
    rounded: "{rounded.full}"
    padding: "0 12px"
    height: "32px"
---

# Design System: LOIT

## 1. Overview

**Creative North Star: "Fresh Mint Field"**

LOIT looks like spring green growing on warm light ground. Vivid mint ink, the
color of the wordmark, sits on a near-white cream canvas tinted faintly green,
never pure `#fff`, never pure `#000`. The feeling is alive and hopeful: money
that breathes, not money that weighs. This is a money smart friend, not a bank.
The system is warm, lively, and unmistakably local, in Bahasa Indonesia first.

Density is calm. Logging a transaction is the act users repeat most, so the
common case is uncluttered and one-handed: a few legible numbers, generous
breathing room, the next tap obvious. Surfaces are flat and paper-like, drawn
by hair-thin borders, not boxed in shadow. Color is restrained on purpose. The
mint accent earns attention precisely because it is rare; status colors speak
only when something needs a human decision.

This system explicitly rejects three things. It is not **cold corporate
banking**: no navy-and-gold, no dense forms, no teller-window intimidation. It
is not **crypto or fintech hype**: no neon-on-black, no aggressive gradients,
no gamified greed, no fake urgency. And it is not a **cluttered spreadsheet
dashboard**: no walls of tiny numbers, no chart overload, no everything-on-one-
screen. Lively does not mean loud. It is real money, kept calmly.

**Key Characteristics:**
- Fresh mint brand on warm tinted-cream (light) and desaturated petrol (dark)
- Border-first surfaces; shadows soft, low, and reserved
- Inter throughout, with tabular figures for every amount
- Restrained accent: mint and ochre appear rarely and mean something
- Calm density: optimize the capture hot path, push everything else back

## 2. Colors

A warm, optimistic palette: one fresh green carries the brand, one ochre warms
it, everything else is a green-tinted neutral. Status colors are muted, never
fluorescent.

### Primary
- **Trusted Money Green** (light `#1FA871`, dark `#34E89E`): the logo green and
  the single brand voice. Primary buttons, selected chips, focus borders,
  active nav, the income-positive direction. In dark mode it brightens to the
  vivid wordmark mint (`#34E89E`) so it pops on petrol. Steady, reassuring,
  growth, never garish.
- **Mint Bright** (`#34E89E`) / **Mint Dark-Brand** (`#2BC487`): highlight and
  pressed/hover steps of the same green. Used for state, not as a second color.

### Secondary
- **Ochre Accent** (light `#E8922F`, dark `#F5BC6D`): the warm counterpoint.
  Sparingly, for highlights, badges, the occasional emphasis the green should
  not carry. A pinch of warmth, never a second brand.

### Neutral
- **Canvas Cream** (`#FAFAF7`): app background in light mode. White warmed and
  tinted faintly toward the brand hue. The "paper" of the ledger.
- **Surface White** (`#FFFFFF`): raised cards, inputs, sheets in light mode.
- **Muted Stone** (`#F3F2ED`): quiet fills, default chips, inert backgrounds.
- **Border Stone** (`#D4D4CE`): the default 1px hairline that defines surfaces.
- **Ink** (`#111613`): primary text. A green-black, never `#000`.
- **Ink Secondary** (`#5A6160`) / **Ink Tertiary** (`#9AA09E`): supporting and
  hint text.
- **Petrol Canvas / Surface / Raised** (`#0D2E33` / `#123A40` / `#16454C`):
  the dark-mode ground. Desaturated petrol retoned from the logo background, so
  dark mode stays on-brand instead of going generic slate-gray.

### Status (muted, decision-prompting)
- **Success Green** (`#2F8F5E`), **Warning Amber** (`#D49A2B`), **Danger Red**
  (`#C5443E`), **Info Blue** (`#3E7AC5`): each with a faint tinted surface
  (`successSurface`, etc.) for backgrounds. Distinct from the brand green so
  "this succeeded" never reads as "this is the brand."

### Room Palette
Eight distinct hues (`#0F6E5C` teal, `#F2A85C` ochre, `#7A4FBF` violet,
`#C5443E` red, `#3E7AC5` blue, `#2F8F5E` green, `#D47A9B` rose, `#5A6160`
stone) assign one stable color per shared room, so members recognize a room at
a glance. Decorative identity only, never status.

### Named Rules
**The One Voice Rule.** Mint is the only brand color. On any given screen the
mint accent covers well under 10% of the surface. Its rarity is what makes a
primary button or a selected chip read instantly. Never tint whole panels mint.

**The No Pure Black/White Rule.** Backgrounds are tinted cream or petrol; text
is green-black `#111613`. Pure `#000` and `#fff` are forbidden; they look cold,
which is the one thing LOIT must never be.

## 3. Typography

**Display / Body / Label Font:** Inter (with `system-ui, sans-serif` fallback)

**Character:** One humanist sans does all the work: friendly enough to feel
local, neutral enough to disappear behind the numbers. The signature move is
**tabular figures (`tnum`) on every amount**, so digits align in columns and
money never jitters as it changes.

### Hierarchy
- **Display** (600, 40px / 44px, `-0.5` tracking): the one big number or screen
  headline. Used once per screen, at most.
- **Headline** (600, 24px / 30px, `-0.2`): section and screen titles.
- **Title** (600, 20px / 26px, `-0.1`): card headers, sheet titles, list group
  headers.
- **Body** (400, 16px / 24px): default reading and input text. Cap measured
  text at 65 to 75ch.
- **Label** (600, 12px / 16px, `+0.2`; small 11px `+0.5`): chip text, eyebrows,
  metadata, badges.
- **Amount** (600, 40px hero / 28px large / 16px default, `tnum`): every money
  value, always tabular. The hero amount is the visual anchor of a screen.

### Named Rules
**The Tabular Money Rule.** Every numeric money value uses Inter with
`tnum`. Always. A balance that shifts column width as it updates is a bug, not
a style choice.

**The Single-Family Rule.** Inter only. No serif display, no second face.
Hierarchy comes from size and weight (600 vs 400), not from mixing fonts.

## 4. Elevation

Border-first. Surfaces are flat at rest and defined by a single 1px border
(`#D4D4CE` light, petrol-toned dark). Shadows are auxiliary, soft, low, and
reserved for things that genuinely float: the FAB, toasts, bottom sheets,
modals, full-screen overlays. The look is paper on a desk, not glass panes
hovering in space. If a card needs a drop shadow to feel separate from the
background, the border is doing its job wrong.

### Shadow Vocabulary
- **e0** (no shadow, 1px border): default for cards, rows, inert surfaces.
- **e1** (`0 1px 2px rgba(17,22,19,0.04)`): raised cards, tab bar.
- **e2** (`0 4px 12px rgba(17,22,19,0.08)`): FAB, toast.
- **e3** (`0 12px 32px rgba(17,22,19,0.12)`): bottom sheet, modal.
- **e4** (`0 24px 64px rgba(17,22,19,0.16)`): full-screen overlay.

### Named Rules
**The Border-Before-Shadow Rule.** Reach for a 1px border first. A shadow is
permitted only when an element must visibly lift above the canvas in response
to state or stacking (sheet, FAB, modal). Decorative shadows are forbidden.

## 5. Components

Warm, tactile, responsive. Components invite the tap: rounded enough to feel
friendly, with real press feedback. The signature interaction is a subtle
`scale(0.97)` on press at 80ms, so every control feels physical.

### Buttons
- **Shape:** gently rounded (12px radius, `rounded.md`). Heights 36 / 44 / 52
  for sizes s / m / l.
- **Primary:** solid Trusted Money Green fill, white text. The one loud element
  on a screen.
- **Secondary:** white surface, mint text, 1.5px strong-stone border.
- **Tertiary / Ghost:** transparent; mint text (tertiary) or ink text (ghost).
- **Destructive:** soft red surface (`#FBEAE9`) with red text; a solid-red
  variant exists for the rare hard-stop confirm.
- **Press / Disabled:** `scale(0.97)` at 80ms on press; 0.4 opacity disabled.
  No hover states (touch-first, Android).

### Chips
- **Style:** full pill (`rounded.full`), 32px high, label type.
- **State:** default is muted-stone fill with ink text; selected flips to mint
  fill with white text; outline is transparent with a 1px border. Dismissible
  chips carry a small close glyph at 75% opacity.

### Cards / Containers
- **Corner Style:** 12 to 16px (`rounded.md`/`lg`).
- **Background:** surface-white (light) / petrol-surface (dark).
- **Shadow Strategy:** e0 by default. Border defines the edge; see Elevation.
- **Border:** 1px border-stone hairline.
- **Internal Padding:** 16px (`spacing.md`) standard.

### Inputs / Fields
- **Style:** surface fill, 12px radius, 1px default border, 14px horizontal pad,
  44px min height.
- **Focus:** border thickens to 2px and shifts to brand mint. Cursor is mint.
  No glow, no fill change.
- **Error / Disabled:** error is a 2px danger-red border plus red helper text
  below; disabled is a muted fill with a subtle border.

### Navigation
- **Bottom tab bar (`loit_tab_bar`):** the app's primary nav. 5 slots, 64px
  tall, surface fill with a 1px top border and e1 shadow. Slots: Home,
  Transactions, **Scan FAB (center)**, Rooms, Settings. Side items are tabs:
  24px icon (filled when active, outline when not) over an 11px label, active in
  mint, inactive in ink-secondary.
- **Center Scan FAB:** the capture hot path made physical. A 52px ochre-accent
  circle (e2 shadow, scanner glyph in inverse), raised out of the bar. It is
  the one always-animated element: a slow sine "breathe" (±2.5%, 2.4s loop) plus
  a single expanding halo pulse that fades as it grows. Press scales to 0.94.
  When the user is inside a shared room it re-skins to that room's palette color
  and grows a small group badge, signaling the scan will land in the room, not
  the personal feed.
- **Month app bar:** screen-level header carrying the active month context.

### Bottom Sheet (signature)
The primary surface for capture and pickers (category, account, currency).
`loit_sheet` / `showLoitSheet`.
- **Shape:** top-rounded only (24px, `rounded.xl`), flush to the screen bottom.
- **Surface:** surface-white / petrol-surface over a transparent barrier, e3
  shadow. Max height 92% of viewport; content scrolls inside.
- **Drag handle:** a 40x4 border-default pill at the top, centered. Sheets are
  drag-dismissible by default.
- **Title:** optional title row in Title type (20px) with an optional trailing
  action.
- **Behavior:** presented over the root navigator so it overlays the persistent
  tab bar instead of rendering behind it.

### Signature Component: Amount Text
`loit_amount_text` renders money with tabular figures and directional color
(income-positive in green, expense in ink/red as context dictates). It is the
most-repeated visual unit in the app and the reason the type scale carries a
dedicated `amount` role.

## 6. Do's and Don'ts

### Do:
- **Do** keep mint under ~10% of any screen. One primary action, one selected
  state. The One Voice Rule is the whole color strategy.
- **Do** render every money value in Inter with tabular figures (`tnum`).
- **Do** define surfaces with a 1px border first; reserve shadows (e2 to e4) for
  things that truly float (FAB, sheet, modal).
- **Do** tint neutrals toward the brand hue. Cream `#FAFAF7` and ink `#111613`,
  not white and black.
- **Do** keep the capture path uncluttered: a few legible numbers, generous
  spacing, the next tap obvious one-handed.
- **Do** use the 8-color room palette for shared-room identity, one stable hue
  per room.

### Don't:
- **Don't** ship **cold corporate banking**: no navy-and-gold, no dense forms,
  no jargon, no teller-window sterility.
- **Don't** ship **crypto or fintech hype**: no neon-on-black, no aggressive
  gradients, no gamified greed, no fake-urgency copy.
- **Don't** build a **cluttered spreadsheet dashboard**: no walls of tiny
  numbers, no chart overload, no everything-crammed-on-one-screen.
- **Don't** use pure `#000` or `#fff` anywhere.
- **Don't** add a drop shadow to make a flat card feel separate; fix the border.
- **Don't** tint whole panels mint or introduce a second brand color; ochre is
  an accent, not a co-lead.
- **Don't** mix in a second font family or a serif display. Inter, weight and
  size for hierarchy.
