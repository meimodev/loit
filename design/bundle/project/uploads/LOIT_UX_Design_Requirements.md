# LOIT — Mobile App UX Design Requirements

*Split bills, not friendships.*

**Version:** 1.0 | **Platforms:** iOS 15+ / Android 8+ (Flutter 3.24+) | **Markets:** Indonesia → SEA → Global

---

## 0. How to Read This Document

This spec is the **single source of design truth** for LOIT. Every screen, component, and interaction must trace back to a rule here. If a conflict arises between this document and a mockup, this document wins until explicitly amended.

The document is organized top-down: **philosophy → system → components → screens → states**. Designers start at §2; developers implementing Flutter widgets start at §5 and §8.

---

## 1. Executive Summary

LOIT is a personal-first finance tracker with an opt-in shared-room layer. The UX must feel:

| Attribute | What it means in practice |
|---|---|
| **Elegant** | Generous whitespace, one typeface, restrained color, soft motion. Never feels like a spreadsheet. |
| **Consistent** | A single design language across iOS and Android. A button, chip, or sheet behaves identically on both platforms. |
| **Simple** | The primary task on any screen is obvious within 1 second. Secondary actions are always one tap away — never buried. |
| **Trustworthy** | Money is emotional. Every interaction — especially money-moving ones — shows clear state, clear destination, and clear undo paths. |
| **Warm** | LOIT is named after a Minahasan word for money. The product should feel human and local, not cold fintech. |

**North-Star Interaction:** *A user snaps a receipt, confirms three pre-filled fields, and is back on the dashboard in under 10 seconds.*

---

## 2. Design Principles

Five principles govern every design decision. When they conflict, the higher-numbered wins.

1. **Personal before shared.** The default surface is always "My Finances." Rooms exist but never intrude.
2. **One screen, one job.** Each screen has exactly one primary action. If a screen has two, split it.
3. **Show the money, hide the machinery.** Amounts are the hero. Database IDs, sync states, and infra never appear in copy.
4. **Progressive disclosure.** Free-tier users never see a Pro-only field grayed out in their main flow — upgrade prompts surface contextually at the point of value, not as noise.
5. **Destructive and financial actions require a pause.** Every irreversible action (delete, archive, revoke invite, purchase) has a confirmation moment with a clear undo or a clear "this cannot be undone" signal.

---

## 3. Competitive UX Benchmarking

LOIT borrows selectively from best-in-class apps. Do not clone — inherit the principle, not the pixel.

| App | What we take | What we leave |
|---|---|---|
| **Splitwise** | Frictionless expense entry, clean transaction list density | Debt-tracking model (LOIT has removed settlement) |
| **Monzo** | High-contrast typography, playful but confident tone, instant transaction notifications | Full-banking feature sprawl |
| **Revolut** | Multi-currency clarity, tier paywall flow | Data density and ad-like upsells |
| **Notion / Linear** | Keyboard-calm polish, restrained color, command-menu speed | Complexity — LOIT is not a power-user tool |
| **Cash App / GoPay** | Big-number tap targets, one-handed thumb reach | Social feed and branded clutter |
| **Tricount** | Trip-and-group mental model | Ad-supported free tier |

---

## 4. Brand & Identity Foundations

### 4.1 Voice & Tone
- **Voice:** Warm, direct, competent. Like a friend who is good with money but never smug about it.
- **Tone shifts by context:**
  - Dashboard/neutral → calm, factual.
  - Success → brief, affirming ("Saved.").
  - Error → honest, solution-first ("No internet. Your entry is saved — we'll sync it.").
  - Paywall → confident, value-first, never guilt-trippy.
- **Forbidden patterns:** No exclamation marks on destructive confirmations. No emoji in error copy. No "Oops!". No "Uh oh!".
- **Bilingual parity:** Every string ships in English and Bahasa Indonesia simultaneously. Indonesian is not a translation — it is a co-primary language. Copy is written, not machine-translated.

### 4.2 Logo & Wordmark
- Wordmark-primary ("LOIT" in the brand typeface).
- A monogram mark ("L" or a receipt glyph) used only for app icon, favicons, and Avatar fallbacks.
- Minimum clear space: 1× the cap height of the wordmark on all sides.

---

## 5. Visual Design System

### 5.1 Color

LOIT uses a restrained palette. Color carries semantic meaning — it is never decorative.

#### Core Palette (light theme)

