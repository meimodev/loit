# 3. Disk-cache network images; key receipt cache by storage path, not signed URL

Date: 2026-06-04

## Status

Accepted

## Context

Every network image in the app loaded through Flutter's `NetworkImage` /
`Image.network`, which cache only in the in-memory `ImageCache`. Bytes are
dropped on app restart and under memory pressure, so avatars and receipt
thumbnails re-download on every cold start and often on scroll. Avatars recur
across the dashboard header, settings, room member rows, and transaction
detail; receipt thumbnails recur in the scanner and transaction views.

Receipts add a wrinkle: they live in a **private** Supabase storage bucket and
are served via `createSignedUrl(path, 3600)` — a signed URL that **rotates
every hour**. A naive disk cache keyed on the URL string therefore misses on
every rotation (and on every fresh resolve), defeating the cache for exactly
the heaviest images. Avatars, by contrast, use stable URLs and cache cleanly on
the URL itself.

The app's no-animation constraint also matters: `cached_network_image` fades
images in by default, which we do not want here.

## Decision

- **Add `cached_network_image`** as the single disk-backed image loader.
- **Avatars** swap `NetworkImage(url)` → `CachedNetworkImageProvider(url)` via a
  shared helper `loitAvatarImage(url)` in `lib/shared/widgets/loit_avatar.dart`.
  The helper is the one place avatar image loading is defined, ending the
  previous per-screen duplication. The URL is the cache key (avatar URLs are
  stable).
- **Receipts** (`LoitReceiptImage`) use `CachedNetworkImage` with an **explicit
  `cacheKey` set to the stable storage path**, while `imageUrl` stays the
  hourly-rotating signed URL. Cached bytes are keyed by path, so they survive
  URL rotation and persist across launches; a fresh signed URL is only fetched
  on a cache miss.
- **No fade.** Every `CachedNetworkImage` sets
  `fadeInDuration: Duration.zero` / `fadeOutDuration: Duration.zero` to honor
  the no-animation constraint.

## Consequences

- **`cacheKey` and `imageUrl` intentionally diverge for receipts.** A future
  reader will see a stable `cacheKey` paired with a rotating `imageUrl` and may
  assume it is a bug — it is not. Keying on the signed URL would re-break
  caching every hour. Do not "simplify" by dropping `cacheKey`.
- **Avatar loading is centralized.** New avatar surfaces should call
  `loitAvatarImage`, not inline `NetworkImage`, so caching stays uniform.
- **Disk usage grows** with cached image bytes; `cached_network_image` evicts on
  its own LRU policy. Acceptable for avatar/receipt volumes.
- **A single new dependency.** Reversible by removing the package and restoring
  `NetworkImage` / `Image.network`, at the cost of re-download on every launch.
- Scope was limited to image caching. Other audited items (room aggregation
  query consolidation, `select('*')` narrowing, provider rebuild granularity,
  `autoDispose` policy, `ListView`→sliver) were evaluated and deliberately
  **not** taken: each was marginal or net-negative at current data sizes.
