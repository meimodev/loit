// PLACEHOLDER — overwritten by `flutterfire configure`.
//
// Run (see LOIT_Build_Guide.md Step 1.1):
//   dart pub global activate flutterfire_cli
//   flutterfire configure \
//     --project=<firebase-project-id> \
//     --platforms=android,ios \
//     --ios-bundle-id=id.activid.loit \
//     --android-package-name=id.activid.loit
//
// Until then this file throws at runtime if Firebase is initialized
// so builds can still compile during early bootstrap.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    throw UnsupportedError(
      'firebase_options.dart has not been generated. '
      'Run `flutterfire configure` (see LOIT_Build_Guide.md Step 1.1).',
    );
  }
}
