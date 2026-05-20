package id.activid.loit

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

// Android 13+ made foreground-service notifications user-dismissible, so the
// only way to keep the persistent quick-actions tile visible is to re-post it
// when the user swipes. The notification's DeleteIntent fires here; we relay
// to the service which re-issues startForeground with the cached extras.
class QuickActionsRestartReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val extras = mutableMapOf<String, String>()
        intent.extras?.keySet()?.forEach { k ->
            intent.getStringExtra(k)?.let { extras[k] = it }
        }
        QuickActionsForegroundService.start(context.applicationContext, extras)
    }
}
