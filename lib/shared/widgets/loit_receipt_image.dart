import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/loit_colors.dart';

class LoitReceiptImage extends StatefulWidget {
  const LoitReceiptImage({
    super.key,
    required this.path,
    this.height = 220,
  });

  final String path;
  final double height;

  @override
  State<LoitReceiptImage> createState() => _LoitReceiptImageState();
}

class _LoitReceiptImageState extends State<LoitReceiptImage> {
  late Future<String> _urlFuture;

  @override
  void initState() {
    super.initState();
    _urlFuture = _resolveUrl(widget.path);
  }

  @override
  void didUpdateWidget(covariant LoitReceiptImage old) {
    super.didUpdateWidget(old);
    if (old.path != widget.path) {
      _urlFuture = _resolveUrl(widget.path);
    }
  }

  Future<String> _resolveUrl(String pathOrUrl) {
    if (pathOrUrl.startsWith('http://') || pathOrUrl.startsWith('https://')) {
      return Future.value(pathOrUrl);
    }
    return Supabase.instance.client.storage
        .from('receipts')
        .createSignedUrl(pathOrUrl, 3600);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    final fallback = Container(
      height: widget.height,
      color: c.muted,
      alignment: Alignment.center,
      child: Icon(Icons.broken_image_outlined, color: c.contentTertiary),
    );

    return FutureBuilder<String>(
      future: _urlFuture,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return Container(
            height: widget.height,
            color: c.muted,
            alignment: Alignment.center,
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: c.contentTertiary,
              ),
            ),
          );
        }
        if (snap.hasError || snap.data == null || snap.data!.isEmpty) {
          return fallback;
        }
        // cacheKey is the stable storage path, not the hourly-rotating signed
        // URL — so cached bytes survive URL rotation. See docs/adr/0003.
        return CachedNetworkImage(
          imageUrl: snap.data!,
          cacheKey: widget.path,
          fit: BoxFit.cover,
          fadeInDuration: Duration.zero,
          fadeOutDuration: Duration.zero,
          errorWidget: (_, __, ___) => fallback,
        );
      },
    );
  }
}
