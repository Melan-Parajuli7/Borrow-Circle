import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart' show TargetPlatform;

/// Firebase options for the BorrowCircle project (`borrowcircle-84813`).
///
/// Values are taken from `android/app/google-services.json`. iOS and web are
/// not configured; Firebase is only initialised on Android in [main].
class DefaultFirebaseOptions {
  DefaultFirebaseOptions._();

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCTfnDIYIFT4QOq9qCNitSdbtNkc3MtVaw',
    appId: '1:70105544950:android:fa31c3af73253ccfd654d7',
    messagingSenderId: '70105544950',
    projectId: 'borrowcircle-84813',
    storageBucket: 'borrowcircle-84813.firebasestorage.app',
  );

  /// Options for the current platform, or `null` when the platform is not
  /// supported by this build (web / iOS / desktop).
  static FirebaseOptions? get currentPlatform {
    if (kIsWeb) return null;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        return null;
    }
  }
}
