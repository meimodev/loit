// Server-side scan preprocessing for Telegram receipt photos.
//
// Mirrors `lib/core/services/scan_preprocessor.dart` as closely as the Deno
// runtime allows: decode → resize long edge = 1600 → JPEG q85. We use the
// pure-TS ImageScript library because it runs without native deps on Deno
// Edge Functions.
//
// Unlike the Flutter pipeline we skip the grayscale/contrast pass — Claude
// performs well enough on colour input and the extra passes increase memory
// pressure for the edge runtime. The important wins (resize cap + JPEG
// re-encode at q85) are preserved so payload size matches the in-app scanner.

import { decode, Image } from "https://deno.land/x/imagescript@1.2.17/mod.ts";

const LONG_EDGE = 1600;
const JPEG_QUALITY = 85;

export async function preprocessReceiptImage(
  bytes: Uint8Array,
): Promise<Uint8Array> {
  const decoded = await decode(bytes);
  if (!(decoded instanceof Image)) {
    // Animated input (GIF). Telegram photos never deliver one; bail to the
    // original bytes — downstream parser will reject if illegible.
    return bytes;
  }
  let image: Image = decoded;
  const w = image.width;
  const h = image.height;
  if (w >= h && w > LONG_EDGE) {
    image = image.resize(LONG_EDGE, Image.RESIZE_AUTO);
  } else if (h > w && h > LONG_EDGE) {
    image = image.resize(Image.RESIZE_AUTO, LONG_EDGE);
  }
  return await image.encodeJPEG(JPEG_QUALITY);
}
