package id.activid.loit

// `FlutterFragmentActivity` is kept (instead of plain `FlutterActivity`) because
// other plugins — most notably `local_auth` — host their UI in AndroidX
// Fragments and require a FragmentManager-aware host. Switching back to
// `FlutterActivity` is safe only after auditing every plugin in `pubspec.yaml`.
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterFragmentActivity()