| Token | Suggested Hex | Usage |
|---|---|---|
| `color.brand.primary` | `#0F6E5C` (deep Minahasan teal) | Primary CTAs, active nav, brand marks |
| `color.brand.primary-pressed` | `#0A5A4B` | Pressed/active state |
| `color.brand.accent` | `#F2A85C` (warm sunset ochre) | Highlights, room-specific accents, celebrations |
| `color.bg.canvas` | `#FAFAF7` (warm off-white) | App background |
| `color.bg.surface` | `#FFFFFF` | Cards, sheets |
| `color.bg.surface-muted` | `#F3F2ED` | Secondary surfaces, input fields |
| `color.text.primary` | `#111613` | Body, numbers |
| `color.text.secondary` | `#5A6160` | Labels, metadata |
| `color.text.tertiary` | `#9AA09E` | Placeholders, disabled |
| `color.border.subtle` | `#EAEAE4` | Divider, input border |
| `color.border.strong` | `#C9CCC5` | Focus rings |

#### Semantic Palette

| Token | Hex | Usage |
|---|---|---|
| `color.status.success` | `#2F8F5E` | Under-budget, sync success |
| `color.status.warning` | `#D49A2B` | Budget 80%, expiry warning |
| `color.status.danger` | `#C5443E` | Over-budget, failed action, delete |
| `color.status.info` | `#3E7AC5` | Informational banners |

#### Dark Theme

Dark mode is a first-class theme, not an afterthought. Generate paired tokens (`color.bg.canvas` → `#101311`, `color.text.primary` → `#F2F2EC`, etc.). Preserve the brand primary's perceptual lightness — adjust saturation, not hue. Test every screen against both themes before shipping.

#### Rules
- Money amounts are always `color.text.primary`. Color them semantically (success/danger) *only* in budget and delta contexts.
- Never use color alone to convey meaning. Pair with icon or label for accessibility.
- Contrast: all body text ≥ 4.5:1. All large text and icons ≥ 3:1.

### 5.2 Typography

**Single typeface family** across iOS and Android. Recommended: **Inter** (free, excellent multilingual coverage including Bahasa Indonesia diacritics, tabular numerals). Fallback: system sans.

| Token | Size / Line-height | Weight | Use |
|---|---|---|---|
| `type.display` | 40 / 44 | 600 | Dashboard hero amount, onboarding headlines |
| `type.title-xl` | 28 / 32 | 600 | Screen titles |
| `type.title-l` | 22 / 28 | 600 | Section headers |
| `type.title-m` | 18 / 24 | 600 | Card titles, list group headers |
| `type.body-l` | 16 / 24 | 400 | Default body |
| `type.body-m` | 14 / 20 | 400 | Secondary body, metadata |
| `type.body-s` | 12 / 16 | 500 | Captions, chips, tags |
| `type.mono-num` | matches context | 500, tabular | All numeric amounts |

**Rules**
- All amounts use **tabular numerals** (`font-feature-settings: "tnum"`). This is non-negotiable — it keeps columns aligned.
- Currency symbols sit tight against the number (`Rp85,000` not `Rp 85,000` in Indonesian locale; `$4.99` always). Locale-aware formatting is driven by `intl` package, not manual strings.
- No more than three text sizes per screen.
- Line length caps at ~60 characters for body copy.

### 5.3 Spacing & Grid

8-point grid. Every margin, padding, and gap is a multiple of 4 (micro) or 8 (default).

| Token | Value | Use |
|---|---|---|
| `space.xs` | 4 | Icon-to-label gap |
| `space.s` | 8 | Chip padding, tight stacks |
| `space.m` | 12 | Card internal padding tight |
| `space.l` | 16 | **Default screen horizontal padding**, card padding |
| `space.xl` | 24 | Section spacing |
| `space.2xl` | 32 | Major section breaks |
| `space.3xl` | 48 | Hero breathing room |

**Safe areas:** Always respect notch, Dynamic Island, and Android system bars. Bottom content maintains 16pt clearance from the nav bar or home indicator.

### 5.4 Radius & Elevation

| Token | Value | Use |
|---|---|---|
| `radius.s` | 8 | Chips, small tags |
| `radius.m` | 12 | Input fields, buttons |
| `radius.l` | 16 | Cards, list items |
| `radius.xl` | 24 | Bottom sheets, modals |
| `radius.full` | 999 | Avatars, circular FABs |

**Elevation:** LOIT uses soft, low-spread shadows — not Material's heavy ones. Prefer border-based separation for most surfaces; reserve shadow for floating elements (FAB, sheets, toasts).

- `elevation.0` — border only (`1px color.border.subtle`)
- `elevation.1` — `0 1px 2px rgba(17, 22, 19, 0.04)` — cards
- `elevation.2` — `0 4px 12px rgba(17, 22, 19, 0.08)` — floating buttons
- `elevation.3` — `0 12px 32px rgba(17, 22, 19, 0.12)` — sheets, modals

