package id.activid.loit

// FlutterFragmentActivity (not FlutterActivity) is required by `midtrans_sdk` —
// its Snap UI is hosted in an AndroidX Fragment and silently fails to attach
// when the host activity doesn't support FragmentManager.
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterFragmentActivity()
