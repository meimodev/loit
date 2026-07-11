# QR-only room invites

Room invites had two user-facing surfaces — a shareable link (URL row + Copy +
Share on the "Undang anggota" screen, accepted via `loit.app/invite/{token}`
deep link or pasted into a join screen) and a live QR scan through the Capture
camera — plus a third, email-based invite path (`create-room-invite` Edge
Function) that no client code ever called. We decided the QR scan is the only
invite mechanism: the inviter shows the QR on the "Undang anggota" screen, the
joiner points the Capture camera at it. All link-sharing UI and the paste-to-join
screen are removed, and the dead email-invite path is deleted.

The deliberate trade-off: **invites now require co-presence** (or a second
device displaying the QR). Remote invites have no path. Accepted because LOIT
rooms model households and church congregations — groups that physically meet —
and one join surface is simpler to explain, secure, and maintain than three.

## Consequences

- The deep-link handler (`/invite/:token` route, `deep_link_service.dart`
  invite branch, signed-out token stash) is **kept as silent backward
  compatibility** for links shared before this change. No UI produces new
  links, so a future reader will find a handler with no producer — that is
  intentional, not dead code. It can be deleted once old links have aged out
  (tokens rotate on regenerate anyway).
- The QR payload stays URL-shaped (`https://loit.app/invite/{token}`): the
  scanner's `isLoitInviteUrl` filter and previously printed/screenshotted QRs
  keep working unchanged.
- `RoomJoinScreen` (paste field) is deleted; "Gabung ruangan" entries open the
  scanner (`/scan`) with a join hint overlay.
- The email-invite path (`createInvite` in `room_service.dart`,
  `create-room-invite` Edge Function, `pendingInvitesProvider` + the
  pending-invites banner it feeds) is removed. The `room_invites` table stays —
  `accept_room_invite` still writes accepted rows to it as an audit trail.
