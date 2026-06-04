import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';

/// Circular-avatar background image, disk-cached via [CachedNetworkImageProvider].
///
/// Centralizes avatar image loading so every avatar shares one disk cache and
/// re-downloads are avoided across launches/scrolls. Returns `null` when [url]
/// is missing or empty, so callers keep their existing text-initial fallback.
DecorationImage? loitAvatarImage(String? url) =>
    (url != null && url.isNotEmpty)
        ? DecorationImage(
            image: CachedNetworkImageProvider(url),
            fit: BoxFit.cover,
          )
        : null;
