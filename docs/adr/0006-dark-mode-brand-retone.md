# Dark mode retoned to the logo palette (mint on petrol)

The LOIT wordmark is vivid mint green `#34E89E` on deep petrol teal `#0B3A42`,
but the app's color tokens were a muted sage-teal + ochre system with a neutral
near-black dark canvas (`#101311`). The logo and the running app read as
different products. We retoned **dark mode** around the logo: a mint **brand**
on a petrol **ground**, ochre kept as the warm accent.

Two deliberate divergences make this surprising to a future reader, and are the
reason this ADR exists:

1. **Dark canvas is desaturated petrol `#0D2E33`, not the logo's `#0B3A42`.**
   The full-chroma logo petrol is immersive but fatiguing for a finance app
   users stare at daily; the slightly desaturated ground keeps the mood, calms
   long sessions, and makes full-chroma mint pop harder as the single loud
   element. Pure `#0B3A42` is reserved for splash/marketing surfaces.
2. **Income blue is brightened to cyan `#5CC8E8` in dark only.** `income` maps
   to status `info` blue, and blue is a hue-neighbor of petrol teal — on the new
   ground the feel-good number receded while red expenses popped (backwards for
   finance). The cyan shift restores income's lift without changing the
   blue=income / red=expense semantics. Light `info` is unchanged.

Brand is mint in **both** themes for logo coherence: dark uses `#34E89E`
as-is; light uses a darkened mint `#1FA871` for AA contrast on white.

## Considered options

- **Canvas + brand only (surgical)** — rejected: leaves the rest of the dark
  ramp neutral-gray on a teal ground, so borders read muddy and the retone
  looks half-applied.
- **Pure logo two-color system (mint + petrol, drop ochre)** — rejected: an
  all-teal-green UI reads clinical for daily finance use, and the paywall loses
  its contrast signal — "go Pro" would look like every other mint button. Ochre
  is the warm near-complement that stops monochrome fatigue and marks upgrade.
- **Full petrol/mint retone, ochre kept (chosen)** — three-color system (mint
  brand, ochre accent, petrol ground), teal-tinted borders, mint focus ring,
  cyan income. Coherent with the logo without going one-note.

## Consequences

- **Invariant: mint is a light fill, so anything on it takes a dark
  (`contentInverse`) foreground.** Buttons/chips/icon-buttons already did this;
  the Material checkbox check-glyph and switch thumb were hardcoded
  `Colors.white` (near-invisible on mint) and were flipped to `contentInverse`
  in `loit_theme.dart`. New mint-filled controls must follow this rule.
- `info` now does double duty as income-amount color and info-status color in
  dark; both want pop, so the cyan shift serves both.
- Pre-existing, untouched: the FAB uses `accent` (ochre) with a white
  foreground — weak contrast on light ochre, predates this change. And
  `RoomColors.palette` duplicates `LoitPalette.rooms` byte-for-byte; the retone
  left both as-is. Both are separate cleanups.
- `success` green still sits near mint in status chips/banners. Income/expense
  are blue/red (not green), so the collision is narrow; a deeper-emerald
  `success` is a deferred low-priority nudge, not done here.
