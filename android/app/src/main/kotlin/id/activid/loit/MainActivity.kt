package id.activid.loit

// `FlutterFragmentActivity` is kept (instead of plain `FlutterActivity`) because
// other plugins — most notably `local_auth` — host their UI in AndroidX
// Fragments and require a FragmentManager-aware host. Switching back to
// `FlutterActivity` is safe only after auditing every plugin in `pubspec.yaml`.
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "loit/quick_actions_fgs",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "start" -> {
                    @Suppress("UNCHECKED_CAST")
                    val args = (call.arguments as? Map<String, Any?>) ?: emptyMap()
                    val extras = args
                        .mapValues { it.value?.toString() ?: "" }
                        .filterValues { it.isNotEmpty() }
                    QuickActionsForegroundService.start(applicationContext, extras)
                    result.success(null)
                }
                "stop" -> {
                    QuickActionsForegroundService.stop(applicationContext)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }
}
