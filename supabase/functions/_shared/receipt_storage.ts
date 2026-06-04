import { serviceClient } from "./supabase.ts";

// Receipt-image storage for the bot, mirroring the in-app scanner pipeline
// (`lib/core/services/receipt_service.dart`): non-free tiers keep the scanned
// photo in the private `receipts` bucket under `{userId}/{txnId}.jpg`, with a
// rolling expiry the receipt-expiry cron enforces.
const BUCKET = "receipts";
const RETENTION_DAYS = 365;

// Mirrors Flutter `FeatureFlags.receiptStorage`: every non-free tier stores
// receipt images; free tier never does.
export function canStoreReceipt(tier: string): boolean {
  return tier !== "free";
}

export function receiptPath(userId: string, txnId: string): string {
  return `${userId}/${txnId}.jpg`;
}

// Low-confidence images become a Pending transaction whose txn id doesn't exist
// yet, so the photo is parked here until the user confirms.
export function pendingStashPath(userId: string, pendingId: string): string {
  return `${userId}/pending-${pendingId}.jpg`;
}

function expiryIso(): string {
  return new Date(Date.now() + RETENTION_DAYS * 86_400_000).toISOString();
}

async function uploadBytes(path: string, bytes: Uint8Array): Promise<boolean> {
  const { error } = await serviceClient().storage.from(BUCKET).upload(
    path,
    bytes,
    { contentType: "image/jpeg", upsert: true },
  );
  if (error) {
    console.error("receipt upload failed", path, error.message);
    return false;
  }
  return true;
}

// High-confidence auto-save path: txn id + bytes both in hand.
export async function storeReceiptForTxn(
  userId: string,
  txnId: string,
  bytes: Uint8Array,
): Promise<void> {
  const path = receiptPath(userId, txnId);
  if (!(await uploadBytes(path, bytes))) return;
  await serviceClient().from("transactions").update({
    receipt_url: path,
    receipt_expires_at: expiryIso(),
  }).eq("id", txnId);
}

// Stash the photo against a pending row. Returns the stash path to persist on
// the pending payload, or null if the upload failed (pending still proceeds).
export async function stashPendingReceipt(
  userId: string,
  pendingId: string,
  bytes: Uint8Array,
): Promise<string | null> {
  const path = pendingStashPath(userId, pendingId);
  return (await uploadBytes(path, bytes)) ? path : null;
}

// Promote a stashed blob to its final transaction path once confirmed.
export async function promotePendingReceipt(
  userId: string,
  stashPath: string,
  txnId: string,
): Promise<void> {
  const finalPath = receiptPath(userId, txnId);
  const { error } = await serviceClient().storage.from(BUCKET).move(
    stashPath,
    finalPath,
  );
  if (error) {
    console.error("receipt promote failed", stashPath, error.message);
    return;
  }
  await serviceClient().from("transactions").update({
    receipt_url: finalPath,
    receipt_expires_at: expiryIso(),
  }).eq("id", txnId);
}

export async function deleteStashedReceipt(stashPath: string): Promise<void> {
  await serviceClient().storage.from(BUCKET).remove([stashPath]);
}
