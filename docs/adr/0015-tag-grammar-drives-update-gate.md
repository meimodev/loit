# Git tag grammar drives the Update gate

## Context

Some releases are **breaking** — an old client must be forced to update before it
keeps talking to the backend — and most are not. We need a server-controlled
**Update gate** (see [CONTEXT.md](../../CONTEXT.md)) holding three semver
thresholds (`min`, `recommended`, `latest`) that the client compares against its
own `versionName`. The open question was operational: *who sets those three
numbers, and how, given a human must judge whether a release is breaking?*

The gate keys on the **semver string**, not the build number: CI overrides the
pubspec `+N` (`versionCode`) with a timestamp (`$(date +%s)/60`), so the build
number is unknowable before a release. The semver (`versionName`) is preserved by
CI and bumped each release by `push-deploy` — it is the only human-controlled,
known-ahead identity.

Options considered:

- **Admin dashboard / manual SQL** — edit the row by hand after each release.
  Flexible, but `latest` silently drifts when forgotten, and the breaking call
  lives nowhere durable.
- **Commit-message flag** — parse `[breaking]` from commits. Fuzzy; a squash or
  reword loses it.
- **Git tag grammar** (chosen) — the release tag, which already triggers CI,
  also encodes severity.

## Decision

The release **git tag** is the single source of truth for the gate. CI parses the
tag suffix and upserts the `app_release_gate` row (PostgREST + a Supabase secret),
**cascading up** so the invariant `min <= recommended <= latest` holds with no
manual reconciliation:

| Tag | Sets |
|---|---|
| `v1.2.0` | `latest` = 1.2.0 |
| `v1.2.0-recommended` | `recommended` = `latest` = 1.2.0 |
| `v1.2.0-breaking` | `min` = `recommended` = `latest` = 1.2.0 |

A breaking release is implicitly also recommended and latest; a recommended one is
implicitly latest. Severity is declared once, at tag time, by the person cutting
the release.

## Consequences

- The breaking judgment is recorded durably and visibly in tag history, not in a
  dashboard's audit log.
- `-breaking` / `-recommended` are **CI signals only**. The pubspec version stays
  bare semver (`1.2.0`); the suffix never reaches `versionName`. CI must strip it
  before computing the threshold value.
- Mistakes are sticky: a `-breaking` tag force-blocks every older client the
  moment CI runs. A wrong tag is corrected by pushing a new higher tag or a
  deliberate manual SQL override — never by deleting the tag.
- **Thresholds only ever rise, and CI enforces it (not just the cascade).** Tags
  fire in *push* order, not *version* order, so a stale or backport tag (e.g. a
  `v1.0.9` hotfix cut after `v1.1.0` shipped) would otherwise blindly overwrite
  `latest` downward and silently un-offer the newer release. The CI step reads
  the current row and `max()`-es each field, so a lower tag is a no-op. Lowering
  any threshold is therefore possible *only* via a deliberate manual SQL override
  — the intended escape hatch, kept off the automated path.
- Team muscle memory now binds to this grammar. Reversing it (back to manual, or
  to a console UI) means rewriting the CI publish step and retraining the release
  ritual — deliberate, not free.