### 5.5 Iconography

- **Single icon set:** Lucide or Phosphor (thin, 1.5px stroke). Do not mix sets.
- Icon sizes: 16, 20, 24, 32. Default 24 for nav/actions, 20 in dense lists.
- Icons are monochrome — they inherit text color. Color them semantically only in status contexts.
- Category icons use filled variants for consistency with transaction rows.

### 5.6 Imagery & Illustration

- **No stock photography.**
- Onboarding and empty states use a small, custom illustration set in two accent colors + one neutral. Keep illustrations flat and geometric — avoid gradients and 3D.
- Receipt photos, when shown, always render inside a `radius.l` container with a subtle border.
- User avatars: always circular, always with a colored-initial fallback if no photo.

---

## 6. Cross-Platform Strategy (Flutter Unified)

LOIT ships one design on both platforms — **not** Material on Android and Cupertino on iOS. Custom widgets built on Flutter's Material base with platform-adaptive behavior only where it meaningfully improves usability.

| Element | iOS Behavior | Android Behavior |
|---|---|---|
| Navigation transition | Slide-from-right, swipe-back edge gesture enabled | Slide-from-right, system back button + gesture |
| Modal sheets | iOS-style bottom sheet with grabber, snap points | Material bottom sheet with grabber |
| Haptics | `HapticFeedback.lightImpact` on taps, `selectionClick` on pickers | Matching vibration patterns via `HapticFeedback` |
| Date picker | Native iOS wheel picker in sheet | Native Material calendar |
| Share sheet | Native `UIActivityViewController` | Native `Intent.ACTION_SEND` |
| Permissions copy | Matches Apple human interface language ("LOIT would like to access your camera to scan receipts.") | Matches Material ("Allow LOIT to take photos and record video?") |
| Fonts | Ship Inter as bundled font on both | Same |
| Keyboard | Auto-dismiss on tap outside | Same |
| Pull-to-refresh | iOS-style bouncy indicator | Circular Material indicator |
| Biometric lock | Face ID / Touch ID via `local_auth` | Fingerprint / Face unlock via `local_auth` |

Everything else — colors, typography, spacing, components — is identical. The user should recognize LOIT on either platform without reading the OS chrome.

---

## 7. Motion & Interaction Language

Motion in LOIT is **confident and quiet**. Nothing bounces gratuitously. Animations serve orientation, feedback, or continuity — never decoration.

### 7.1 Duration Tokens

| Token | Duration | Curve | Use |
|---|---|---|---|
| `motion.instant` | 80ms | `easeOut` | Hover/press feedback |
| `motion.short` | 180ms | `easeOut` | Chip toggle, small state change |
| `motion.base` | 240ms | `easeInOut` | Default transition |
| `motion.emphasized` | 320ms | custom cubic `(0.2, 0, 0, 1)` | Sheet rise, page transition |
| `motion.long` | 480ms | `easeInOut` | Celebratory moments only (budget saved, first scan success) |

### 7.2 Interaction Rules

- **Every tappable element gives feedback within 80ms.** A ripple (Android) or soft scale-down to 0.97 (iOS) is acceptable. Never wait for the server.
- **Haptics:** Light tap on button press. Selection tick on picker change. Success notification haptic on save. Warning haptic on budget exceeded. Error haptic on failed scan.
- **List inserts** (e.g., real-time room feed) animate in with a 240ms slide-down + fade-in. New items briefly highlight with a 600ms wash of `color.brand.accent` at 8% opacity.
- **Skeleton loaders**, not spinners, for any content load over 300ms. Spinners are reserved for indeterminate operations (scanning, payment processing).
- **Number changes** (total spending, budget progress) tween smoothly using `AnimatedSwitcher` or `TweenAnimationBuilder`. Never snap.
- **No parallax, no scroll hijacking, no auto-playing animations.**

### 7.3 Gesture Vocabulary

| Gesture | Action |
|---|---|
| Tap | Primary action |
| Long-press | Reveal quick actions (edit, delete, recategorize) on transaction rows |
| Swipe-left on row | Expose Delete / Edit (confirm before destructive) |
| Pull-to-refresh | Sync latest data (dashboard, transactions, rooms) |
| Swipe-down on sheet | Dismiss |
| Swipe-back edge (iOS) | Go back |
| Pinch-to-zoom | Receipt photo viewer only |

---

## 8. Information Architecture & Navigation

### 8.1 Top-Level Structure

A **bottom tab bar** with exactly **4 tabs**. The 5-tab pattern is rejected — it dilutes focus and crowds the thumb zone.

