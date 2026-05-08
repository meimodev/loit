/// Parses a LOIT room-invite token from a URL or bare token string.
///
/// Accepts:
///   - `https://loit.app/invite/{token}`
///   - `loit://invite/{token}`
///   - `https://example/r/{token}` (legacy short form)
///   - Bare token (returned as-is after trim)
///
/// Returns null only when the input is empty.
String? extractInviteToken(String raw) {
  final s = raw.trim();
  if (s.isEmpty) return null;
  final uri = Uri.tryParse(s);
  if (uri != null && uri.pathSegments.length >= 2) {
    final i = uri.pathSegments.indexOf('invite');
    if (i >= 0 && i + 1 < uri.pathSegments.length) {
      return uri.pathSegments[i + 1];
    }
    final r = uri.pathSegments.indexOf('r');
    if (r >= 0 && r + 1 < uri.pathSegments.length) {
      return uri.pathSegments[r + 1];
    }
  }
  return s;
}

/// True iff [raw] looks like a LOIT invite URL (host == loit.app + /invite/
/// path, or custom scheme loit://invite/...). Used to filter out unrelated
/// QR codes (Wi-Fi, payment QRs) before prompting to join.
bool isLoitInviteUrl(String raw) {
  final s = raw.trim();
  final uri = Uri.tryParse(s);
  if (uri == null) return false;
  final isHttpsInvite =
      (uri.scheme == 'https' || uri.scheme == 'http') &&
          uri.host.endsWith('loit.app') &&
          uri.path.startsWith('/invite/');
  final isCustomSchemeInvite = uri.scheme == 'loit' && uri.host == 'invite';
  return isHttpsInvite || isCustomSchemeInvite;
}
