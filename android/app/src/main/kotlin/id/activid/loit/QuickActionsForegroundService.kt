package id.activid.loit

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.net.Uri
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat

// Hosts the persistent "quick actions" notification as a foreground service so
// the notification cannot be swiped away on Android 14+ (ongoing flag alone is
// no longer sticky there). Started/stopped from Dart via the
// `loit/quick_actions_fgs` MethodChannel registered in MainActivity.
class QuickActionsForegroundService : Service() {
    companion object {
        const val CHANNEL_ID = "loit_quick_actions"
        const val NOTIF_ID = 1001

        private const val ACTION_START = "id.activid.loit.qa.START"
        private const val ACTION_STOP = "id.activid.loit.qa.STOP"

        const val EXTRA_TITLE = "title"
        const val EXTRA_BODY = "body"
        const val EXTRA_CHANNEL_NAME = "channelName"
        const val EXTRA_CHANNEL_DESC = "channelDesc"
        const val EXTRA_SCAN = "scan"
        const val EXTRA_ADD = "add"
        const val EXTRA_VIEW_TX = "viewTx"
        const val EXTRA_VIEW_ROOMS = "viewRooms"

        fun start(ctx: Context, extras: Map<String, String>) {
            val i = Intent(ctx, QuickActionsForegroundService::class.java).apply {
                action = ACTION_START
                extras.forEach { (k, v) -> putExtra(k, v) }
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                ctx.startForegroundService(i)
            } else {
                ctx.startService(i)
            }
        }

        fun stop(ctx: Context) {
            val i = Intent(ctx, QuickActionsForegroundService::class.java).apply {
                action = ACTION_STOP
            }
            ctx.startService(i)
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            stopForeground(STOP_FOREGROUND_REMOVE)
            stopSelf()
            return START_NOT_STICKY
        }

        ensureChannel(
            intent?.getStringExtra(EXTRA_CHANNEL_NAME) ?: "Quick actions",
            intent?.getStringExtra(EXTRA_CHANNEL_DESC) ?: ""
        )
        val notif = buildNotification(intent)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(
                NOTIF_ID,
                notif,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC,
            )
        } else {
            startForeground(NOTIF_ID, notif)
        }
        return START_STICKY
    }

    private fun ensureChannel(name: String, description: String) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val mgr = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val existing = mgr.getNotificationChannel(CHANNEL_ID)
        if (existing != null) return
        val ch = NotificationChannel(CHANNEL_ID, name, NotificationManager.IMPORTANCE_LOW).apply {
            this.description = description
            enableVibration(false)
            setSound(null, null)
            setShowBadge(false)
            lockscreenVisibility = Notification.VISIBILITY_SECRET
        }
        mgr.createNotificationChannel(ch)
    }

    private fun pendingDeepLink(uri: String, requestCode: Int): PendingIntent {
        // Explicit component to avoid implicit-intent resolution quirks.
        // app_links plugin reads `intent.data` from MainActivity.onNewIntent.
        val intent = Intent(this, MainActivity::class.java).apply {
            action = Intent.ACTION_VIEW
            data = Uri.parse(uri)
            addFlags(
                Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP,
            )
        }
        val flags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        return PendingIntent.getActivity(this, requestCode, intent, flags)
    }

    private fun pendingRestart(extras: Map<String, String>): PendingIntent {
        val intent = Intent(this, QuickActionsRestartReceiver::class.java).apply {
            extras.forEach { (k, v) -> putExtra(k, v) }
        }
        val flags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        return PendingIntent.getBroadcast(this, 99, intent, flags)
    }

    private fun buildNotification(intent: Intent?): Notification {
        val title = intent?.getStringExtra(EXTRA_TITLE) ?: "LOIT"
        val body = intent?.getStringExtra(EXTRA_BODY) ?: ""
        val channelName = intent?.getStringExtra(EXTRA_CHANNEL_NAME) ?: "Quick actions"
        val channelDesc = intent?.getStringExtra(EXTRA_CHANNEL_DESC) ?: ""
        val scan = intent?.getStringExtra(EXTRA_SCAN) ?: "Scan"
        val add = intent?.getStringExtra(EXTRA_ADD) ?: "Add"
        val viewTx = intent?.getStringExtra(EXTRA_VIEW_TX) ?: "Transactions"
        val viewRooms = intent?.getStringExtra(EXTRA_VIEW_ROOMS) ?: "Rooms"

        val tapPi = pendingDeepLink("loit://transactions", 0)
        val scanPi = pendingDeepLink("loit://scan", 1)
        val addPi = pendingDeepLink("loit://transactions/add", 2)
        val viewTxPi = pendingDeepLink("loit://transactions", 3)
        val viewRoomsPi = pendingDeepLink("loit://rooms", 4)

        // Cache extras into the restart broadcast so a swipe re-posts the
        // notification with identical content (Android 13+ allows user
        // dismissal of FGS notifications; this restores it immediately).
        val restartPi = pendingRestart(
            mapOf(
                EXTRA_TITLE to title,
                EXTRA_BODY to body,
                EXTRA_CHANNEL_NAME to channelName,
                EXTRA_CHANNEL_DESC to channelDesc,
                EXTRA_SCAN to scan,
                EXTRA_ADD to add,
                EXTRA_VIEW_TX to viewTx,
                EXTRA_VIEW_ROOMS to viewRooms,
            ),
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.mipmap.launcher_icon)
            .setContentTitle(title)
            .setContentText(body)
            .setOngoing(true)
            .setAutoCancel(false)
            .setOnlyAlertOnce(true)
            .setSilent(true)
            .setShowWhen(false)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setVisibility(NotificationCompat.VISIBILITY_SECRET)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setContentIntent(tapPi)
            .setDeleteIntent(restartPi)
            .addAction(0, scan, scanPi)
            .addAction(0, add, addPi)
            .addAction(0, viewTx, viewTxPi)
            .addAction(0, viewRooms, viewRoomsPi)
            .build()
            .apply {
                flags = flags or Notification.FLAG_ONGOING_EVENT or Notification.FLAG_NO_CLEAR
            }
    }
}