```
┌──────────┬──────────┬──────────┬──────────┐
│   Home   │  Scan    │  Rooms   │ Settings │
│ (Dashboard) │ (FAB-like)│        │          │
└──────────┴──────────┴──────────┴──────────┘
```

- **Home** — Dashboard (default). Houses transactions, budgets, reports via tabs or nested screens.
- **Scan** — Center tab rendered as a pronounced circular FAB-style button in the bar, lifting above the bar by 8pt. One tap → camera. This is the app's signature moment.
- **Rooms** — Shared rooms list. Empty state is a gentle, opt-in welcome.
- **Settings** — Profile, subscription, preferences, help.

Transactions, Budgets, and Reports are **sub-destinations of Home**, not top-level tabs. They're reached via a secondary navigation (segmented control or Home screen cards) so the bottom bar stays uncluttered.

### 8.2 Navigation Rules

- Tab bar is always visible on top-level screens. Hidden on modal/detail screens.
- No hamburger menus anywhere in the app.
- Back navigation: every non-root screen has a leading back button AND responds to the platform back gesture.
- Deep links (invite acceptance, push notification taps) always land on the relevant screen with the tab bar intact.

### 8.3 Personal ↔ Shared Separation

The Personal / Shared boundary is a **visual and informational wall**. Violations erode trust.

- Room names never appear on Personal screens unless the user explicitly enables dual-logging at the room level.
- A transaction visible in both layers shows a subtle room badge chip on the Personal side (e.g., `🏠 Apartment 4B`) — small, muted, never competing with the amount.
- The color accent used inside a room's screens is the room's own accent (assigned on creation) — never the global brand primary. This gives each room a quiet identity and prevents confusion between rooms.

---

## 9. Core Component Library

Every screen is assembled from these atoms/molecules. Do not invent new components — extend these.

### 9.1 Buttons

| Variant | Use | Spec |
|---|---|---|
| **Primary** | Single per screen. The main action. | `color.brand.primary` bg, white text, `radius.m`, height 52, type.body-l 600 |
| **Secondary** | Alternative action | Transparent bg, `color.brand.primary` text + 1.5px border |
| **Tertiary / Text** | Low-priority, in-row action | No bg, no border, `color.brand.primary` text |
| **Destructive** | Delete, revoke, archive | `color.status.danger` text on `color.bg.surface-muted` bg |
| **Icon** | Compact, icon-only | 44×44 hit area minimum |

- Minimum hit target **44×44pt** on all platforms (WCAG + Apple HIG).
- Disabled state: 40% opacity, no other style changes.
- Loading state: spinner replaces label, button width locked to prevent layout shift.
- Full-width primary buttons are the default for the bottom of form screens.

### 9.2 Input Fields

- Label sits above the field, not inside (no floating labels — they hurt scannability).
- Amount fields use a large, numeric-keypad-optimized input with the currency symbol as a persistent prefix.
- Error state: border turns `color.status.danger`, error message renders below in `type.body-s`.
- Clear-button (×) appears when the field has content and is focused.

### 9.3 Cards

- Default card: `color.bg.surface`, `radius.l`, `space.l` padding, `elevation.1` or border-only.
- Tappable cards get a subtle press state (scale 0.98, 80ms).
- Maximum one primary action inside a card. Secondary actions live in an overflow menu or detail screen.

### 9.4 List Rows (Transaction Row — Master Pattern)

The transaction row is the **most-rendered component in LOIT**. Get it right or nothing else matters.

```
┌────────────────────────────────────────────┐
│ [Icon]  Merchant name                      │
│         Category · Date           Rp85,000 │
└────────────────────────────────────────────┘
```

- Leading: 40×40 circular icon with category-tinted bg at 12% opacity.
- Title line: merchant name, `type.body-l` 500.
- Subtitle line: category · relative date (`Today`, `Yesterday`, `Mon 12 Dec`), `type.body-m` `color.text.secondary`.
- Trailing: amount, `type.body-l` 600, **tabular numerals**. Currency symbol left-attached.
- If receipt photo exists: a small paperclip or receipt icon sits next to the amount.
- Tap → detail screen. Swipe-left → Delete / Edit. Long-press → quick categorize menu.
- Row height: minimum 64pt (56pt content + 8pt vertical breathing).

### 9.5 Chips

- Single-row horizontal scroll containers for filters (date, category, currency).
- Active chip: `color.brand.primary` bg, white text. Inactive: `color.bg.surface-muted` bg, `color.text.primary`.
- Height 32, `radius.full`, `space.m` horizontal padding.

