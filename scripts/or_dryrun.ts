// OpenRouter contract dry-run. Exercises the same chat/completions shape as
// _shared/openrouter.ts chatComplete(): Anthropic model, per-block
// cache_control on the system block, JSON-only reply. Prints reply + usage so
// you can confirm cache_write/cache_read tokens.
//
//   OPENROUTER_API_KEY=sk-or-... deno run --allow-net --allow-env scripts/or_dryrun.ts
//
// Run twice back-to-back: the 2nd call should show cached prompt tokens.

const API_KEY = Deno.env.get("OPENROUTER_API_KEY");
if (!API_KEY) {
  console.error("OPENROUTER_API_KEY unset");
  Deno.exit(1);
}

const MODEL = "anthropic/claude-haiku-4.5";
// Padded so the system block clears Anthropic's ~1024-token cache minimum.
const SYSTEM = "You are a parser. Return ONLY valid JSON, no markdown.\n" +
  "Echo the user's amount and currency as {\"total\":N,\"currency\":\"X\"}.\n" +
  "Reference filler to exceed the cache threshold: ".padEnd(18000, "lorem ipsum dolor sit amet ");

const res = await fetch("https://openrouter.ai/api/v1/chat/completions", {
  method: "POST",
  headers: {
    "Authorization": `Bearer ${API_KEY}`,
    "Content-Type": "application/json",
  },
  body: JSON.stringify({
    model: MODEL,
    max_tokens: 64,
    messages: [
      {
        role: "system",
        content: [{ type: "text", text: SYSTEM, cache_control: { type: "ephemeral" } }],
      },
      { role: "user", content: [{ type: "text", text: "I spent 25000 rupiah." }] },
    ],
  }),
});

console.log("HTTP", res.status, res.statusText);
const data = await res.json();
if (!res.ok) {
  console.error("ERROR body:", JSON.stringify(data, null, 2));
  Deno.exit(1);
}
console.log("model    :", data.model);
console.log("reply    :", data.choices?.[0]?.message?.content);
console.log("usage    :", JSON.stringify(data.usage));
