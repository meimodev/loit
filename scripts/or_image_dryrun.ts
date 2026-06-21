// OpenRouter VISION dry-run. Sends a real image the way receipt_parser.ts
// does (base64 JPEG data URL, per-block cached system prompt) and dumps the
// FULL raw OpenRouter response — model, message content, usage, finish_reason
// — i.e. everything chatComplete() normally throws away.
//
//   OPENROUTER_API_KEY=sk-or-... deno run --allow-net --allow-env --allow-read \
//     scripts/or_image_dryrun.ts "/path/to/receipt.jpeg"
import { encodeBase64 } from "https://deno.land/std@0.224.0/encoding/base64.ts";

const API_KEY = Deno.env.get("OPENROUTER_API_KEY");
const path = Deno.args[0];
if (!API_KEY || !path) {
  console.error("usage: OPENROUTER_API_KEY=... deno run ... or_image_dryrun.ts <image-path>");
  Deno.exit(1);
}

const ext = path.split(".").pop()?.toLowerCase() ?? "jpeg";
const mime = ext === "png" ? "image/png" : ext === "webp" ? "image/webp" : "image/jpeg";
const b64 = encodeBase64(await Deno.readFile(path));
console.log(`image: ${path}  (${mime}, ${(b64.length / 1024).toFixed(0)} KB base64)`);

const SYSTEM =
  "You are a financial document parser. Read the receipt image and return ONLY " +
  "valid JSON, no markdown: " +
  '{"is_transaction":bool,"merchant":str|null,"currency":"ISO 4217"|null,' +
  '"total":number|null,"items":[{"name":str,"qty":number,"total_price":number}]}';

const res = await fetch("https://openrouter.ai/api/v1/chat/completions", {
  method: "POST",
  headers: { "Authorization": `Bearer ${API_KEY}`, "Content-Type": "application/json" },
  body: JSON.stringify({
    model: "anthropic/claude-haiku-4.5",
    max_tokens: 4096,
    messages: [
      { role: "system", content: [{ type: "text", text: SYSTEM, cache_control: { type: "ephemeral" } }] },
      {
        role: "user",
        content: [
          { type: "image_url", image_url: { url: `data:${mime};base64,${b64}` } },
          { type: "text", text: "Parse this receipt. Today is 2026-06-21." },
        ],
      },
    ],
  }),
});

console.log("HTTP", res.status, res.statusText);
const data = await res.json();
console.log("=== RAW RESPONSE ===");
console.log(JSON.stringify(data, null, 2));
console.log("=== content only ===");
console.log(data?.choices?.[0]?.message?.content ?? "(none)");