### 9.6 Bottom Sheets

- Primary surface for secondary actions, pickers, and confirmations.
- Handle bar (grabber) at top: 36×4, `color.border.strong`, 8pt top margin.
- Snap points: peek (30%) and full. Never force full-height unless content demands it.
- Scrim behind sheet: `rgba(0, 0, 0, 0.4)`. Tap to dismiss.
- Sheets can stack (e.g., category picker inside transaction edit sheet), but never more than two deep.

### 9.7 Toasts & Banners

- **Toast** — transient confirmation, auto-dismiss after 3s. Position: top, beneath status bar. One at a time.
- **Banner** — persistent info (offline, expiry warning). Top of the screen, full-width, `color.bg.surface-muted` bg, icon + copy + optional action.
- **Snackbar (Android-style)** — reserved for undo flows ("Transaction deleted — Undo"). Bottom, 5s auto-dismiss.

### 9.8 Progress Indicators

- **Budget bar:** horizontal, 8pt height, `radius.full`. Fills with `color.status.success` (<70%), `color.status.warning` (70–99%), `color.status.danger` (100%+). Overage renders as a darker segment beyond the 100% mark.
- **Scanning progress:** circular indeterminate spinner, 48pt, `color.brand.primary`, paired with status copy ("Reading receipt…").
- **Sync indicator:** small cloud icon in the app bar that cycles through idle / syncing / synced / queued states.

### 9.9 Empty States

Every list has a designed empty state. **Never** show a blank screen.

Structure: illustration (120pt square) → title (`type.title-m`) → body (`type.body-m`) → primary CTA.

Examples:
- Transactions empty: "No expenses yet. Snap your first receipt or add one manually."
- Rooms empty: "Rooms are for friends, trips, and households. Create one or join via invite."
- Budget empty: "Set a monthly goal to see how you're tracking."

---

## 10. Screen-Level UX Specifications

### 10.1 Onboarding (First Launch)

**Goal:** Get the user to their first transaction within 90 seconds.

**Flow (5 screens max, each skippable except auth):**

