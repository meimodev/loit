// Google Gemini client, used by the Telegram bot for ONE job only: voice
// transcription. Claude has no audio input, so a voice note is transcribed to
// text here before the Claude text parser handles it. Text, caption, and
// receipt parsing all run on Claude — do NOT route those through this module.
// See docs/adr/0002-telegram-bot-back-to-claude.md.
//
// NOTE: the model id is supplied verbatim; a wrong/retired id fails at runtime
// (404). `gemini-3.5-flash` is confirmed live as of 2026-06-03.
import { GoogleGenAI } from "npm:@google/genai@2.7.0";

export const GEMINI_MODEL = "gemini-3.5-flash";

const ai = new GoogleGenAI({ apiKey: Deno.env.get("GEMINI_API_KEY")! });

const TRANSCRIBE_PROMPT =
  "Transcribe verbatim. Return only the transcript text, no commentary.";

// Transcribe a base64-encoded voice note to plain text. Returns the trimmed
// transcript (possibly empty). Throws on transport/SDK errors so the caller
// can route to its failure reply.
export async function geminiTranscribe(
  audioBase64: string,
  mimeType: string,
): Promise<string> {
  const res = await ai.models.generateContent({
    model: GEMINI_MODEL,
    contents: [
      {
        role: "user",
        // deno-lint-ignore no-explicit-any
        parts: [{ inlineData: { mimeType, data: audioBase64 } }] as any,
      },
    ],
    config: {
      systemInstruction: TRANSCRIBE_PROMPT,
      maxOutputTokens: 512,
    },
  });
  return (res.text ?? "").trim();
}
