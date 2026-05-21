export type Locale = "en" | "id";

const dict: Record<string, Record<string, string>> = {
  en: {
    incomeRecorded: "Income recorded",
    newExpense: "New expense",
    roomTransaction: "{amount} {currency}",

    // Bot replies
    botNotLinked:
      "Your Telegram is not linked to a LOIT account. Open LOIT → Settings → Connect Telegram to get a link code.",
    botLinkedOk: "Connected to LOIT. Send a message like \"kopi 25k\" to log a transaction.",
    botLinkInvalid: "That link code is invalid or expired. Generate a new one in LOIT → Settings.",
    botHelp:
      "Send a transaction in plain text — \"kopi 25k\" or \"gaji 8jt\". You can also send a receipt photo or a voice note.\n\nCommands: /today, /undo, /cancel, /end, /help.",
    botRateLimited:
      "You've hit the rate limit (50 messages/hour). Try again later.",
    botUnknown: "Sorry, I couldn't understand that. Try \"kopi 25k\" or send /help.",
    botRoomNotFound:
      "I see you mentioned the room \"{room}\", but it's not in this LOIT account.\n\nYour rooms: {rooms}",
    botRoomNotFoundNoRooms:
      "I see you mentioned a room (\"{room}\"), but this LOIT account isn't in any shared rooms yet. Create or join one in LOIT → Rooms.",
    botTransactionSaved: "✅ Saved\n{summary}",
    botIncomeSaved: "✅ Income recorded\n{summary}",
    botPendingConfirm: "⚠️ Please confirm\n{summary}\n\nLooks right?",
    botUndoDone: "↩️ Undone.",
    botUndoExpired: "Undo window passed. Edit in app:",
    botQuotaReached:
      "You've reached your scan quota for this month. Upgrade or buy a top-up in LOIT to keep going.",
    botVoiceTooLong: "Voice notes must be 60 seconds or shorter.",
    botParseFailed: "I couldn't parse a transaction from that.",
    botToday: "📅 Today's transactions",
    botTodayEmpty: "🌱 No transactions today yet.",
    botUnlinked: "Unlinked. You can re-connect any time from LOIT → Settings.",
    botDisconnected:
      "Disconnected from LOIT. The bot will no longer save anything for you. Reconnect any time from LOIT → Settings.",
    botCallbackNotLinked: "Not linked. Reconnect from LOIT → Settings.",
    botCancelled: "❌ Cancelled.",
    botNothingToCancel: "Nothing pending to cancel.",
    botNothingToUndo: "Nothing to undo.",
    botUndoFailed: "Couldn't undo — the transaction may already be gone.",
    botEditDetail: "Editing this transaction:\n{summary}",
    botEditAppliedSummary: "✅ Updated\n{summary}",
    botRoomPicker: "📍 Where should this go?",
    botEditPicker: "What do you want to change?",
    botEditAwaitAmount: "Send the new amount as a number.",
    botEditAwaitCategory: "Pick a category:",
    botEditAwaitAccount: "Pick an account:",
    botEditAwaitDestination: "Pick a destination:",
    botEditAwaitDate: "Send the new date (YYYY-MM-DD).",
    botEditAwaitNotes: "Send the new note text.",
    botEditApplied: "✅ Updated.",
    botEditFailed: "Could not update that transaction.",
    botInvalidCategory: "That category isn't available for the chosen destination. Pick a valid one:",
    botEditCancelled: "Edit cancelled.",
    botEditWindowExpired: "Edit window has passed. Edit in app:",
    botTodayFailed: "Couldn't fetch today's transactions.",
    btnUndo: "↩️ Undo",
    btnEdit: "✏️ Edit",
    btnPersonal: "Personal",
    btnCancel: "❌ Cancel",
    btnConfirm: "✅ Confirm",
    btnEditInApp: "Edit in app",
    btnEditAmount: "Amount",
    btnEditCategory: "Category",
    btnEditAccount: "Account",
    btnEditDestination: "Destination",
    btnEditDate: "Date",
    btnEditNotes: "Notes",
  },
  id: {
    incomeRecorded: "Pemasukan dicatat",
    newExpense: "Pengeluaran baru",
    roomTransaction: "{amount} {currency}",

    botNotLinked:
      "Telegram kamu belum terhubung ke akun LOIT. Buka LOIT → Pengaturan → Hubungkan Telegram untuk kode tautan.",
    botLinkedOk: "Terhubung ke LOIT. Kirim pesan seperti \"kopi 25k\" untuk mencatat transaksi.",
    botLinkInvalid: "Kode tautan tidak valid atau kadaluarsa. Buat ulang di LOIT → Pengaturan.",
    botHelp:
      "Kirim transaksi dalam teks bebas — \"kopi 25k\" atau \"gaji 8jt\". Bisa juga foto struk atau pesan suara.\n\nPerintah: /today, /undo, /cancel, /end, /help.",
    botRateLimited:
      "Kamu sudah mencapai batas (50 pesan/jam). Coba lagi nanti.",
    botUnknown: "Maaf, saya tidak mengerti. Coba \"kopi 25k\" atau /help.",
    botRoomNotFound:
      "Pesannya menyebut room \"{room}\", tapi room itu tidak ada di akun LOIT ini.\n\nRoom kamu: {rooms}",
    botRoomNotFoundNoRooms:
      "Pesannya menyebut sebuah room (\"{room}\"), tapi akun LOIT ini belum tergabung di room bersama mana pun. Buat atau gabung dari LOIT → Rooms.",
    botTransactionSaved: "✅ Tersimpan\n{summary}",
    botIncomeSaved: "✅ Pemasukan dicatat\n{summary}",
    botPendingConfirm: "⚠️ Mohon konfirmasi\n{summary}\n\nSudah benar?",
    botUndoDone: "↩️ Dibatalkan.",
    botUndoExpired: "Waktu undo sudah lewat. Ubah di aplikasi:",
    botQuotaReached:
      "Kuota scan bulan ini habis. Upgrade atau beli top-up di LOIT untuk melanjutkan.",
    botVoiceTooLong: "Pesan suara maksimum 60 detik.",
    botParseFailed: "Saya tidak menemukan transaksi dari pesan itu.",
    botToday: "📅 Transaksi hari ini",
    botTodayEmpty: "🌱 Belum ada transaksi hari ini.",
    botUnlinked: "Akun terputus. Bisa hubungkan ulang dari LOIT → Pengaturan.",
    botDisconnected:
      "Terputus dari LOIT. Bot tidak akan menyimpan apa pun lagi. Hubungkan ulang dari LOIT → Pengaturan.",
    botCallbackNotLinked: "Tidak terhubung. Hubungkan ulang di LOIT → Pengaturan.",
    botCancelled: "❌ Dibatalkan.",
    botNothingToCancel: "Tidak ada yang menunggu pembatalan.",
    botNothingToUndo: "Tidak ada yang bisa dibatalkan.",
    botUndoFailed: "Gagal membatalkan — transaksi mungkin sudah hilang.",
    botEditDetail: "Mengedit transaksi ini:\n{summary}",
    botEditAppliedSummary: "✅ Diperbarui\n{summary}",
    botRoomPicker: "📍 Mau dicatat ke mana?",
    botEditPicker: "Apa yang ingin diubah?",
    botEditAwaitAmount: "Kirim jumlah baru sebagai angka.",
    botEditAwaitCategory: "Pilih kategori:",
    botEditAwaitAccount: "Pilih akun:",
    botEditAwaitDestination: "Pilih tujuan:",
    botEditAwaitDate: "Kirim tanggal baru (YYYY-MM-DD).",
    botEditAwaitNotes: "Kirim catatan baru.",
    botEditApplied: "✅ Tersimpan.",
    botEditFailed: "Gagal memperbarui transaksi.",
    botInvalidCategory: "Kategori itu tidak tersedia untuk tujuan ini. Pilih kategori yang valid:",
    botEditCancelled: "Edit dibatalkan.",
    botEditWindowExpired: "Waktu edit sudah lewat. Ubah di aplikasi:",
    botTodayFailed: "Gagal memuat transaksi hari ini.",
    btnUndo: "↩️ Undo",
    btnEdit: "✏️ Ubah",
    btnPersonal: "Pribadi",
    btnCancel: "❌ Batal",
    btnConfirm: "✅ Konfirmasi",
    btnEditInApp: "Ubah di aplikasi",
    btnEditAmount: "Jumlah",
    btnEditCategory: "Kategori",
    btnEditAccount: "Akun",
    btnEditDestination: "Tujuan",
    btnEditDate: "Tanggal",
    btnEditNotes: "Catatan",
  },
};

export function t(locale: Locale, key: string, params?: Record<string, string>): string {
  const val = dict[locale]?.[key] ?? dict["en"][key] ?? key;
  if (!params) return val;
  return val.replace(/\{(\w+)\}/g, (_, name) => params[name] ?? `{${name}}`);
}

export function resolveLocale(language: string | null | undefined): Locale {
  if (language === "id") return "id";
  return "en";
}
