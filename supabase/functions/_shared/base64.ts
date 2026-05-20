// Chunked base64 encoder. `btoa(String.fromCharCode(...bytes))` blows up for
// realistic Telegram files because spreading a Uint8Array uses one JS argument
// per byte, exceeding V8's argument-count limit (~65k) for any file over a
// few tens of KB. This helper chunks the conversion to a string in fixed-size
// blocks before delegating to `btoa`.

const CHUNK = 0x8000; // 32 KB per chunk — well under any JS arg-count limit.

export function bytesToBase64(bytes: Uint8Array): string {
  let binary = "";
  for (let i = 0; i < bytes.length; i += CHUNK) {
    const end = Math.min(i + CHUNK, bytes.length);
    binary += String.fromCharCode.apply(
      null,
      Array.from(bytes.subarray(i, end)),
    );
  }
  return btoa(binary);
}