1. **Welcome** — wordmark, tagline, single "Get Started" CTA. A subtle looping illustration (receipt folding into a phone). No carousel of feature screens — those are vanity and slow adoption down.
2. **Auth** — three equal-prominence options: Continue with Google, Continue with Apple (iOS only — not shown on Android), Continue with Email. Biometric opt-in offered right after auth.
3. **Name + Home Currency** — single screen, two fields, IDR pre-selected based on device locale. Currency picker is a searchable sheet.
4. **Demo Scan (optional)** — "Try scanning a receipt — on us. This one's free." Big illustrated Scan button + "Skip for now" text link. The demo scan does NOT count against monthly quota (per decision log #19). If user scans, they see the full confirmation flow and land on the dashboard with their first transaction pre-populated.
5. **Dashboard arrival** — a single, warm micro-message: "Welcome to LOIT, [Name]. Your money, your way." Dismisses on first tap.

**Permissions** are requested contextually, not upfront. Camera on first scan tap. Notifications after user sets their first budget.

### 10.2 Personal Dashboard (Home)

**Hierarchy (top to bottom):**

1. **Greeting + month chip:** "Hi, Maria" + `November 2026` chip (tap to change month).
2. **Hero amount card:** Total spent this month, huge display number, tabular. Below: delta vs last month as a small chip ("↓ 12% vs October", green or red).
3. **Budget progress strip:** Up to 3 category rings inline (Free tier limit). Each shows category icon, amount spent / limit, color-coded ring. Tap → Budgets detail.
4. **Recent transactions (5):** Transaction rows. "See all →" at the bottom, linking to full log.
5. **Spending trend:** Small sparkline (7 days), minimal — no axes, just shape.
6. **Contextual nudge card (optional):** Surfaces one at a time, e.g. "You're 80% through your Dining budget" or "3 scans left this month" or "Upgrade to Pro for unlimited categories." Dismissible.

Pull-to-refresh syncs with haptic feedback.

### 10.3 Transaction Log

- Sticky header with filter chips: date range, category, currency.
- Transactions grouped by day, with sticky day headers as the user scrolls.
- Search icon in the app bar opens a full-screen search with real-time results.
- Infinite scroll with skeleton placeholders at the bottom as new pages load.
- FAB (bottom-right, above tab bar) for manual add. Slightly smaller and less prominent than the central Scan tab — scanning is the hero path.

### 10.4 Transaction Detail

- Hero: amount, currency, merchant.
- Below: date/time, category (tappable chip to recategorize), notes (inline editable), receipt photo (if Pro/Team — tap to view full-screen).
- For room transactions: a room badge chip near the top linking back to the room.
- Actions at the bottom: Edit (primary), Delete (destructive, with confirm sheet).
- AI-scanned transactions show a subtle "AI-scanned" chip next to the merchant.

### 10.5 Scanner

**The signature flow. Every millisecond matters.**

1. **Camera view** opens full-screen with a receipt-shaped guide overlay. Copy above: "Position the receipt inside the frame."
2. **Capture** — single tap on a large circular shutter. Haptic feedback on capture.
3. **Review still** — captured image shown for 1.5s with "Scanning…" overlay while compression and upload happen.
4. **Confirmation screen** — pre-filled fields: merchant, date, category, total, items (collapsible list). Every field is tappable-to-edit. A destination selector at the bottom: `My Finances only` / `This room only` / `Both` (only relevant in room context).
5. **Primary CTA:** "Save" → returns to previous screen with a success toast and haptic.

**Failure states (per decision log #4, #14):**
- AI parse failure → straight to manual entry screen, pre-filled with whatever was detected. No retry screen. Copy: "We couldn't read all of it — fill in the rest."
- Connection error → retry screen with "Scanning requires internet" + Retry + Manual entry link.
- In-app error → "Something went wrong. Try again." + Retry.

**Scan counter:** A small persistent chip at the top of the camera view ("7 of 8 scans · Resets Dec 1"). Demo scan shows "Free demo — on us." Top-up CTA surfaces only when 1 or 0 scans remain.

### 10.6 Budget

- List of budget cards, each a horizontal budget bar with category icon, name, spent/limit, and percentage.
- Tap a card → sheet with history (this month + previous months, line chart).
- FAB: Add category (Free tier: shows paywall once 3 categories are reached).
- Alerts are configured per-budget with a toggle (default on).

### 10.7 Reports

- Segmented control at top: By Category / By Merchant / Trend / Calendar.
- Pie/donut chart for category breakdown (tap slice → drill in).
- Bar chart for month-over-month.
- Calendar heatmap for daily spending intensity.
- All charts are tappable — never decorative. Tapping surfaces the underlying rows.
- Export button (Pro/Team only): opens a sheet with CSV / PDF options and date range picker.
- Free tier: a muted banner on the trend view: "Showing last 3 months. Upgrade to Pro for full history."

### 10.8 Rooms List

- Empty state: illustrated + "Create room" and "Join with invite link" CTAs side-by-side.
- Populated: cards, one per room. Each card shows room name, member avatars (max 4 visible + "+N"), total spent in the current period, last activity relative time.
- Archived rooms collapse into a "Archived (3)" folder at the bottom.
- Plus button in app bar → create room sheet.

### 10.9 Room Detail

Single screen with three tabs (segmented control, not separate screens):

1. **Feed** — real-time transaction list, newest first. Presence indicator at the top: stacked small avatars + "Alex is adding an expense…" ephemeral indicator.
2. **Budget** — shared budget cards. Shows contribution by each member within each category.
3. **Reports** — combined room reports.

**No-connection state:** if the user opens a room while offline, a full-screen centered message: "Rooms need internet." + Retry. Tab bar stays active so they can return to Personal.

**Room header:** room name, member count, creator-only settings icon (leads to sheet with Archive, Regenerate invite, Sync settings, Leave — Leave is destructive-styled).

### 10.10 Invite Flow

- Creator sees a sheet: QR code (large, scannable), the same link as copyable text, a native Share button.
- "Link expires in 7 days for each recipient." shown as a subtle footnote.
- Regenerate link option at the bottom, confirm-destructive style ("This invalidates the old link.").
- **Invitee side:** tapping a deep link opens the app (or App Store if not installed). Landing sheet: room name, creator's name, member count, "Join room" primary CTA, "Decline" text link. Joining is instant — no approval step.

### 10.11 Paywall

One screen, one job: make the value obvious, make the purchase safe.

Structure:
- Short headline tied to the gated feature ("Unlimited budgets. Unlimited currencies. Pro.").
- Three-tier comparison card (Free / Pro / Team) with monthly prices. Recommended tier (Pro) visually elevated with a subtle border in `color.brand.accent`.
- Feature comparison table — concise, scannable, emoji-free.
- Toggle: Monthly / Yearly (yearly shows "2 months free" badge).
- Primary CTA: "Start Pro — Rp85,529/mo" (dynamic based on selection).
- Below CTA: small print — "Billed via Midtrans. Cancel anytime. Terms & Privacy."
- Secondary action: "Not now" as a text link in the top-right corner, never as a dismissive (X) that feels like a mistake.

After purchase:
- Midtrans Snap opens in-app (no browser redirect). On return, a full-screen success state: illustration, "You're on Pro.", summary of unlocked features, "Back to app" CTA.

### 10.12 Settings

Grouped, vertically scrollable. No tabs.

- **Profile** — name, avatar, email.
- **Subscription** — current plan, renewal date, upgrade/downgrade.
- **Preferences** — home currency, app theme (System / Light / Dark), language (System / English / Bahasa Indonesia), app lock (biometric/PIN toggle), notifications (per-category toggles).
- **Data** — export all data (Pro/Team), delete account.
- **Support** — help center, contact, privacy policy, terms.
- **About** — version, build.

Destructive actions (Delete account) live at the bottom in `color.status.danger` text, require re-authentication, and surface a confirmation sheet with typed-confirmation for irreversible actions.

---

## 11. State Patterns

Every screen must handle five states explicitly. Undefined states are bugs.

| State | Pattern |
|---|---|
| **Empty** | Illustration + title + body + CTA (per §9.9). |
| **Loading** | Skeleton placeholders matching the target layout's shape. No spinners for structural loads over 300ms. |
| **Error (recoverable)** | Inline banner with cause + action ("Can't load transactions. Retry."). App stays usable. |
| **Error (blocking)** | Full-screen state with illustration + explanation + action. Reserved for auth failures, payment failures, no-connection-in-room. |
| **Success** | Toast (transient) or full-screen moment (onboarding, first scan, tier upgrade). Never a modal. |

### 11.1 Offline UX Patterns

Offline is a first-class state, not an error.

- **Persistent offline banner** at the top of the screen when disconnected: "You're offline. Personal tracking still works." Tappable to show more info.
- Manual transaction entry works. Save button shows "Saved locally" with a cloud-with-arrow icon instead of the usual check.
- Scanner is **disabled with explanation**, not hidden. The Scan tab shows a muted state and tapping surfaces a sheet: "Scanning needs internet." with a Manual entry alternative.
- Room screens show the full-screen no-connection state.
- On reconnect: a brief top banner "Synced. [N] transactions synced." appears for 3s, haptic success, then dismisses.

---

## 12. Notifications & Feedback

Aligned with Appendix A of the blueprint. Additional UX rules:

- **Grouping:** Multiple room events within a short window collapse into a single notification ("3 new expenses in Bali Trip").
- **In-app vs push parity:** Anything that produces a push also appears as an in-app banner or feed entry if the user is in the relevant screen — never show a push for something the user is clearly already looking at.
- **Quiet hours:** System-respected (iOS Focus, Android Do Not Disturb). LOIT never bypasses.
- **Opt-in tiers:** Settings offers granular control — budget alerts, room activity, receipt expiry, marketing (off by default).
- **Permission ask:** Only request push permission after the user sets their first budget, with a short pre-prompt explaining why.

---

## 13. Accessibility

LOIT meets **WCAG 2.2 AA** at launch. Accessibility is not a Phase 5 item.

| Area | Requirement |
|---|---|
| Contrast | All text ≥ 4.5:1. Icons paired with labels meet 3:1. Verified with tooling per build. |
| Tap targets | Minimum 44×44pt. Spacing between adjacent targets ≥ 8pt. |
| Screen readers | Every interactive element has a semantic label. Amount rows read "Merchant, amount, category, date" in sequence. Decorative icons are hidden from the accessibility tree. |
| Dynamic type | Supports OS text-size scaling up to 150% without layout breakage. Fixed-height chips become multi-line at larger scales. |
| Reduce motion | Respects the OS setting — disables all non-essential animation, replaces with instant transitions. |
| Color blindness | No color-only signaling. Budget bars pair color with numeric percentage and icon. |
| Voice-over flows | Full scan → confirm → save flow is completable by VoiceOver / TalkBack alone. |
| Form labels | Every input has a visible and programmatic label. Errors are announced. |
| Focus order | Logical top-to-bottom, left-to-right. Focus rings are visible and high-contrast. |

---

## 14. Localization UX

English and Bahasa Indonesia are **co-primary**. Every string, every screen, day one.

- **String length planning:** Indonesian often runs 15–25% longer than English. Every button, chip, and banner must accommodate up to 1.3× the English length without truncation. Test both locales in every QA pass.
- **Currency:** `Rp1.000.000,00` (ID) vs `$1,000,000.00` (EN). Driven entirely by `intl` with locale-aware separators.
- **Dates:** `DD/MM/YYYY` (ID) / contextual relative ("Today", "Hari ini") everywhere possible.
- **Number input:** The decimal separator on the number pad respects locale.
- **Language switcher:** Live — no app restart required.
- **No forced market assumptions:** IDR is default because Indonesia is the primary market, but a user whose device is set to US English gets USD as their suggested home currency during onboarding.

---

## 15. Privacy & Trust UX

Given LOIT handles money and invite-only social graphs, trust-signaling is a design responsibility.

- **App lock:** Offered on first successful auth ("Lock LOIT with Face ID?"). Respected throughout — re-auth on resume from background after 5 min.
- **Sensitive-number blur:** Optional setting that blurs amounts on the dashboard until the user taps-to-reveal. Off by default.
- **Room data isolation:** Users always see a clear scope indicator — "This expense is in `Apartment 4B`" or "This expense is private to you." — on any screen where the scope could be ambiguous.
- **Receipt expiry UX:** The Day 335/350/360 flow (decision log #3) renders as designed banners and push notifications, never as scary red alerts. Copy is calm and solution-first.
- **Data deletion:** Settings → Data → Delete account. Shows exactly what will be deleted, requires password re-entry, offers CSV export before proceeding.
- **No dark patterns:** Cancel subscription is as easy to find as upgrade. Confirmation sheets default-focus the safe option, not the destructive one.

---

## 16. Performance & Perceived Speed

Perceived speed is a design concern, not just an engineering one.

| Target | Spec |
|---|---|
| App cold start | < 3 seconds to first interactive screen (per blueprint QA) |
| Tab switch | < 150ms visible content swap (use cached data, not refetch) |
| Scan confirmation render | Pre-rendered skeleton within 100ms of shutter; fields populate as AI returns |
| Transaction save | Optimistic UI — the transaction appears in the list before the server confirms. If save fails, it silently reappears with a retry option. |
| List scroll | 60fps sustained on mid-tier devices (Samsung A-series, iPhone SE) |
| Image load | Receipt thumbnails use blur-up placeholders. Full-size photos lazy-load on tap. |

---

## 17. Design Tokens — Flutter Implementation

All tokens defined in §5 live in `lib/core/theme/tokens.dart` and are referenced, not hardcoded, in every widget. A widget referencing `#0F6E5C` directly is a lint failure.

```dart
// Example shape
class LoitColors {
  static const brandPrimary = Color(0xFF0F6E5C);
  static const brandPrimaryPressed = Color(0xFF0A5A4B);
  // ...
}

class LoitSpacing {
  static const xs = 4.0;
  static const s = 8.0;
  static const m = 12.0;
  static const l = 16.0;
  // ...
}
```

The design system is exported as a single `ThemeData` and a complementary `LoitTheme` extension for tokens not covered by Flutter's default theme (custom radii, motion durations, elevation shadows).

---

## 18. Success Metrics — UX KPIs

UX design success is measured, not felt.

| Metric | Target (6-month post-launch) |
|---|---|
| Time from app open to first transaction (new user) | < 90 seconds median |
| Scan → save completion rate | > 85% |
| Manual-entry fallback from AI failure → saved | > 70% |
| Onboarding completion rate | > 80% |
| 7-day retention | > 35% |
| 30-day retention | > 20% |
| Paywall → purchase conversion | > 3% |
| Accessibility audit score | 100% WCAG 2.2 AA |
| Crash-free sessions | > 99.5% |
| App Store rating | ≥ 4.5 |

---

## 19. Do's and Don'ts — Quick Reference

### Do
- Lead every screen with the one thing the user came to do.
- Use tabular numerals for every amount.
- Show offline state explicitly — don't fail silently.
- Ship both languages on day one.
- Animate number changes, not decorations.
- Keep the Personal/Shared wall intact.

### Don't
- Use more than one primary action per screen.
- Rely on color alone to convey meaning.
- Show empty white screens — design every empty state.
- Mix icon sets.
- Add a 5th bottom tab.
- Guilt-trip users on paywalls.
- Put destructive actions near safe actions without confirmation.
- Skip haptics — they're free polish.

---

## 20. Design Handoff Checklist (Per Screen)

Before any screen is marked "design complete":

- [ ] Light + dark theme
- [ ] English + Bahasa Indonesia at max-length
- [ ] All five states (empty / loading / error-recoverable / error-blocking / success)
- [ ] Offline behavior defined
- [ ] Accessibility labels specified
- [ ] Motion spec attached (what animates, how long, what curve)
- [ ] Haptic moments identified
- [ ] Tap targets verified ≥ 44pt
- [ ] Token-only colors (no raw hex in the design file)
- [ ] Reviewed against §2 principles

---

*LOIT — Split bills, not friendships.*
